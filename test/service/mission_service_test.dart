// MissionService 가 백엔드와 주고받는 계약을 검증한다.
//
// 미션 API 는 아직 서버에 없다. 404 든 네트워크 오류든 예외가 새어 나오지
// 않고 null 로 떨어지는지가 핵심이다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Constants/ErrorMessages.dart';
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

    test('이미 받은 미션(7012)이면 null 과 함께 문구를 알려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(
          statusCode: 400,
          errorCode: 7012,
          message: '이미 보상을 받은 미션입니다.',
        ),
      );

      String? failure;
      final result = await buildService(http).claim(
        1024,
        onFailure: (message) => failure = message,
      );

      expect(result, isNull);
      expect(failure, isNotNull);
    });

    test('아직 완료하지 않은 미션(7011)도 예외를 던지지 않는다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 7011),
      );

      String? failure;
      final result = await buildService(http).claim(
        1024,
        onFailure: (message) => failure = message,
      );

      expect(result, isNull);
      expect(failure, ErrorMessages.missionNotCompleted);
    });

    test('진행도를 찾을 수 없으면(7010) null 이다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, errorCode: 7010),
      );

      String? failure;
      final result = await buildService(http).claim(
        99,
        onFailure: (message) => failure = message,
      );

      expect(result, isNull);
      expect(failure, ErrorMessages.missionProgressNotFound);
    });

    test('네트워크가 끊겨도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(const SocketException('offline'));

      expect(await buildService(http).claim(1024), isNull);
    });
  });
}
