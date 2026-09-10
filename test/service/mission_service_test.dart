// MissionService 가 백엔드와 주고받는 계약을 검증한다.
//
// 미션 API 는 아직 서버에 없다. 404 든 네트워크 오류든 예외가 새어 나오지
// 않고 null 로 떨어지는지가 핵심이다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Constants/ErrorMessages.dart';
import 'package:ono/Model/Mission/MissionClaimResultModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/Mission/MissionService.dart';

import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  MissionService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return MissionService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  Map<String, dynamic> boardPayload() => {
        'daily': {
          'periodKey': '2026-09-09',
          'missions': [
            {
              'progressId': 1024,
              'code': 'DAILY_NOTE_WRITE',
              'title': '오늘의 오답',
              'description': '오답노트 1개 등록',
              'iconKey': 'note_write',
              'category': 'DAILY',
              'current': 1,
              'target': 1,
              'completed': true,
              'claimed': false,
              'rewardType': 'XP',
              'rewardValue': 10,
            },
          ],
        },
        'weekly': {'periodKey': '2026-W37', 'missions': []},
      };

  group('getMissions', () {
    test('GET /api/missions 로 미션판을 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(boardPayload()));

      final board = await buildService(http).getMissions();

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/missions');
      expect(http.lastRequest.authorization, 'test-access-token');
      expect(board, isNotNull);
      expect(board!.daily.periodKey, '2026-09-09');
      expect(board.daily.missions.single.code, 'DAILY_NOTE_WRITE');
      expect(board.weekly.missions, isEmpty);
    });

    test('expired 그룹이 오면 함께 읽는다', () async {
      final payload = boardPayload()
        ..['expired'] = {
          'periodKey': null,
          'missions': [
            {
              'progressId': 777,
              'code': 'WEEKLY_REVIEW_30',
              'title': '서른 번의 복습',
              'description': '복습 30회',
              'iconKey': 'review',
              'category': 'WEEKLY',
              'periodKey': '2026-W36',
              'current': 30,
              'target': 30,
              'completed': true,
              'claimed': false,
              'rewardType': 'XP',
              'rewardValue': 100,
            },
          ],
        };
      final http = TestHttpClient.respondJson(apiEnvelope(payload));

      final board = await buildService(http).getMissions();

      expect(board!.expired.missions, hasLength(1));
      expect(board.expired.missions.single.periodKey, '2026-W36');
      expect(board.expired.missions.single.isClaimable, isTrue);
    });

    test('expired 가 없는 예전 응답도 그대로 읽는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(boardPayload()));

      final board = await buildService(http).getMissions();

      expect(board, isNotNull);
      expect(board!.expired.missions, isEmpty);
      expect(board.daily.missions, hasLength(1));
    });

    test('API 가 아직 배포 전이라 404 가 와도 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, message: 'Not Found'),
      );

      expect(await buildService(http).getMissions(), isNull);
    });

    test('서버가 500 을 줘도 예외를 던지지 않는다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      expect(await buildService(http).getMissions(), isNull);
    });

    test('네트워크가 끊겨도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(const SocketException('offline'));

      expect(await buildService(http).getMissions(), isNull);
    });

    test('토큰이 없으면 호출하지 않고 null 을 돌려준다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(boardPayload()));

      final board = await buildService(http, accessToken: null).getMissions();

      expect(board, isNull);
      expect(http.callCount, 0);
    });
  });

  group('getHistory', () {
    Map<String, dynamic> historyPayload({
      bool withTotals = true,
      int? nextCursor = 998,
      bool hasNext = true,
    }) =>
        {
          'content': [
            {
              'progressId': 1024,
              'code': 'WEEKLY_NOTE_10',
              'title': '열 권의 노트',
              'iconKey': 'writing_wink',
              'category': 'WEEKLY',
              'periodKey': '2026-W37',
              'rewardType': 'XP',
              'rewardValue': 80,
              'claimedAt': '2026-09-10T14:33:47',
            },
          ],
          'nextCursor': nextCursor,
          'hasNext': hasNext,
          'size': 20,
          if (withTotals) 'totalClaimedXp': 1250,
          if (withTotals) 'totalClaimedCount': 37,
        };

    test('GET /api/missions/history 로 첫 페이지를 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(historyPayload()));

      final page = await buildService(http).getHistory();

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.path, '/api/missions/history');
      expect(http.lastRequest.queryParameters['size'], '20');
      // 첫 페이지에는 커서를 보내지 않는다.
      expect(http.lastRequest.queryParameters.containsKey('cursor'), isFalse);
      expect(page, isNotNull);
      expect(page!.content.single.title, '열 권의 노트');
      expect(page.totalClaimedXp, 1250);
      expect(page.totalClaimedCount, 37);
    });

    test('커서를 주면 다음 페이지를 부른다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope(historyPayload(
            withTotals: false, nextCursor: null, hasNext: false)),
      );

      final page = await buildService(http).getHistory(cursor: 998);

      expect(http.lastRequest.queryParameters['cursor'], '998');
      expect(page!.totalClaimedXp, isNull);
      expect(page.isLastPage, isTrue);
    });

    test('API 가 아직 배포 전이라 404 가 와도 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, message: 'Not Found'),
      );

      expect(await buildService(http).getHistory(), isNull);
    });

    test('네트워크가 끊겨도 예외를 던지지 않는다', () async {
      final http = TestHttpClient.throwing(const SocketException('offline'));

      expect(await buildService(http).getHistory(), isNull);
    });
  });

  group('claim', () {
    test('POST /api/missions/{progressId}/claim 으로 보상을 받는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope({
        'progressId': 1024,
        'rewardType': 'XP',
        'rewardValue': 10,
        'totalStudyLevel': 7,
        'leveledUp': true,
      }));

      final result = await buildService(http).claim(1024);

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/missions/1024/claim',
      );
      expect(result, isNotNull);
      expect(result!.rewardType, MissionRewardType.xp);
      expect(result.rewardValue, 10);
      expect(result.totalStudyLevel, 7);
      expect(result.leveledUp, isTrue);
    });

    test('이미 받은 미션(7012)은 거절로 표시하고 문구를 알려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(
          statusCode: 400,
          errorCode: 7012,
          message: '이미 보상을 받은 미션입니다.',
        ),
      );

      MissionClaimFailure? failure;
      final result = await buildService(http).claim(
        1024,
        onFailure: (f) => failure = f,
      );

      expect(result, isNull);
      expect(failure, isNotNull);
      expect(failure!.kind, MissionClaimFailureKind.rejected);
      expect(failure!.errorCode, 7012);
      // 화면이 이걸 보고 오류를 띄우지 않고 조용히 다시 조회한다.
      expect(failure!.isAlreadyClaimed, isTrue);
    });

    test('아직 완료하지 않은 미션(7011)도 예외를 던지지 않는다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 7011),
      );

      MissionClaimFailure? failure;
      final result = await buildService(http).claim(
        1024,
        onFailure: (f) => failure = f,
      );

      expect(result, isNull);
      expect(failure!.kind, MissionClaimFailureKind.rejected);
      expect(failure!.message, ErrorMessages.missionNotCompleted);
      expect(failure!.isAlreadyClaimed, isFalse);
    });

    test('진행도를 찾을 수 없으면(7010) 거절이다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, errorCode: 7010),
      );

      MissionClaimFailure? failure;
      final result = await buildService(http).claim(
        99,
        onFailure: (f) => failure = f,
      );

      expect(result, isNull);
      expect(failure!.kind, MissionClaimFailureKind.rejected);
      expect(failure!.message, ErrorMessages.missionProgressNotFound);
    });

    test('서버가 500 이면 결과를 모르는 것으로 둔다', () async {
      // 서버가 XP 를 주고 나서 터졌을 수도 있다. 실패로 단정하면 안 된다.
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      MissionClaimFailure? failure;
      await buildService(http).claim(1024, onFailure: (f) => failure = f);

      expect(failure!.kind, MissionClaimFailureKind.unknown);
      expect(failure!.isUnknown, isTrue);
    });

    test('응답을 받는 중 연결이 끊기면 결과를 모르는 것으로 둔다', () async {
      final http = TestHttpClient.throwing(const SocketException('offline'));

      MissionClaimFailure? failure;
      await buildService(http).claim(1024, onFailure: (f) => failure = f);

      expect(failure!.kind, MissionClaimFailureKind.unknown);
    });

    test('2xx 인데 본문을 읽지 못하면 결과를 모르는 것으로 둔다', () async {
      // 서버는 이미 보상을 줬다. 여기서 실패라고 알리면 사용자가 두 번 누른다.
      final http =
          TestHttpClient.respondJson(apiEnvelope({'unexpected': true}));

      MissionClaimFailure? failure;
      final result = await buildService(http).claim(
        1024,
        onFailure: (f) => failure = f,
      );

      expect(result, isNull);
      expect(failure!.kind, MissionClaimFailureKind.unknown);
    });

    test('네트워크가 끊겨도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(const SocketException('offline'));

      expect(await buildService(http).claim(1024), isNull);
    });
  });
}
