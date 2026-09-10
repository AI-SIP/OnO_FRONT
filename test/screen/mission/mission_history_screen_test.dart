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

// 고정 시각이다. 날짜 계산에 Duration 을 쓰지 않는다. 서머타임이 있는 지역에서는
// 하루가 24시간이 아니라 시각이 한 시간 밀려 `오후 2:33` 단언이 깨진다.
final _now = DateTime(2026, 9, 10, 15, 0);
final _today = DateTime(2026, 9, 10, 14, 33);
final _yesterday = DateTime(2026, 9, 9, 14, 33);

void main() {
  setUpOnoWidgetTest();

  late MockMissionService missionService;

  setUp(() {
    missionService = MockMissionService();
  });

  Future<void> pumpHistory(WidgetTester tester, {bool settle = true}) async {
    disableAnimationsForTest(tester);
    await pumpOnoWidget(
      tester,
      MissionHistoryScreen(
        missionService: missionService,
        // 시계를 고정한다. 실제 시각에 매이면 자정을 넘기는 순간이나 서머타임이
        // 있는 지역에서만 어긋나는 실패가 난다.
        clock: () => _now,
      ),
      settle: settle,
    );
  }

  void stubPage(
    MissionHistoryPageModel? page, {
    int? cursor,
  }) {
    when(() => missionService.getHistory(cursor: cursor))
        .thenAnswer((_) async => page);
  }

  group('첫 페이지', () {
    testWidgets('합계와 목록을 보여 준다', (tester) async {
      stubPage(
        MissionHistoryPageModel(
          content: [buildItem(progressId: 1, claimedAt: _today)],
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

    testWidgets('합계가 없으면 목록에서 더해 보여 준다', (tester) async {
      stubPage(
        MissionHistoryPageModel(
          content: [
            buildItem(progressId: 1, claimedAt: _today, rewardValue: 10),
            buildItem(progressId: 2, claimedAt: _today, rewardValue: 15),
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
            buildItem(progressId: 1, claimedAt: _today),
            buildItem(progressId: 2, claimedAt: _yesterday, title: '출석'),
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
                claimedAt: _today,
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
            buildItem(progressId: 99, claimedAt: _today, title: '두 번째 페이지'),
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
              buildItem(progressId: i, claimedAt: _today, title: '기록 $i'),
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

  group('요청이 겹칠 때', () {
    testWidgets('먼저 나간 요청이 늦게 도착해도 새로고침한 목록을 덮지 않는다', (tester) async {
      // 요청이 날아가 있는 동안 새로고침하면 목록이 비워진다. 그 뒤 늦게
      // 도착한 옛 응답이 빈 목록에 붙고 커서까지 옛것으로 덮이면, 새로 읽은
      // 페이지가 통째로 사라지고 스크롤해도 복구되지 않는다.
      var calls = 0;
      when(() => missionService.getHistory(cursor: null)).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          // 첫 요청은 늦게 온다. 그 사이에 새로고침이 끼어든다.
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return MissionHistoryPageModel(
            content: [
              buildItem(progressId: 1, claimedAt: _today, title: '늦게 온 페이지'),
            ],
            nextCursor: 998,
            hasNext: true,
            totalClaimedXp: 999,
            totalClaimedCount: 99,
          );
        }
        return MissionHistoryPageModel(
          content: [
            buildItem(progressId: 2, claimedAt: _today, title: '새로 읽은 페이지'),
          ],
          nextCursor: null,
          hasNext: false,
          totalClaimedXp: 500,
          totalClaimedCount: 12,
        );
      });

      // 첫 응답을 기다리지 않는다. 기다리면 겹치는 순간이 사라진다.
      await pumpHistory(tester, settle: false);
      await tester.pump(const Duration(milliseconds: 50));

      // 첫 요청이 아직 날아가 있는 동안 당겨서 새로고침한다.
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 늦게 온 첫 응답이 도착할 시간을 준다.
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(
        find.text('새로 읽은 페이지'),
        findsOneWidget,
        reason: '새로고침으로 읽은 것이 남아 있어야 한다',
      );
      expect(
        find.text('늦게 온 페이지'),
        findsNothing,
        reason: '지난 세대의 응답은 버려야 한다',
      );
      // 합계도 새로 읽은 것이어야 한다.
      expect(find.text('500 XP'), findsOneWidget);
      expect(find.text('999 XP'), findsNothing);
    });
  });

  group('빈 목록과 실패', () {
    testWidgets('받은 게 없으면 조용한 안내만 남는다', (tester) async {
      stubPage(MissionHistoryPageModel.empty);

      await pumpHistory(tester);

      expect(find.text('아직 받은 보상이 없어요'), findsOneWidget);
      expect(find.text('0 XP'), findsOneWidget);
    });

    testWidgets('조회에 실패하면 빈 상태가 아니라 다시 시도를 보여 준다', (tester) async {
      // 실패한 것을 "받은 보상이 없다"로 보여 주면 보상이 있는데도 없다고
      // 말하는 셈이라, 사용자가 그대로 믿고 나가 버린다.
      stubPage(null);

      await pumpHistory(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('아직 받은 보상이 없어요'), findsNothing);
      expect(find.text('보상 기록을 불러오지 못했어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('다시 시도를 누르면 한 번 더 읽는다', (tester) async {
      // 첫 번째는 실패, 두 번째는 성공한다.
      var calls = 0;
      when(() => missionService.getHistory(cursor: null)).thenAnswer((_) async {
        calls++;
        if (calls == 1) return null;
        return MissionHistoryPageModel(
          content: [buildItem(progressId: 1, claimedAt: _today)],
          nextCursor: null,
          hasNext: false,
          totalClaimedXp: 10,
          totalClaimedCount: 1,
        );
      });

      await pumpHistory(tester);
      expect(find.text('다시 시도'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('오늘의 오답'), findsOneWidget);
      expect(find.text('보상 기록을 불러오지 못했어요'), findsNothing);
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

  group('폰과 태블릿, 큰 글자', () {
    for (final size in [OnoSurface.smallPhone, OnoSurface.tablet]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          '${size.width.toInt()}dp 글자 ${scale}배에서 넘치지 않는다',
          (tester) async {
            stubPage(
              MissionHistoryPageModel(
                content: [
                  buildItem(
                    progressId: 1,
                    claimedAt: _today,
                    title: '아주 긴 미션 제목이 들어오면 어떻게 되는지 보는 줄',
                    rewardValue: 1200,
                  ),
                  buildItem(progressId: 2, claimedAt: _yesterday),
                ],
                nextCursor: null,
                hasNext: false,
                totalClaimedXp: 123456,
                totalClaimedCount: 789,
              ),
            );

            disableAnimationsForTest(tester);
            await pumpOnoWidget(
              tester,
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: MissionHistoryScreen(
                    missionService: missionService,
                    clock: () => _now,
                  ),
                ),
              ),
              surfaceSize: size,
            );

            expect(
              tester.takeException(),
              isNull,
              reason: '${size.width.toInt()}dp × $scale 에서 넘쳤다',
            );
            // 넘치지 않은 것과 그릴 게 없었던 것은 다르다.
            expect(find.text('지금까지 받은 보상'), findsOneWidget);
            expect(find.text('오늘'), findsOneWidget);
          },
        );
      }
    }
  });
}
