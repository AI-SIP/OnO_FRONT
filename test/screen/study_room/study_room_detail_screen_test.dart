// StudyRoomDetailScreen 위젯 테스트.
//
// 방장/일반 멤버가 더보기 메뉴·멤버 관리에서 서로 다른 버튼을 보는지가 이
// 화면의 핵심이라, 권한별 조건부 표시에 집중한다. 실제 StudyRoomProvider 에
// MockStudyRoomService 를 물려서 fetchRoomDetail 이 호출하는 하위 fetch 들
// (피드/챌린지/공유문제/주간리포트)까지 자연스럽게 스텁한다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/StudyRoom/InviteCodeModel.dart';
import 'package:ono/Model/StudyRoom/StudyRoomMemberModel.dart';
import 'package:ono/Model/StudyRoom/StudyRoomModel.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Provider/StudyRoomProvider.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/StudyRoom/StudyRoomDetailScreen.dart';
import 'package:ono/Service/Api/StudyRoom/StudyRoomService.dart';

import '../../helpers/helpers.dart';

const _host = StudyRoomMemberModel(
  userId: 10,
  name: '방장',
  totalStudyLevel: 3,
  currentStreak: 5,
  weeklyProblemCount: 12,
  weeklyPracticeCount: 4,
);
const _member = StudyRoomMemberModel(
  userId: 20,
  name: '멤버',
  totalStudyLevel: 1,
  currentStreak: 0,
  weeklyProblemCount: 3,
  weeklyPracticeCount: 1,
);

StudyRoomModel _room() => const StudyRoomModel(
      roomId: 1,
      name: '알고리즘 스터디',
      hostUserId: 10,
      members: [_host, _member],
    );

UserProvider _buildUserProvider(int userId) {
  final problems = ProblemsProvider();
  final folders = FoldersProvider(problemsProvider: problems);
  final practice = ProblemPracticeProvider(problemsProvider: problems);
  return UserProvider(problems, folders, practice)
    ..userInfoModel = UserInfoModel(userId: userId);
}

