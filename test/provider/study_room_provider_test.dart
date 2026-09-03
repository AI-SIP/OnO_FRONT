// StudyRoomProvider 상태 전이 테스트.
//
// isLoading 이 여러 메서드에서 공유되는 단일 플래그라 항상 try/finally 로
// 리셋되는지, 페이지네이션 가드(hasNext/isLoadingMore/nextCursor)가 실제로
// 도는지, 부분 실패를 흡수하는 fetchRoomDetail 이 나머지 데이터를 살리는지를
// 본다. FirebaseAnalytics 호출이 섞여 있어 support/provider_test_env 로
// 스텁을 깐다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/StudyRoom/ActivityFeedModel.dart';
import 'package:ono/Model/StudyRoom/FeedReactionModel.dart';
import 'package:ono/Model/StudyRoom/SharedProblemCommentModel.dart';
import 'package:ono/Model/StudyRoom/SharedProblemModel.dart';
import 'package:ono/Model/StudyRoom/StudyRoomMemberModel.dart';
import 'package:ono/Model/StudyRoom/StudyRoomModel.dart';
import 'package:ono/Model/StudyRoom/WeeklyReportModel.dart';
import 'package:ono/Provider/StudyRoomProvider.dart';
import 'package:ono/Service/Api/StudyRoom/StudyRoomService.dart';

import '../helpers/helpers.dart';
import 'support/provider_test_env.dart';

StudyRoomModel _room(int id, {String? name, int hostUserId = 1}) {
  return StudyRoomModel(
    roomId: id,
    name: name ?? 'room-$id',
    hostUserId: hostUserId,
    members: const [],
  );
}

ActivityFeedModel _feed(int id) {
  return ActivityFeedModel(
    feedId: id,
    userId: 1,
    userName: 'tester',
    eventType: 'problem_solved',
    createdAt: DateTime(2024, 1, 1),
    reactions: [],
  );
}

SharedProblemModel _shared(int id) {
  return SharedProblemModel(
    sharedProblemId: id,
    sharedByUserId: 1,
    sharedByName: 'tester',
    problemImageUrls: const [],
    reference: 'ref',
    sharedAt: DateTime(2024, 1, 1),
    reactions: [],
  );
}

SharedProblemCommentModel _comment(int id) {
  return SharedProblemCommentModel(
    commentId: id,
    content: 'comment-$id',
    authorId: 1,
    authorName: 'tester',
    createdAt: DateTime(2024, 1, 1),
    isEdited: false,
    isMine: true,
    canDelete: true,
    reactions: [],
  );
}

