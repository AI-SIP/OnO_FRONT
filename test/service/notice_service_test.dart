import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Notice/NoticeModel.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/Notice/NoticeService.dart';

import '../helpers/helpers.dart';

/// NoticeService 가 백엔드와 주고받는 계약을 검증한다.
///
/// 공지는 없어도 앱이 돌아가야 하는 기능이라, 실패 경로에서 예외를 던지지
/// 않고 null / false 로 떨어지는지가 핵심이다.
void main() {
  setUpOnoTest();

  NoticeService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return NoticeService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  group('getActiveNotice', () {
    test('GET /api/notices/active 로 활성 공지를 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope({
        'noticeId': 12,
        'title': '점검 안내',
        'content': '오늘 밤 2시부터 30분간 점검이 있습니다.',
        'type': 'WARNING',
        'expiresAt': '2026-09-08T23:10:00',
      }));

      final notice = await buildService(http).getActiveNotice();

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/notices/active',
      );
      expect(http.lastRequest.authorization, 'test-access-token');
      expect(notice, isNotNull);
      expect(notice!.noticeId, 12);
      expect(notice.title, '점검 안내');
      expect(notice.type, NoticeType.warning);
      expect(notice.expiresAt, DateTime(2026, 9, 8, 23, 10));
    });

    test('공지가 없으면 data 키 없이 {} 가 오고 null 을 돌려준다', () async {
      // 서버 공통 응답이 null 필드를 빼고 내려서 data 키 자체가 없다.
      final http = TestHttpClient.respondJson(<String, dynamic>{});

      final notice = await buildService(http).getActiveNotice();

      expect(notice, isNull);
    });

    test('서버가 500 을 줘도 예외를 던지지 않고 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      final notice = await buildService(http).getActiveNotice();

      expect(notice, isNull);
    });

    test('API 가 아직 배포 전이라 404 가 와도 null 을 돌려준다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, message: 'Not Found'),
      );

      expect(await buildService(http).getActiveNotice(), isNull);
    });

    test('네트워크가 끊겨도 null 을 돌려준다', () async {
      final http = TestHttpClient.throwing(const SocketException('offline'));

      expect(await buildService(http).getActiveNotice(), isNull);
    });

    test('토큰이 없으면 호출하지 않고 null 을 돌려준다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(null));

      final notice =
          await buildService(http, accessToken: null).getActiveNotice();

      expect(notice, isNull);
      expect(http.callCount, 0);
    });
  });

  group('dismissNotice', () {
    test('POST /api/notices/{noticeId}/dismiss 로 그만 보기를 알린다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope('공지를 24시간 동안 숨겼습니다.'),
      );

      final ok = await buildService(http).dismissNotice(12);

      expect(ok, isTrue);
      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/notices/12/dismiss',
      );
    });

    test('없는 공지(404, errorCode 14001)면 false 를 돌려주고 던지지 않는다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(
          statusCode: 404,
          errorCode: 14001,
          message: '공지를 찾을 수 없습니다.',
        ),
      );

      expect(await buildService(http).dismissNotice(99), isFalse);
    });
  });
}
