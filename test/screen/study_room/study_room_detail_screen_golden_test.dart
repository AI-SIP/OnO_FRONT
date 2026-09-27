// 스터디룸 상세 화면 골든 테스트.
//
// 활동 피드의 `N시간 전`, `N일 전` 과 챌린지의 `N일 남음` 은 지금 시각에 매여서,
// 날짜를 골든 시계(goldenNow) 기준으로 적는다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/StudyRoom/ActivityFeedModel.dart';
import 'package:ono/Model/StudyRoom/ChallengeMemberProgressModel.dart';
import 'package:ono/Model/StudyRoom/ChallengeModel.dart';
import 'package:ono/Model/StudyRoom/FeedReactionModel.dart';
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

void main() {
  setUpOnoWidgetTest();

  const host = StudyRoomMemberModel(
    userId: 10,
    name: '방장',
    totalStudyLevel: 3,
    currentStreak: 5,
    weeklyProblemCount: 12,
    weeklyPracticeCount: 4,
  );
  const member = StudyRoomMemberModel(
    userId: 20,
    name: '멤버',
    totalStudyLevel: 1,
    currentStreak: 0,
    weeklyProblemCount: 3,
    weeklyPracticeCount: 1,
  );

  Future<Widget> buildApp() async {
    final service = MockStudyRoomService();
    when(() => service.fetchRoomDetail(1)).thenAnswer(
      (_) async => const StudyRoomModel(
        roomId: 1,
        name: '알고리즘 스터디',
        hostUserId: 10,
        members: [host, member],
      ),
    );
    when(() => service.fetchFeed(any(), cursor: any(named: 'cursor')))
        .thenAnswer(
      (_) async => CursorPage(
        content: [
          ActivityFeedModel(
            feedId: 1,
            userId: 20,
            userName: '멤버',
            eventType: 'practice_completed',
            createdAt: goldenNow.subtract(const Duration(hours: 2)),
            reactions: [
              FeedReactionModel(emoji: '👍', count: 2, reactedByMe: true),
            ],
          ),
          ActivityFeedModel(
            feedId: 2,
            userId: 10,
            userName: '방장',
            eventType: 'problem_registered',
            createdAt: goldenNow.subtract(const Duration(days: 3)),
            reactions: [],
          ),
        ],
        nextCursor: null,
        hasNext: false,
      ),
    );
    when(() => service.fetchChallenges(any())).thenAnswer(
      (_) async => [
        ChallengeModel(
          challengeId: 1,
          title: '이번 주 20문제',
          type: 'group',
          metric: 'problem_count',
          period: 'weekly',
          targetValue: 20,
          endAt: goldenNow.add(const Duration(days: 4, hours: 1)),
          status: 'in_progress',
          memberProgress: const [
            ChallengeMemberProgressModel(
              userId: 10,
              name: '방장',
              current: 12,
              cleared: false,
            ),
            ChallengeMemberProgressModel(
              userId: 20,
              name: '멤버',
              current: 3,
              cleared: false,
            ),
          ],
          groupCurrent: 15,
        ),
      ],
    );
    when(() => service.fetchSharedProblems(any(), cursor: any(named: 'cursor')))
        .thenAnswer((_) async => const CursorPage(
              content: [],
              nextCursor: null,
              hasNext: false,
            ));
    when(() => service.fetchWeeklyReports(roomId: any(named: 'roomId')))
        .thenAnswer((_) async => []);

    final problems = ProblemsProvider();
    final folders = FoldersProvider(problemsProvider: problems);
    final practice = ProblemPracticeProvider(problemsProvider: problems);
    final userProvider = UserProvider(problems, folders, practice)
      ..userInfoModel = UserInfoModel(userId: 10);

    return buildOnoApp(
      const StudyRoomDetailScreen(roomId: 1),
      cosmeticProvider: await loadedCosmeticProvider(),
      studyRoomProvider: StudyRoomProvider(studyRoomService: service),
      userProvider: userProvider,
    );
  }

  // 활동 피드와 챌린지는 기본 탭(랭킹)에 없어서 탭을 옮겨 뜬다. 날짜 문구가
  // 나오는 곳이 이 둘이다.
  for (final tab
      in {'ranking': null, 'challenge': '챌린지', 'feed': '활동'}.entries) {
    screenGoldenTest(
      '스터디룸 상세 화면 ${tab.key}',
      fileName: 'study_room_detail_screen_${tab.key}',
      surfaces: GoldenSurface.layouts,
      buildApp: buildApp,
      prepare: tab.value == null
          ? null
          : (tester) => tester.tap(find.text(tab.value!)),
    );
  }
}
