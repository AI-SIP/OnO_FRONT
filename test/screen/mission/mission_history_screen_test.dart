// 보상 기록 화면 테스트.
//
// 무한 스크롤과 합계 처리가 관찰 대상이다. 합계는 첫 페이지에만 오고,
// 서버가 끝이라고 하면 더 부르지 않아야 한다. 조회가 실패해도 오류를 띄우지
// 않는다 — 백엔드에 아직 이 API 가 없을 수 있다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Mission/MissionHistoryModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Screen/Mission/MissionHistoryScreen.dart';

import '../../helpers/helpers.dart';

MissionHistoryItemModel buildItem({
  required int progressId,
  required DateTime claimedAt,
  String code = 'DAILY_NOTE_WRITE',
  String title = '오늘의 오답',
  int rewardValue = 10,
}) {
  return MissionHistoryItemModel(
    progressId: progressId,
    code: code,
    title: title,
    iconKey: 'note_write',
    category: MissionCategory.daily,
    periodKey: '2026-09-10',
    rewardType: MissionRewardType.xp,
    rewardValue: rewardValue,
    claimedAt: claimedAt,
  );
}

void main() {
  setUpOnoWidgetTest();

  late MockMissionService missionService;

  setUp(() {
    missionService = MockMissionService();
  });

  Future<void> pumpHistory(WidgetTester tester) async {
    disableAnimationsForTest(tester);
    await pumpOnoWidget(
      tester,
      MissionHistoryScreen(missionService: missionService),
    );
  }

  void stubPage(
    MissionHistoryPageModel? page, {
    int? cursor,
  }) {
    when(() => missionService.getHistory(cursor: cursor))
        .thenAnswer((_) async => page);
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 14, 33);
  final yesterday = today.subtract(const Duration(days: 1));

  group('첫 페이지', () {
    testWidgets('합계와 목록을 보여 준다', (tester) async {
      stubPage(
        MissionHistoryPageModel(
          content: [buildItem(progressId: 1, claimedAt: today)],
          nextCursor: null,
          hasNext: false,
          totalClaimedXp: 1250,
          totalClaimedCount: 37,
        ),
      );

      await pumpHistory(tester);

      expect(find.text('지금까지 받은 보상'), findsOneWidget);
      expect(find.text('1250 XP'), findsOneWidget);
      expect(find.text('미션 37개'), findsOneWidget);
      expect(find.text('오늘의 오답'), findsOneWidget);
      expect(find.text('+10 XP'), findsOneWidget);
    });

    test('합계가 없으면 읽은 것으로 센다', () {
      // 서버가 합계를 빼고 주더라도 화면이 비지 않아야 한다.
      const page = MissionHistoryPageModel(
        content: [],
        nextCursor: null,
        hasNext: false,
      );
      expect(page.totalClaimedXp, isNull);
    });

    testWidgets('합계가 없으면 목록에서 더해 보여 준다', (tester) async {
      stubPage(
        MissionHistoryPageModel(
          content: [
            buildItem(progressId: 1, claimedAt: today, rewardValue: 10),
            buildItem(progressId: 2, claimedAt: today, rewardValue: 15),
          ],
          nextCursor: null,
          hasNext: false,
        ),
      );

      await pumpHistory(tester);

      expect(find.text('25 XP'), findsOneWidget);
      expect(find.text('미션 2개'), findsOneWidget);
    });

    testWidgets('날짜별로 묶는다', (tester) async {
      stubPage(
        MissionHistoryPageModel(
          content: [
            buildItem(progressId: 1, claimedAt: today),
            buildItem(progressId: 2, claimedAt: yesterday, title: '출석'),
          ],
          nextCursor: null,
          hasNext: false,
        ),
      );

      await pumpHistory(tester);

      expect(find.text('오늘'), findsOneWidget);
      expect(find.text('어제'), findsOneWidget);
      // 같은 날짜가 이어지면 머리글을 다시 쓰지 않는다.
      expect(find.text('오후 2:33'), findsNWidgets(2));
    });
  });

  group('다음 페이지', () {
    testWidgets('끝에 닿으면 이어서 읽고 중복 없이 붙인다', (tester) async {
      stubPage(
        MissionHistoryPageModel(
          content: [
            for (var i = 0; i < 8; i++)
              buildItem(
                progressId: i,
                claimedAt: today,
                title: '첫 페이지 $i',
              ),
          ],
          nextCursor: 998,
          hasNext: true,
          totalClaimedXp: 500,
          totalClaimedCount: 12,
        ),
      );
      stubPage(
        MissionHistoryPageModel(
          content: [
            buildItem(progressId: 99, claimedAt: today, title: '두 번째 페이지'),
          ],
          nextCursor: null,
          hasNext: false,
        ),
        cursor: 998,
      );

      await pumpHistory(tester);
      expect(find.text('첫 페이지 0'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();

      verify(() => missionService.getHistory(cursor: 998)).called(1);
      expect(find.text('두 번째 페이지'), findsOneWidget);
      // 합계는 첫 페이지 값을 그대로 들고 있는다.
      expect(find.text('500 XP'), findsOneWidget);
      expect(find.text('미션 12개'), findsOneWidget);
    });

    testWidgets('마지막 페이지면 더 부르지 않는다', (tester) async {
      stubPage(
        MissionHistoryPageModel(
          content: [
            for (var i = 0; i < 8; i++)
              buildItem(progressId: i, claimedAt: today, title: '기록 $i'),
          ],
          nextCursor: null,
          hasNext: false,
        ),
      );

      await pumpHistory(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();

      verify(() => missionService.getHistory(cursor: null)).called(1);
      verifyNever(
          () => missionService.getHistory(cursor: any(named: 'cursor')));
    });
  });

  group('빈 목록과 실패', () {
    testWidgets('받은 게 없으면 조용한 안내만 남는다', (tester) async {
      stubPage(MissionHistoryPageModel.empty);

      await pumpHistory(tester);

      expect(find.text('아직 받은 보상이 없어요'), findsOneWidget);
      expect(find.text('0 XP'), findsOneWidget);
    });

    testWidgets('조회에 실패해도 오류를 띄우지 않는다', (tester) async {
      stubPage(null);

      await pumpHistory(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('아직 받은 보상이 없어요'), findsOneWidget);
    });

    testWidgets('실패한 뒤에는 스크롤해도 다시 조르지 않는다', (tester) async {
      stubPage(null);

      await pumpHistory(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      verify(() => missionService.getHistory(cursor: null)).called(1);
      verifyNever(
          () => missionService.getHistory(cursor: any(named: 'cursor')));
    });
  });
}