void main() {
  setUpOnoTest();

  setUpAll(setUpProviderTestEnv);

  late MockStudyRoomService service;
  late StudyRoomProvider provider;
  late NotifyRecorder notified;

  setUp(() {
    service = MockStudyRoomService();
    provider = StudyRoomProvider(studyRoomService: service);
    notified = NotifyRecorder();
    provider.addListener(notified.call);
  });

  group('초기 상태', () {
    test('아무 것도 안 했을 때 방 목록도 로딩도 없다', () {
      expect(provider.rooms, isEmpty);
      expect(provider.selectedRoom, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.feedItems, isEmpty);
      expect(provider.challenges, isEmpty);
      expect(provider.sharedProblems, isEmpty);
    });
  });

  group('fetchMyRooms', () {
    test('성공하면 방 목록이 채워지고 isLoading 이 false 로 돌아온다', () async {
      when(() => service.fetchMyRooms()).thenAnswer((_) async => [_room(1)]);

      await provider.fetchMyRooms();

      expect(provider.rooms.map((r) => r.roomId), [1]);
      expect(provider.isLoading, isFalse);
      expect(notified.count, greaterThan(0));
    });

    test('실패해도 isLoading 은 반드시 false 로 돌아온다 (스피너가 안 멈추는 버그 방지)', () async {
      when(() => service.fetchMyRooms()).thenThrow(Exception('network error'));

      await expectLater(provider.fetchMyRooms(), throwsA(isA<Exception>()));

      expect(provider.isLoading, isFalse);
      expect(provider.rooms, isEmpty);
    });
  });

  group('fetchRoomDetail', () {
    test('피드/챌린지/공유문제/주간리포트 중 일부가 실패해도 나머지는 반영된다', () async {
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room(1));
      when(() => service.fetchFeed(1, cursor: null))
          .thenThrow(Exception('feed down'));
      when(() => service.fetchChallenges(1)).thenAnswer((_) async => []);
      when(() => service.fetchSharedProblems(1, cursor: null))
          .thenAnswer((_) async => CursorPage(
                content: [_shared(1)],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchWeeklyReports(roomId: 1))
          .thenAnswer((_) async => []);

      await provider.fetchRoomDetail(1); // 던지지 않아야 한다

      expect(provider.selectedRoom?.roomId, 1);
      expect(provider.feedItems, isEmpty); // 실패한 부분은 비어있게 유지
      expect(provider.sharedProblems.map((s) => s.sharedProblemId), [1]);
      expect(provider.isLoading, isFalse);
    });

    test('rooms 목록에 있던 같은 방은 최신 정보로 교체된다', () async {
      when(() => service.fetchMyRooms())
          .thenAnswer((_) async => [_room(1, name: '옛 이름')]);
      await provider.fetchMyRooms();

      when(() => service.fetchRoomDetail(1))
          .thenAnswer((_) async => _room(1, name: '새 이름'));
      when(() => service.fetchFeed(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchChallenges(1)).thenAnswer((_) async => []);
      when(() => service.fetchSharedProblems(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchWeeklyReports(roomId: 1))
          .thenAnswer((_) async => []);

      await provider.fetchRoomDetail(1);

      expect(provider.rooms.first.name, '새 이름');
    });
  });

  group('createRoom / joinRoom / leaveRoom / deleteRoom', () {
    test('생성한 방이 목록에 추가된다', () async {
      when(() => service.createRoom('스터디'))
          .thenAnswer((_) async => _room(9, name: '스터디'));

      final created = await provider.createRoom('스터디');

      expect(created.roomId, 9);
      expect(provider.rooms.map((r) => r.roomId), [9]);
      expect(provider.isLoading, isFalse);
    });

    test('leaveRoom 은 목록에서 빠지고, 선택된 방이었다면 선택도 풀린다', () async {
      when(() => service.fetchMyRooms()).thenAnswer((_) async => [_room(1)]);
      await provider.fetchMyRooms();
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room(1));
      when(() => service.fetchFeed(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchChallenges(1)).thenAnswer((_) async => []);
      when(() => service.fetchSharedProblems(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchWeeklyReports(roomId: 1))
          .thenAnswer((_) async => []);
      await provider.fetchRoomDetail(1);

      when(() => service.leaveRoom(1)).thenAnswer((_) async {});

      await provider.leaveRoom(1);

      expect(provider.rooms, isEmpty);
      expect(provider.selectedRoom, isNull);
    });

    test('deleteRoom 실패해도 isLoading 은 false 로 돌아온다', () async {
      when(() => service.fetchMyRooms()).thenAnswer((_) async => [_room(1)]);
      await provider.fetchMyRooms();
      when(() => service.deleteRoom(1)).thenThrow(Exception('boom'));

      await expectLater(provider.deleteRoom(1), throwsA(isA<Exception>()));

      expect(provider.isLoading, isFalse);
      // 실패했으니 목록에서 지워지지 않아야 한다.
      expect(provider.rooms.map((r) => r.roomId), [1]);
    });
  });

  group('updateRoomThumbnail (동시 호출 가드)', () {
    test('업로드 중 재호출하면 두 번째 호출은 무시된다', () async {
      var callCount = 0;
      when(() => service.uploadRoomThumbnail(
            roomId: 1,
            imagePath: any(named: 'imagePath'),
          )).thenAnswer((_) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'https://cdn.test/thumb.png';
      });
      when(() => service.fetchMyRooms()).thenAnswer((_) async => [_room(1)]);
      await provider.fetchMyRooms();

      final first = provider.updateRoomThumbnail(1, '/tmp/a.png');
      final second = provider.updateRoomThumbnail(1, '/tmp/b.png');
      await Future.wait([first, second]);

      expect(callCount, 1);
      expect(provider.rooms.first.thumbnailImagePath,
          'https://cdn.test/thumb.png');
    });
  });

  group('loadMoreFeed (페이지네이션)', () {
    test('커서를 이어받아 목록에 이어 붙인다', () async {
      when(() => service.fetchFeed(1, cursor: null)).thenAnswer(
        (_) async => CursorPage(
          content: [_feed(1)],
          nextCursor: 1,
          hasNext: true,
        ),
      );
      await provider.fetchFeed(1);

      when(() => service.fetchFeed(1, cursor: 1)).thenAnswer(
        (_) async => CursorPage(
          content: [_feed(2)],
          nextCursor: null,
          hasNext: false,
        ),
      );

      await provider.loadMoreFeed(1);

      expect(provider.feedItems.map((f) => f.feedId), [1, 2]);
      expect(provider.feedHasNext, isFalse);
      expect(provider.isFeedLoadingMore, isFalse);
    });

    test('hasNext 가 false 면 더 부르지 않는다', () async {
      when(() => service.fetchFeed(1, cursor: null)).thenAnswer(
        (_) async => const CursorPage(
          content: [],
          nextCursor: null,
          hasNext: false,
        ),
      );
      await provider.fetchFeed(1);
      clearInteractions(service);

      await provider.loadMoreFeed(1);

      verifyNever(() => service.fetchFeed(any(), cursor: any(named: 'cursor')));
    });

    test('이미 로딩 중이면 재진입하지 않는다', () async {
      when(() => service.fetchFeed(1, cursor: null)).thenAnswer(
        (_) async => CursorPage(
          content: [_feed(1)],
          nextCursor: 1,
          hasNext: true,
        ),
      );
      await provider.fetchFeed(1);

      var callCount = 0;
      when(() => service.fetchFeed(1, cursor: 1)).thenAnswer((_) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const CursorPage(content: [], nextCursor: null, hasNext: false);
      });

      final first = provider.loadMoreFeed(1);
      final second = provider.loadMoreFeed(1);
      await Future.wait([first, second]);

      expect(callCount, 1);
    });
  });

  group('toggleFeedReaction', () {
    test('반응 결과로 해당 피드의 reactions 만 갱신된다', () async {
      // toggleFeedReaction 은 selectedRoom(또는 _activeRoomId)이 있어야
      // roomId 를 알 수 있으므로, fetchRoomDetail 로 방을 선택해 둔다.
      when(() => service.fetchMyRooms()).thenAnswer((_) async => [_room(1)]);
      await provider.fetchMyRooms();
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room(1));
      when(() => service.fetchFeed(1, cursor: null)).thenAnswer(
        (_) async => CursorPage(
          content: [_feed(1)],
          nextCursor: null,
          hasNext: false,
        ),
      );
      when(() => service.fetchChallenges(1)).thenAnswer((_) async => []);
      when(() => service.fetchSharedProblems(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchWeeklyReports(roomId: 1))
          .thenAnswer((_) async => []);
      await provider.fetchRoomDetail(1);
      provider.updateCurrentUserId(1);

      when(() => service.toggleFeedReaction(
            roomId: 1,
            feedId: 1,
            emoji: any(named: 'emoji'),
          )).thenAnswer(
        (_) async =>
            [FeedReactionModel(emoji: '👍', count: 1, reactedByMe: true)],
      );

      await provider.toggleFeedReaction(1, '👍');

      expect(provider.feedItems.first.reactions, hasLength(1));
    });

    test('존재하지 않는 feedId 면 아무 것도 하지 않는다', () async {
      await provider.toggleFeedReaction(999, '👍');

      verifyNever(() => service.toggleFeedReaction(
            roomId: any(named: 'roomId'),
            feedId: any(named: 'feedId'),
            emoji: any(named: 'emoji'),
          ));
    });
  });

  group('shareProblems / deleteSharedProblem', () {
    test('공유한 문제가 목록 맨 앞에 추가된다', () async {
      when(() => service.fetchMyRooms()).thenAnswer((_) async => [_room(1)]);
      await provider.fetchMyRooms();
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room(1));
      when(() => service.fetchFeed(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchChallenges(1)).thenAnswer((_) async => []);
      when(() => service.fetchSharedProblems(1, cursor: null))
          .thenAnswer((_) async => CursorPage(
                content: [_shared(1)],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchWeeklyReports(roomId: 1))
          .thenAnswer((_) async => []);
      await provider.fetchRoomDetail(1);

      when(() => service.shareProblems(
            roomId: 1,
            problemId: 42,
            comment: any(named: 'comment'),
          )).thenAnswer((_) async => _shared(2));

      await provider.shareProblems(42);

      expect(provider.sharedProblems.map((s) => s.sharedProblemId), [2, 1]);
    });

    test('삭제하면 목록과 댓글 캐시에서 함께 빠진다', () async {
      when(() => service.fetchMyRooms()).thenAnswer((_) async => [_room(1)]);
      await provider.fetchMyRooms();
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room(1));
      when(() => service.fetchFeed(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchChallenges(1)).thenAnswer((_) async => []);
      when(() => service.fetchSharedProblems(1, cursor: null))
          .thenAnswer((_) async => CursorPage(
                content: [_shared(1)],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchWeeklyReports(roomId: 1))
          .thenAnswer((_) async => []);
      await provider.fetchRoomDetail(1);
      when(() => service.deleteSharedProblem(roomId: 1, sharedProblemId: 1))
          .thenAnswer((_) async {});

      await provider.deleteSharedProblem(1);

      expect(provider.sharedProblems, isEmpty);
      expect(provider.sharedProblemComments.containsKey(1), isFalse);
    });
  });

  group('공유 문제 댓글', () {
    Future<void> selectRoomWithSharedProblem() async {
      when(() => service.fetchMyRooms()).thenAnswer((_) async => [_room(1)]);
      await provider.fetchMyRooms();
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room(1));
      when(() => service.fetchFeed(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchChallenges(1)).thenAnswer((_) async => []);
      when(() => service.fetchSharedProblems(1, cursor: null))
          .thenAnswer((_) async => CursorPage(
                content: [_shared(1)],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchWeeklyReports(roomId: 1))
          .thenAnswer((_) async => []);
      await provider.fetchRoomDetail(1);
    }

    test('작성하면 댓글 캐시와 sharedProblem.commentCount 가 함께 늘어난다', () async {
      await selectRoomWithSharedProblem();
      when(() => service.createSharedProblemComment(
            roomId: 1,
            sharedProblemId: 1,
            content: '좋아요',
          )).thenAnswer((_) async => _comment(1));

      await provider.createSharedProblemComment(1, '좋아요');

      expect(provider.sharedProblemComments[1], hasLength(1));
      expect(provider.sharedProblems.first.commentCount, 1);
    });

    test('삭제하면 댓글 캐시에서 빠지고 commentCount 는 0 밑으로 내려가지 않는다', () async {
      await selectRoomWithSharedProblem();
      when(() => service.createSharedProblemComment(
            roomId: 1,
            sharedProblemId: 1,
            content: '좋아요',
          )).thenAnswer((_) async => _comment(1));
      await provider.createSharedProblemComment(1, '좋아요');

      when(() => service.deleteSharedProblemComment(
            roomId: 1,
            sharedProblemId: 1,
            commentId: 1,
          )).thenAnswer((_) async {});

      await provider.deleteSharedProblemComment(
        sharedProblemId: 1,
        commentId: 1,
      );
      // 같은 댓글을 또 지우는 상황을 흉내내도(캐시엔 이미 없음) 음수로 내려가면 안 된다.
      await provider.deleteSharedProblemComment(
        sharedProblemId: 1,
        commentId: 1,
      );

      expect(provider.sharedProblemComments[1], isEmpty);
      expect(provider.sharedProblems.first.commentCount, 0);
    });
  });

  group('markReportRead', () {
    test('서버 실패와 무관하게 낙관적으로 isRead 가 true 로 유지된다 (의도된 동작)', () async {
      when(() => service.fetchMyRooms()).thenAnswer((_) async => [_room(1)]);
      await provider.fetchMyRooms();
      when(() => service.fetchRoomDetail(1)).thenAnswer((_) async => _room(1));
      when(() => service.fetchFeed(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchChallenges(1)).thenAnswer((_) async => []);
      when(() => service.fetchSharedProblems(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchWeeklyReports(roomId: 1)).thenAnswer(
        (_) async => [
          WeeklyReportModel(
            reportId: 1,
            topMemberName: 'a',
            topMemberProblemCount: 1,
            longestStreakName: 'b',
            longestStreakDays: 1,
            totalProblems: 1,
            challengesCompleted: 0,
            cheerMessage: '화이팅',
          ),
        ],
      );
      await provider.fetchRoomDetail(1);
      when(() => service.markWeeklyReportRead(roomId: 1, reportId: 1))
          .thenThrow(Exception('network error'));

      await provider.markReportRead(); // 던지지 않아야 한다

      expect(provider.weeklyReport?.isRead, isTrue);
    });
  });

  group('setMyGoal', () {
    test('나(currentUserId)의 멤버 정보만 목표치가 갱신된다', () async {
      const me = StudyRoomMemberModel(
        userId: 1,
        name: '나',
        totalStudyLevel: 1,
        currentStreak: 0,
        weeklyProblemCount: 0,
        weeklyPracticeCount: 0,
      );
      const other = StudyRoomMemberModel(
        userId: 2,
        name: '남',
        totalStudyLevel: 1,
        currentStreak: 0,
        weeklyProblemCount: 0,
        weeklyPracticeCount: 0,
      );
      when(() => service.fetchMyRooms()).thenAnswer((_) async => [_room(1)]);
      await provider.fetchMyRooms();
      when(() => service.fetchRoomDetail(1)).thenAnswer(
        (_) async => const StudyRoomModel(
          roomId: 1,
          name: 'room-1',
          hostUserId: 1,
          members: [me, other],
        ),
      );
      when(() => service.fetchFeed(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchChallenges(1)).thenAnswer((_) async => []);
      when(() => service.fetchSharedProblems(1, cursor: null))
          .thenAnswer((_) async => const CursorPage(
                content: [],
                nextCursor: null,
                hasNext: false,
              ));
      when(() => service.fetchWeeklyReports(roomId: 1))
          .thenAnswer((_) async => []);
      await provider.fetchRoomDetail(1);
      provider.updateCurrentUserId(1);

      when(() => service.setMyGoal(roomId: 1, weeklyGoal: 5))
          .thenAnswer((_) async => (weeklyGoal: 5, goalProgress: 0));

      await provider.setMyGoal(5);

      final updatedMe =
          provider.selectedRoom!.members.firstWhere((m) => m.userId == 1);
      final updatedOther =
          provider.selectedRoom!.members.firstWhere((m) => m.userId == 2);
      expect(updatedMe.weeklyGoal, 5);
      expect(updatedOther.weeklyGoal, isNull);
    });
  });
}