void main() {
  setUpOnoWidgetTest();

  late MockStudyRoomService service;
  late StudyRoomProvider studyRoomProvider;

  setUp(() {
    service = MockStudyRoomService();
    studyRoomProvider = StudyRoomProvider(studyRoomService: service);
    when(() => service.fetchFeed(any(), cursor: any(named: 'cursor')))
        .thenAnswer((_) async => const CursorPage(
              content: [],
              nextCursor: null,
              hasNext: false,
            ));
    when(() => service.fetchChallenges(any())).thenAnswer((_) async => []);
    when(() => service.fetchSharedProblems(any(), cursor: any(named: 'cursor')))
        .thenAnswer((_) async => const CursorPage(
              content: [],
              nextCursor: null,
              hasNext: false,
            ));
    when(() => service.fetchWeeklyReports(roomId: any(named: 'roomId')))
        .thenAnswer((_) async => []);
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    required int currentUserId,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomDetailScreen(roomId: 1),
        studyRoomProvider: studyRoomProvider,
        userProvider: _buildUserProvider(currentUserId),
        surfaceSize: surfaceSize,
      );
    });
  }

  testWidgets('로딩 중에는 스피너가 뜬다', (tester) async {
    // Future.delayed 는 실제 Timer 를 만들어 테스트 종료 시 "pending timer"
    // 로 실패하므로, 직접 완료 시점을 제어할 수 있는 Completer 를 쓴다.
    final completer = Completer<StudyRoomModel>();
    when(() => service.fetchRoomDetail(1)).thenAnswer((_) => completer.future);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomDetailScreen(roomId: 1),
        studyRoomProvider: studyRoomProvider,
        userProvider: _buildUserProvider(10),
        settle: false,
      );
    });

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_room());
    await tester.pump();
  });

  testWidgets('방을 못 불러오면 안내 문구가 뜬다', (tester) async {
    when(() => service.fetchRoomDetail(1)).thenThrow(Exception('network'));

    await pumpDetail(tester, currentUserId: 10);

    expect(find.text('방을 찾을 수 없습니다'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('정상 응답이면 방 이름과 멤버 수, 탭 4개가 보인다', (tester) async {
    when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room());

    await pumpDetail(tester, currentUserId: 10);

    expect(find.text('알고리즘 스터디'), findsWidgets);
    expect(find.text('멤버 2명'), findsOneWidget);
    expect(find.text('랭킹'), findsOneWidget);
    expect(find.text('챌린지'), findsOneWidget);
    expect(find.text('공유'), findsOneWidget);
    expect(find.text('활동'), findsOneWidget);
  });

  testWidgets('랭킹 탭은 주간 문제 수 내림차순으로 정렬된다', (tester) async {
    when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room());

    await pumpDetail(tester, currentUserId: 10);

    // 방장(12문제)이 멤버(3문제)보다 먼저(더 위에) 나와야 한다.
    final hostCard = find.text('방장');
    final memberCard = find.text('멤버');
    expect(hostCard, findsOneWidget);
    expect(memberCard, findsOneWidget);
    expect(
      tester.getTopLeft(hostCard).dy,
      lessThan(tester.getTopLeft(memberCard).dy),
    );
  });

  group('더보기 메뉴 — 권한별 조건부 표시', () {
    testWidgets('방장이면 정보 수정·멤버 관리·방 삭제가 모두 보인다', (tester) async {
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room());

      await pumpDetail(tester, currentUserId: 10);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('스터디룸 정보 수정'), findsOneWidget);
      expect(find.text('멤버 관리'), findsOneWidget);
      expect(find.text('방 삭제하기'), findsOneWidget);
      expect(find.text('스터디룸 탈퇴'), findsOneWidget);
    });

    testWidgets('일반 멤버면 정보 수정·멤버 관리·방 삭제가 안 보이고 탈퇴만 보인다', (tester) async {
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room());

      await pumpDetail(tester, currentUserId: 20);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('스터디룸 정보 수정'), findsNothing);
      expect(find.text('멤버 관리'), findsNothing);
      expect(find.text('방 삭제하기'), findsNothing);
      expect(find.text('스터디룸 탈퇴'), findsOneWidget);
    });
  });

  group('멤버 관리 — 소유권에 따른 내보내기 버튼', () {
    testWidgets('방장 화면에서는 나 자신과 방장 본인에게 내보내기 버튼이 없다', (tester) async {
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room());

      await pumpDetail(tester, currentUserId: 10);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('멤버 관리'));
      await tester.pumpAndSettle();

      // 방장(나)에게는 내보내기 버튼이 없고, 일반 멤버에게는 있다.
      expect(find.text('내보내기'), findsOneWidget);
    });
  });

  testWidgets('초대 코드 버튼을 누르면 초대 코드 시트가 뜬다', (tester) async {
    when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room());
    when(() => service.generateInviteCode(1)).thenAnswer(
      (_) async => InviteCodeModel(
        code: 'ABC123',
        expiredAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    await pumpDetail(tester, currentUserId: 10);

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();

    expect(find.text('초대 코드'), findsOneWidget);
  });

  // TODO(#174): 실제 버그. lib/Model/StudyRoom/InviteCodeModel.dart:12-13 —
  // expiredAt 이 없는 응답을 받으면 DateTime.now() 로 대체되어, 방금 만든
  // 초대 코드가 만료 임박(사실상 즉시 만료)으로 보인다. generateInviteCode 가
  // expiredAt 없는 응답을 흉내내면, 시트에 표시되는 만료 시각이 "지금" 이 된다.
  testWidgets(
    '초대 코드 응답에 expiredAt이 없으면 만료 시각이 지금으로 표시된다 (버그)',
    (tester) async {
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room());
      when(() => service.generateInviteCode(1)).thenAnswer(
        (_) async => InviteCodeModel.fromJson(const {'code': 'ABC123'}),
      );

      await pumpDetail(tester, currentUserId: 10);
      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pumpAndSettle();

      final expiryText =
          tester.widgetList<Text>(find.textContaining('만료:')).first.data!;
      final now = DateTime.now();
      final expected =
          '만료: ${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      expect(expiryText, expected);
    },
    skip: true, // #174 에서 수정 예정
  );

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room());

    await pumpDetail(
      tester,
      currentUserId: 10,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(StudyRoomDetailScreen), findsOneWidget);
  });
}
