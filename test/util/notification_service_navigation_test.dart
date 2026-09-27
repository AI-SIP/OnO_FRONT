// 알림을 눌렀을 때 실제로 화면이 열리는지 보는 테스트 (#253).
//
// 분기표만으로는 "결정했지만 열지 않는" 상태를 못 잡아서, 스터디룸 계열은
// 화면이 실제로 뜨는 데까지 확인한다. 백그라운드 탭과 종료 상태 탭이 모두
// 이 경로(navigateByNotificationData)로 모인다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/StudyRoom/SharedProblemModel.dart';
import 'package:ono/Model/StudyRoom/StudyRoomMemberModel.dart';
import 'package:ono/Model/StudyRoom/StudyRoomModel.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Provider/ScreenIndexProvider.dart';
import 'package:ono/Provider/StudyRoomProvider.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/StudyRoom/SharedProblemDetailScreen.dart';
import 'package:ono/Screen/StudyRoom/StudyRoomDetailScreen.dart';
import 'package:ono/Service/Api/StudyRoom/StudyRoomService.dart';
import 'package:ono/Util/NotificationService.dart';

import '../helpers/helpers.dart';

const _host = StudyRoomMemberModel(
  userId: 10,
  name: '방장',
  totalStudyLevel: 3,
  currentStreak: 5,
  weeklyProblemCount: 12,
  weeklyPracticeCount: 4,
);

StudyRoomModel _room() => const StudyRoomModel(
      roomId: 7,
      name: '알고리즘 스터디',
      hostUserId: 10,
      members: [_host],
    );

SharedProblemModel _sharedProblem() => SharedProblemModel(
      sharedProblemId: 15,
      sharedByUserId: 10,
      sharedByName: '방장',
      problemImageUrls: const [],
      reference: '수학의 정석 12쪽',
      comment: '이거 같이 풀어요',
      sharedAt: DateTime(2026, 9, 1),
      reactions: const [],
    );

UserProvider _buildUserProvider() {
  final problems = ProblemsProvider();
  final folders = FoldersProvider(problemsProvider: problems);
  final practice = ProblemPracticeProvider(problemsProvider: problems);
  return UserProvider(problems, folders, practice)
    ..userInfoModel = UserInfoModel(userId: 10);
}

void main() {
  setUpOnoWidgetTest();

  late MockStudyRoomService service;
  late StudyRoomProvider studyRoomProvider;
  late ScreenIndexProvider screenIndexProvider;

  setUp(() {
    service = MockStudyRoomService();
    studyRoomProvider = StudyRoomProvider(studyRoomService: service);
    screenIndexProvider = ScreenIndexProvider();

    when(() => service.fetchRoomDetail(any())).thenAnswer((_) async => _room());
    when(() => service.fetchFeed(any(), cursor: any(named: 'cursor')))
        .thenAnswer((_) async => const CursorPage(
              content: [],
              nextCursor: null,
              hasNext: false,
            ));
    when(() => service.fetchChallenges(any())).thenAnswer((_) async => []);
    when(() => service.fetchSharedProblems(any(), cursor: any(named: 'cursor')))
        .thenAnswer((_) async => CursorPage(
              content: [_sharedProblem()],
              nextCursor: null,
              hasNext: false,
            ));
    when(() => service.fetchWeeklyReports(roomId: any(named: 'roomId')))
        .thenAnswer((_) async => []);
    when(() => service.fetchSharedProblemComments(
          roomId: any(named: 'roomId'),
          sharedProblemId: any(named: 'sharedProblemId'),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => const CursorPage(
          content: [],
          nextCursor: null,
          hasNext: false,
        ));
  });

  /// 홈 자리에 빈 화면을 두고, 알림을 눌렀을 때처럼 [data] 를 흘려보낸다.
  Future<void> tapNotification(
    WidgetTester tester,
    Map<String, dynamic> data,
  ) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const Scaffold(body: Center(child: Text('홈'))),
        studyRoomProvider: studyRoomProvider,
        userProvider: _buildUserProvider(),
        screenIndexProvider: screenIndexProvider,
      );

      await NotificationService.instance.navigateByNotificationData(data);
      await tester.pumpAndSettle();
    });
  }

  testWidgets('CHALLENGE_NOTIFICATION 을 누르면 스터디룸 상세가 열린다', (tester) async {
    await tapNotification(tester, {
      'type': 'CHALLENGE_NOTIFICATION',
      'roomId': '7',
    });

    expect(find.byType(StudyRoomDetailScreen), findsOneWidget);
    expect(find.text('알고리즘 스터디'), findsWidgets);
  });

  testWidgets('소문자 challenge_completed 도 같은 화면을 연다', (tester) async {
    await tapNotification(tester, {
      'type': 'challenge_completed',
      'roomId': '7',
    });

    expect(find.byType(StudyRoomDetailScreen), findsOneWidget);
  });

  testWidgets('스터디룸 알림은 하단 탭도 스터디룸으로 옮긴다', (tester) async {
    await tapNotification(tester, {
      'type': 'CHALLENGE_NOTIFICATION',
      'roomId': '7',
    });

    expect(screenIndexProvider.screenIndex, 3);
  });

  testWidgets('SHARED_PROBLEM_COMMENT 를 누르면 공유 문제 상세까지 열린다', (tester) async {
    await tapNotification(tester, {
      'type': 'SHARED_PROBLEM_COMMENT',
      'roomId': '7',
      'sharedProblemId': '15',
    });

    expect(find.byType(SharedProblemDetailScreen), findsOneWidget);
    expect(find.text('이거 같이 풀어요'), findsWidgets);
  });

  testWidgets('소문자 shared_problem 도 공유 문제 상세까지 연다', (tester) async {
    await tapNotification(tester, {
      'type': 'shared_problem',
      'roomId': '7',
      'sharedProblemId': '15',
    });

    expect(find.byType(SharedProblemDetailScreen), findsOneWidget);
  });

  testWidgets('공유 문제를 찾지 못하면 방 화면까지만 열고 끝낸다', (tester) async {
    await tapNotification(tester, {
      'type': 'SHARED_PROBLEM',
      'roomId': '7',
      'sharedProblemId': '9999',
    });

    expect(find.byType(StudyRoomDetailScreen), findsOneWidget);
    expect(find.byType(SharedProblemDetailScreen), findsNothing);
  });

  testWidgets('모르는 알림은 아무 화면도 열지 않는다', (tester) async {
    await tapNotification(tester, {'type': 'something_new'});

    expect(find.text('홈'), findsOneWidget);
    expect(find.byType(StudyRoomDetailScreen), findsNothing);
  });
}
