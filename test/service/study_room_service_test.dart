import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/StudyRoom/StudyRoomService.dart';

import '../helpers/helpers.dart';

/// StudyRoomService 계약 테스트.
///
/// StudyRoomService 는 [HttpService] 가 상태 코드·errorCode 에 따라 예외를 어떻게
/// 나누는지는 다루지 않는다 (그 로직은 helpers_smoke_test.dart 가 이미 검증한다).
/// 여기서는 fetchRoomDetail / createRoom 두 대표 메서드로 그 분기가 StudyRoomService
/// 를 통해서도 그대로 나오는지만 재확인하고, 나머지 메서드들은 URL·쿼리·바디·응답
/// 매핑 계약에 집중한다.
void main() {
  setUpOnoTest();

  StudyRoomService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return StudyRoomService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  final roomJson = {
    'roomId': 1,
    'name': '스터디룸',
    'hostUserId': 10,
    'members': [
      {
        'userId': 10,
        'name': '기승민',
        'totalStudyLevel': 3,
        'currentStreak': 5,
        'weeklyProblemCount': 12,
        'weeklyPracticeCount': 4,
      },
    ],
    'thumbnailUrl': 'https://cdn.test/room.png',
    'memberCount': 4,
    'todayPracticeMemberCount': 2,
    'todayPracticeCount': 6,
    'hasUnreadReport': true,
  };

  final feedJson = {
    'feedId': 1,
    'userId': 10,
    'userName': '기승민',
    'eventType': 'problem_registered',
    'metadata': {'count': 3},
    'createdAt': '2026-09-01T10:00:00Z',
    'reactions': [
      {'emoji': '👍', 'count': 2, 'reactedByMe': true},
    ],
  };

  final challengeJson = {
    'challengeId': 5,
    'title': '이번 주 20문제',
    'type': 'group',
    'metric': 'problem_count',
    'period': 'weekly',
    'periodDays': 7,
    'targetValue': 20,
    'startAt': '2026-09-01T00:00:00Z',
    'endAt': '2026-09-07T23:59:59Z',
    'status': 'in_progress',
    'memberProgress': [
      {'userId': 10, 'name': '기승민', 'current': 5, 'cleared': false},
    ],
    'groupCurrent': 5,
  };

  final sharedProblemJson = {
    'sharedProblemId': 3,
    'sharedByUserId': 10,
    'sharedByName': '기승민',
    'problemId': 100,
    'problemImageUrls': ['https://cdn.test/p1.png'],
    'reference': '수학 문제',
    'comment': '이거 어렵네요',
    'commentCount': 2,
    'sharedAt': '2026-09-01T09:00:00Z',
    'reactions': <Map<String, dynamic>>[],
  };

  final commentJson = {
    'commentId': 7,
    'content': '저도 어려웠어요',
    'authorId': 11,
    'authorName': '팀원',
    'createdAt': '2026-09-01T09:30:00Z',
    'isEdited': false,
    'isMine': false,
    'canDelete': false,
    'reactions': <Map<String, dynamic>>[],
  };

  final weeklyReportJson = {
    'reportId': 2,
    'topMemberName': '기승민',
    'topMemberProblemCount': 15,
    'longestStreakName': '팀원',
    'longestStreakDays': 10,
    'totalProblems': 40,
    'challengesCompleted': 2,
    'cheerMessage': '이번 주도 화이팅!',
    'weekStart': '2026-08-25',
    'weekEnd': '2026-08-31',
    'isRead': false,
  };

  // ─────────────────────────────────────────────────────────────
  group('fetchMyRooms', () {
    test('GET /api/study-room 로 방 목록을 가져와 매핑한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([roomJson]));
      final rooms = await buildService(http).fetchMyRooms();

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/study-room');
      expect(http.lastRequest.authorization, 'test-access-token');

      expect(rooms, hasLength(1));
      expect(rooms.first.roomId, 1);
      expect(rooms.first.name, '스터디룸');
      expect(rooms.first.thumbnailImagePath, 'https://cdn.test/room.png');
      expect(rooms.first.serverMemberCount, 4);
      expect(rooms.first.hasUnreadReport, true);
      expect(rooms.first.members, hasLength(1));
    });

    test('응답이 배열이 아니라 객체로 오면 조용히 빈 목록이 된다', () async {
      // 백엔드가 실수로 목록 대신 페이지네이션 모양({content:[...]})으로 감싸 보내도
      // _mapList 는 "List 가 아니다"라고만 판단해 예외 없이 빈 배열을 돌려준다.
      // 화면에는 그냥 "방이 없음"으로 보여서 계약이 깨져도 알아채기 어렵다.
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'content': [roomJson]
        }),
      );
      final rooms = await buildService(http).fetchMyRooms();
      expect(rooms, isEmpty);
    });

    test('data 가 null 이면 빈 목록이 된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(null));
      final rooms = await buildService(http).fetchMyRooms();
      expect(rooms, isEmpty);
    });

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([roomJson]));
      await expectLater(
        buildService(http, accessToken: null).fetchMyRooms(),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });
  });

  group('fetchRoomDetail', () {
    test('GET /api/study-room/{roomId}', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(roomJson));
      final room = await buildService(http).fetchRoomDetail(1);

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/study-room/1');
      expect(room.roomId, 1);
      expect(room.hostUserId, 10);
    });

    test('필수 필드(roomId, name, hostUserId)가 통째로 빠지면 크래시 없이 기본값(0, "")으로 채워진다',
        () async {
      // StudyRoomModel.fromJson 은 모든 필드에 ?? 기본값이 있어 크래시는 나지 않지만,
      // 방 정보가 통째로 사라진 것을 화면에서 "roomId=0, name=''" 방으로 오인할 수 있다.
      final http = TestHttpClient.respondJson(apiEnvelope(<String, dynamic>{}));
      final room = await buildService(http).fetchRoomDetail(1);
      expect(room.roomId, 0);
      expect(room.name, '');
      expect(room.hostUserId, 0);
      expect(room.members, isEmpty);
    });

    test('errorCode 가 1000번대(1005 제외)면 즉시 UnauthorizedException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 401, errorCode: 1001, message: '탈퇴한 사용자'),
      );
      await expectLater(
        buildService(http).fetchRoomDetail(1),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('errorCode 1005(토큰 만료)면 재발급 후 재시도해 성공한다', () async {
      final http = TestHttpClient.sequence([
        errorResponse(statusCode: 401, errorCode: 1005, message: '토큰 만료'),
        jsonResponse(apiEnvelope(roomJson)),
      ]);
      final room = await buildService(http).fetchRoomDetail(1);
      expect(http.callCount, 2);
      expect(room.roomId, 1);
    });

    test('errorCode 가 비인증 대역이면 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 3001, message: '잘못된 요청'),
      );
      await expectLater(
        buildService(http).fetchRoomDetail(1),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('500 이면 ServerException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );
      await expectLater(
        buildService(http).fetchRoomDetail(1),
        throwsA(isA<ServerException>()),
      );
    });

    test('전송 자체가 실패하면 NetworkException', () async {
      final http = TestHttpClient.throwing(const SocketException(''));
      await expectLater(
        buildService(http).fetchRoomDetail(1),
        throwsA(isA<NetworkException>()),
      );
    });

    test('성공 상태인데 응답이 JSON 이 아니면(원문 문자열 반환) 빈 방으로 안전하게 처리된다', () async {
      // HttpService 는 2xx + JSON 파싱 실패면 예외 대신 원문 문자열을 그대로 돌려준다.
      // _asMap 이 String 을 Map 이 아니라고 보고 빈 Map 으로 치환해 크래시는 나지 않는다.
      final http = TestHttpClient.respondWith(textResponse('OK'));
      final room = await buildService(http).fetchRoomDetail(1);
      expect(room.roomId, 0);
    });

    test('실패 상태인데 JSON 이 아니면 ParseException', () async {
      final http = TestHttpClient.respondWith(
        textResponse('Internal Server Error', statusCode: 500),
      );
      await expectLater(
        buildService(http).fetchRoomDetail(1),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('createRoom', () {
    test('POST /api/study-room, 이름은 trim 되어 전송된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(roomJson));
      final room = await buildService(http).createRoom('  새 스터디룸  ');

      expect(http.lastRequest.method, 'POST');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/study-room');
      expect(http.lastRequest.jsonBody, {'name': '새 스터디룸'});
      expect(room.roomId, 1);
    });

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(roomJson));
      await expectLater(
        buildService(http, accessToken: null).createRoom('방'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });
  });

  group('updateRoomName', () {
    test('PATCH /api/study-room/{roomId}, 이름은 trim 되어 전송된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(roomJson));
      final room =
          await buildService(http).updateRoomName(roomId: 1, name: '  바뀐 이름  ');

      expect(http.lastRequest.method, 'PATCH');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/study-room/1');
      expect(http.lastRequest.jsonBody, {'name': '바뀐 이름'});
      expect(room.roomId, 1);
    });
  });

  group('uploadRoomThumbnail', () {
    late File tempImage;

    setUp(() {
      final dir = Directory.systemTemp.createTempSync('ono_test_');
      tempImage = File('${dir.path}/thumb.png')
        ..writeAsBytesSync(const [137, 80, 78, 71]);
    });

    test('PATCH multipart 로 썸네일 파일을 보내고 thumbnailUrl 을 돌려받는다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({'thumbnailUrl': 'https://cdn.test/new.png'}),
      );
      final url = await buildService(http).uploadRoomThumbnail(
        roomId: 1,
        imagePath: tempImage.path,
      );

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/thumbnail',
      );
      expect(http.lastRequest.contentType, contains('multipart/form-data'));
      expect(http.lastRequest.body, contains('name="thumbnail"'));
      expect(url, 'https://cdn.test/new.png');
    });

    test('응답에 thumbnailUrl 이 없으면 null 을 돌려준다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<String, dynamic>{}));
      final url = await buildService(http).uploadRoomThumbnail(
        roomId: 1,
        imagePath: tempImage.path,
      );
      expect(url, isNull);
    });
  });

  group('joinRoom', () {
    test('POST /api/study-room/join, 초대 코드를 그대로 보낸다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(roomJson));
      final room = await buildService(http).joinRoom('ABC123');

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/join',
      );
      expect(http.lastRequest.jsonBody, {'code': 'ABC123'});
      expect(room.roomId, 1);
    });

    test('만료/존재하지 않는 코드는 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 3002, message: '유효하지 않은 코드'),
      );
      await expectLater(
        buildService(http).joinRoom('BAD'),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('leaveRoom / deleteRoom / kickMember', () {
    test('leaveRoom: DELETE /{roomId}/leave, 204 는 예외 없이 끝난다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).leaveRoom(1);

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/leave',
      );
    });

    test('deleteRoom: DELETE /{roomId}', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).deleteRoom(1);

      expect(http.lastRequest.method, 'DELETE');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/study-room/1');
    });

    test('kickMember: DELETE /{roomId}/members/{memberId}', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).kickMember(1, 9);

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/members/9',
      );
    });
  });

  group('generateInviteCode', () {
    test('POST /{roomId}/invite', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'code': 'INVITE1',
          'expiredAt': '2026-12-31T23:59:59Z',
        }),
      );
      final invite = await buildService(http).generateInviteCode(1);

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/invite',
      );
      expect(invite.code, 'INVITE1');
      expect(invite.isExpired, isFalse);
    });

    test('code/expiredAt 이 없으면 code="", expiredAt=지금(즉시 만료)으로 채워진다', () async {
      // InviteCodeModel.fromJson 은 expiredAt 이 없으면 DateTime.now() 로 대체한다.
      // isExpired 는 DateTime.now().isAfter(expiredAt) 이라 호출 시점에 따라
      // 거의 항상 true 가 되어, 방금 만든 초대 코드가 "이미 만료됨"으로 보일 수 있다.
      final http = TestHttpClient.respondJson(apiEnvelope(<String, dynamic>{}));
      final invite = await buildService(http).generateInviteCode(1);
      expect(invite.code, '');
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(invite.isExpired, isTrue);
    });
  });

  group('setMyGoal', () {
    test('PUT /{roomId}/members/me/goal, weeklyGoal 을 그대로 보낸다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({'weeklyGoal': 10, 'goalProgress': 3}),
      );
      final result =
          await buildService(http).setMyGoal(roomId: 1, weeklyGoal: 10);

      expect(http.lastRequest.method, 'PUT');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/members/me/goal',
      );
      expect(http.lastRequest.jsonBody, {'weeklyGoal': 10});
      expect(result.weeklyGoal, 10);
      expect(result.goalProgress, 3);
    });

    test('weeklyGoal 을 null 로 보내면(목표 해제) body 에도 null 이 그대로 담긴다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({'weeklyGoal': null, 'goalProgress': null}),
      );
      final result =
          await buildService(http).setMyGoal(roomId: 1, weeklyGoal: null);

      expect(http.lastRequest.jsonBody, {'weeklyGoal': null});
      expect(result.weeklyGoal, isNull);
      expect(result.goalProgress, isNull);
    });
  });

  group('fetchFeed', () {
    test('cursor 없이 호출하면 size 만 쿼리로 붙는다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'content': [feedJson],
          'nextCursor': 5,
          'hasNext': true,
        }),
      );
      final page = await buildService(http).fetchFeed(1);

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/feed?size=30',
      );
      expect(page.content, hasLength(1));
      expect(page.content.first.feedId, 1);
      expect(page.content.first.displayText, contains('3문제'));
      expect(page.nextCursor, 5);
      expect(page.hasNext, isTrue);
    });

    test('cursor 와 size 를 둘 다 쿼리로 보낸다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({'content': [], 'nextCursor': null, 'hasNext': false}),
      );
      await buildService(http).fetchFeed(1, cursor: 20, size: 10);

      expect(http.lastRequest.queryParameters, {'cursor': '20', 'size': '10'});
    });

    test('응답이 페이지 객체가 아니라 배열 그대로 오면 nextCursor=null, hasNext=false 로 처리한다',
        () async {
      final http = TestHttpClient.respondJson(apiEnvelope([feedJson]));
      final page = await buildService(http).fetchFeed(1);

      expect(page.content, hasLength(1));
      expect(page.nextCursor, isNull);
      expect(page.hasNext, isFalse);
    });

    test('feed 항목의 필수 필드가 없어도 기본값으로 채워져 크래시는 나지 않는다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'content': [<String, dynamic>{}],
          'hasNext': false,
        }),
      );
      final page = await buildService(http).fetchFeed(1);
      expect(page.content.first.feedId, 0);
      expect(page.content.first.userName, '알 수 없음');
      expect(page.content.first.reactions, isEmpty);
    });
  });

  group('toggleFeedReaction', () {
    test('POST /{roomId}/feed/{feedId}/reactions, emoji 를 보내고 반응 목록을 돌려받는다',
        () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'reactions': [
            {'emoji': '👍', 'count': 1, 'reactedByMe': true},
          ],
        }),
      );
      final reactions = await buildService(http).toggleFeedReaction(
        roomId: 1,
        feedId: 2,
        emoji: '👍',
      );

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/feed/2/reactions',
      );
      expect(http.lastRequest.jsonBody, {'emoji': '👍'});
      expect(reactions, hasLength(1));
      expect(reactions.first.emoji, '👍');
    });

    test('응답에 reactions 키가 없으면 빈 목록이 된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<String, dynamic>{}));
      final reactions = await buildService(http)
          .toggleFeedReaction(roomId: 1, feedId: 2, emoji: '👍');
      expect(reactions, isEmpty);
    });
  });

  group('fetchChallenges / createChallenge / deleteChallenge', () {
    test('fetchChallenges: GET /{roomId}/challenges', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([challengeJson]));
      final challenges = await buildService(http).fetchChallenges(1);

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/challenges',
      );
      expect(challenges, hasLength(1));
      expect(challenges.first.title, '이번 주 20문제');
      expect(challenges.first.isInProgress, isTrue);
      expect(challenges.first.clearedCount, 0);
    });

    test('createChallenge: POST /{roomId}/challenges, endAt 은 ISO8601 로 전송된다',
        () async {
      final http = TestHttpClient.respondJson(apiEnvelope(challengeJson));
      final endAt = DateTime.utc(2026, 9, 7, 23, 59, 59);
      final challenge = await buildService(http).createChallenge(
        roomId: 1,
        title: '이번 주 20문제',
        type: 'group',
        metric: 'problem_count',
        period: 'weekly',
        periodDays: 7,
        targetValue: 20,
        endAt: endAt,
      );

      expect(http.lastRequest.method, 'POST');
      final body = http.lastRequest.jsonBody!;
      expect(body['title'], '이번 주 20문제');
      expect(body['type'], 'group');
      expect(body['metric'], 'problem_count');
      expect(body['targetValue'], 20);
      expect(body['endAt'], endAt.toIso8601String());
      expect(DateTime.tryParse(body['startAt'] as String), isNotNull);
      expect(challenge.challengeId, 5);
    });

    test(
        'createChallenge 예외 시 showErrorSnackBar:false 로 넘겨도 BadRequestException',
        () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 3010, message: '잘못된 챌린지 값'),
      );
      await expectLater(
        buildService(http).createChallenge(
          roomId: 1,
          title: 't',
          type: 'group',
          metric: 'problem_count',
          targetValue: 1,
          endAt: DateTime.now(),
        ),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('deleteChallenge: DELETE /{roomId}/challenges/{challengeId}',
        () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).deleteChallenge(roomId: 1, challengeId: 5);

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/challenges/5',
      );
    });
  });

  group('fetchSharedProblems', () {
    test('cursor 없이 호출하면 size(기본 20)만 쿼리로 붙는다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'content': [sharedProblemJson],
          'nextCursor': 9,
          'hasNext': true,
        }),
      );
      final page = await buildService(http).fetchSharedProblems(1);

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/shared-problems?size=20',
      );
      expect(page.content.first.sharedProblemId, 3);
      expect(page.content.first.problemImageUrls, ['https://cdn.test/p1.png']);
      expect(page.nextCursor, 9);
      expect(page.hasNext, isTrue);
    });

    test('cursor 를 지정하면 쿼리에 포함된다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({'content': [], 'hasNext': false}),
      );
      await buildService(http).fetchSharedProblems(1, cursor: 3, size: 5);
      expect(http.lastRequest.queryParameters, {'cursor': '3', 'size': '5'});
    });
  });

  group('shareProblems', () {
    test('comment 가 있으면 body 에 포함된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(sharedProblemJson));
      final shared = await buildService(http).shareProblems(
        roomId: 1,
        problemId: 100,
        comment: '이거 어렵네요',
      );

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/shared-problems',
      );
      expect(
        http.lastRequest.jsonBody,
        {'problemId': 100, 'comment': '이거 어렵네요'},
      );
      expect(shared.sharedProblemId, 3);
    });

    test('comment 가 null 이거나 빈 문자열이면 body 에서 아예 빠진다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(sharedProblemJson));
      await buildService(http).shareProblems(roomId: 1, problemId: 100);
      expect(http.lastRequest.jsonBody, {'problemId': 100});

      await buildService(http)
          .shareProblems(roomId: 1, problemId: 100, comment: '');
      expect(http.lastRequest.jsonBody, {'problemId': 100});
    });
  });

  group('deleteSharedProblem / toggleSharedProblemReaction', () {
    test('deleteSharedProblem: DELETE /{roomId}/shared-problems/{id}',
        () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http)
          .deleteSharedProblem(roomId: 1, sharedProblemId: 3);

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/shared-problems/3',
      );
    });

    test('toggleSharedProblemReaction: POST .../shared-problems/{id}/reactions',
        () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'reactions': [
            {'emoji': '❤️', 'count': 1, 'reactedByMe': true},
          ],
        }),
      );
      final reactions = await buildService(http).toggleSharedProblemReaction(
        roomId: 1,
        sharedProblemId: 3,
        emoji: '❤️',
      );

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/shared-problems/3/reactions',
      );
      expect(http.lastRequest.jsonBody, {'emoji': '❤️'});
      expect(reactions.first.emoji, '❤️');
    });
  });

  group('fetchSharedProblemComments', () {
    test('cursor 없이 호출하면 size(기본 20)만 쿼리로 붙는다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'content': [commentJson],
          'nextCursor': null,
          'hasNext': false,
        }),
      );
      final page = await buildService(http)
          .fetchSharedProblemComments(roomId: 1, sharedProblemId: 3);

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/shared-problems/3/comments?size=20',
      );
      expect(page.content.first.commentId, 7);
      expect(page.content.first.content, '저도 어려웠어요');
      expect(page.hasNext, isFalse);
    });
  });

  group('createSharedProblemComment / updateSharedProblemComment', () {
    test('createSharedProblemComment: content 는 trim 되어 전송된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(commentJson));
      final comment = await buildService(http).createSharedProblemComment(
        roomId: 1,
        sharedProblemId: 3,
        content: '  저도 어려웠어요  ',
      );

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/shared-problems/3/comments',
      );
      expect(http.lastRequest.jsonBody, {'content': '저도 어려웠어요'});
      expect(comment.commentId, 7);
    });

    test('updateSharedProblemComment: PATCH .../comments/{commentId}',
        () async {
      final http = TestHttpClient.respondJson(apiEnvelope(commentJson));
      await buildService(http).updateSharedProblemComment(
        roomId: 1,
        sharedProblemId: 3,
        commentId: 7,
        content: '  수정된 댓글  ',
      );

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/shared-problems/3/comments/7',
      );
      expect(http.lastRequest.jsonBody, {'content': '수정된 댓글'});
    });
  });

  group('deleteSharedProblemComment / toggleSharedProblemCommentReaction', () {
    test('deleteSharedProblemComment: DELETE .../comments/{commentId}',
        () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).deleteSharedProblemComment(
        roomId: 1,
        sharedProblemId: 3,
        commentId: 7,
      );

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/shared-problems/3/comments/7',
      );
    });

    test('toggleSharedProblemCommentReaction: POST .../comments/{id}/reactions',
        () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'reactions': [
            {'emoji': '😂', 'count': 1, 'reactedByMe': false},
          ],
        }),
      );
      final reactions =
          await buildService(http).toggleSharedProblemCommentReaction(
        roomId: 1,
        sharedProblemId: 3,
        commentId: 7,
        emoji: '😂',
      );

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/shared-problems/3/comments/7/reactions',
      );
      expect(http.lastRequest.jsonBody, {'emoji': '😂'});
      expect(reactions.first.emoji, '😂');
    });
  });

  group('fetchWeeklyReports / markWeeklyReportRead', () {
    test('fetchWeeklyReports: GET /{roomId}/weekly-reports, limit 기본값 4',
        () async {
      final http = TestHttpClient.respondJson(apiEnvelope([weeklyReportJson]));
      final reports = await buildService(http).fetchWeeklyReports(roomId: 1);

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/weekly-reports?limit=4',
      );
      expect(reports.first.reportId, 2);
      expect(reports.first.cheerMessage, '이번 주도 화이팅!');
    });

    test('fetchWeeklyReports: limit 을 지정하면 쿼리에 반영된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<dynamic>[]));
      await buildService(http).fetchWeeklyReports(roomId: 1, limit: 10);
      expect(http.lastRequest.queryParameters, {'limit': '10'});
    });

    test('markWeeklyReportRead: PATCH .../weekly-reports/{id}/read', () async {
      final http = TestHttpClient.respondJson(apiEnvelope({'isRead': true}));
      final isRead =
          await buildService(http).markWeeklyReportRead(roomId: 1, reportId: 2);

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/study-room/1/weekly-reports/2/read',
      );
      expect(isRead, isTrue);
    });

    test('markWeeklyReportRead: isRead 가 응답에 없으면 false 로 처리된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<String, dynamic>{}));
      final isRead =
          await buildService(http).markWeeklyReportRead(roomId: 1, reportId: 2);
      expect(isRead, isFalse);
    });
  });
}
