// TokenProvider.refreshAccessToken() / _refreshAccessTokenInternal() 검증.
//
// 커밋 c2a6cdd 이전에는 이 경로가 최상위 `http.post` 를 직접 호출해서 Client 를
// 갈아끼울 수 없었다. 지금은 `TokenProvider(client: ...)` 로 주입할 수 있어서
// 실제 HTTP 없이 갱신 흐름을 검증할 수 있다.
//
// 기존 test/provider/token_provider_test.dart 는 이 파일이 다루는 네트워크 경로를
// 의도적으로 비워 뒀으니(주석 참고) 여기와 겹치지 않는다.
import 'dart:async' as async_lib;
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Provider/TokenProvider.dart';

import '../helpers/helpers.dart';

/// exp 클레임만 있는 최소 JWT. 서명 검증은 하지 않는 코드라 서명은 아무 문자열이나 둔다.
String _fakeJwt({required int expiresInSeconds}) {
  String encodePart(Map<String, dynamic> part) {
    return base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');
  }

  final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresInSeconds;
  final header = encodePart({'alg': 'none', 'typ': 'JWT'});
  final payload = encodePart({'exp': exp});
  return '$header.$payload.signature';
}

void main() {
  setUpOnoTest();

  setUp(() {
    // 이전 테스트가 등록한 핸들러가 새어들지 않도록 매 테스트 전에 no-op 로 되돌린다.
    TokenProvider.registerAuthFailureHandler(() async {});
  });

  group('refreshAccessToken — 요청 형태', () {
    test('POST {baseUrl}/api/auth/refresh 로 refreshToken 을 바디에 실어 보낸다',
        () async {
      stubSecureStorage(initialData: {'refreshToken': 'refresh-abc'});
      final http = TestHttpClient.respondJson(
        apiEnvelope(
            {'accessToken': 'new-access', 'refreshToken': 'new-refresh'}),
      );
      final tokenProvider = TokenProvider(client: http.client);

      await tokenProvider.refreshAccessToken();

      expect(http.lastRequest.method, 'POST');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/auth/refresh');
      expect(http.lastRequest.jsonBody, {'refreshToken': 'refresh-abc'});
      expect(http.lastRequest.contentType, contains('application/json'));
    });

    test('성공하면 새 access/refresh 토큰을 저장소에 저장한다', () async {
      final storageData =
          stubSecureStorage(initialData: {'refreshToken': 'r1'});
      final http = TestHttpClient.respondJson(
        apiEnvelope(
            {'accessToken': 'new-access', 'refreshToken': 'new-refresh'}),
      );
      final tokenProvider = TokenProvider(client: http.client);

      await tokenProvider.refreshAccessToken();

      expect(storageData['accessToken'], 'new-access');
      expect(storageData['refreshToken'], 'new-refresh');
    });
  });

  group('refreshAccessToken — refreshToken 이 없는 경우', () {
    test('refreshToken 이 없으면 요청 없이 UnauthorizedException', () async {
      stubSecureStorage();
      final http = TestHttpClient.respondJson(apiEnvelope(null));
      final tokenProvider = TokenProvider(client: http.client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });

    test('refreshToken 이 없으면 인증 실패 핸들러가 불린다', () async {
      stubSecureStorage();
      var notified = false;
      TokenProvider.registerAuthFailureHandler(() async {
        notified = true;
      });
      final tokenProvider =
          TokenProvider(client: TestHttpClient.respondJson(null).client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(notified, isTrue);
    });
  });

  group('refreshAccessToken — 서버가 인증 실패로 응답', () {
    test('401 이면 토큰을 지우고 인증 실패 핸들러를 부른 뒤 UnauthorizedException', () async {
      final storageData = stubSecureStorage(
          initialData: {'refreshToken': 'r1', 'accessToken': 'a1'});
      var notified = false;
      TokenProvider.registerAuthFailureHandler(() async {
        notified = true;
      });
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 401, message: '인증이 만료되었습니다'),
      );
      final tokenProvider = TokenProvider(client: http.client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(storageData.containsKey('accessToken'), isFalse);
      expect(storageData.containsKey('refreshToken'), isFalse);
      expect(notified, isTrue);
    });

    test('리프레시 토큰 관련 errorCode(1002) 는 상태 코드가 404 여도 인증 실패로 처리한다', () async {
      // 서버는 "리프레시 토큰 정보를 찾을 수 없음"을 404 + errorCode 1002 로 내려준다.
      // 상태 코드만 보면 놓치기 때문에 errorCode 를 우선 확인해야 한다 (구현 주석 참고).
      stubSecureStorage(initialData: {'refreshToken': 'stale'});
      final http = TestHttpClient.respondWith(
        errorResponse(
            statusCode: 404, errorCode: 1002, message: '리프레시 토큰 정보를 찾을 수 없습니다'),
      );
      final tokenProvider = TokenProvider(client: http.client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('errorCode 가 없어도 400 + "리프레시 토큰" 메시지면 인증 실패로 처리한다', () async {
      stubSecureStorage(initialData: {'refreshToken': 'stale'});
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, message: '리프레시 토큰이 유효하지 않습니다'),
      );
      final tokenProvider = TokenProvider(client: http.client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('리프레시 토큰과 무관한 400 오류는 ApiException 으로 처리하고 토큰을 지우지 않는다', () async {
      final storageData =
          stubSecureStorage(initialData: {'refreshToken': 'r1'});
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, message: '잘못된 요청입니다'),
      );
      final tokenProvider = TokenProvider(client: http.client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<ApiException>()),
      );
      // 리프레시 토큰 무효 패턴이 아니므로 저장소는 그대로 남아 있어야 한다.
      expect(storageData['refreshToken'], 'r1');
    });
  });

  group('refreshAccessToken — 네트워크 계열 예외 매핑 (Sentry FLUTTER-100/110/15S/102)',
      () {
    test('SocketException 은 NetworkException 으로 바뀐다', () async {
      stubSecureStorage(initialData: {'refreshToken': 'r1'});
      final http = TestHttpClient.throwing(const SocketException('연결 실패'));
      final tokenProvider = TokenProvider(client: http.client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('http.ClientException 은 NetworkException 으로 바뀐다', () async {
      stubSecureStorage(initialData: {'refreshToken': 'r1'});
      final http =
          TestHttpClient.throwing(ClientException('Connection closed'));
      final tokenProvider = TokenProvider(client: http.client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('타임아웃은 TimeoutException 으로 바뀐다', () async {
      stubSecureStorage(initialData: {'refreshToken': 'r1'});
      final http =
          TestHttpClient.throwing(async_lib.TimeoutException('timeout'));
      final tokenProvider = TokenProvider(client: http.client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('refreshAccessToken — 동시 호출 가드 (_refreshInFlight)', () {
    test('동시에 두 번 부르면 요청은 한 번만 나간다', () async {
      stubSecureStorage(initialData: {'refreshToken': 'r1'});
      final http = TestHttpClient.handler((req) async {
        // 두 호출이 겹치도록 살짝 지연시킨 뒤 응답한다.
        await Future.delayed(const Duration(milliseconds: 30));
        return jsonResponse(
          apiEnvelope(
              {'accessToken': 'new-access', 'refreshToken': 'new-refresh'}),
        );
      });
      final tokenProvider = TokenProvider(client: http.client);

      final first = tokenProvider.refreshAccessToken();
      final second = tokenProvider.refreshAccessToken();
      await Future.wait([first, second]);

      expect(http.callCount, 1);
    });

    test('가드가 풀린 뒤에는 다시 호출하면 새 요청이 나간다', () async {
      stubSecureStorage(initialData: {'refreshToken': 'r1'});
      final http = TestHttpClient.respondJson(
        apiEnvelope(
            {'accessToken': 'new-access', 'refreshToken': 'new-refresh'}),
      );
      final tokenProvider = TokenProvider(client: http.client);

      await tokenProvider.refreshAccessToken();
      await tokenProvider.refreshAccessToken();

      expect(http.callCount, 2);
    });
  });

  group('refreshAccessToken — 응답 형식 오류', () {
    test('data 가 없으면 ParseException', () async {
      stubSecureStorage(initialData: {'refreshToken': 'r1'});
      final http = TestHttpClient.respondJson(apiEnvelope(null));
      final tokenProvider = TokenProvider(client: http.client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<ParseException>()),
      );
    });

    test('accessToken 이나 refreshToken 이 응답에 없으면 ParseException', () async {
      stubSecureStorage(initialData: {'refreshToken': 'r1'});
      final http = TestHttpClient.respondJson(
          apiEnvelope({'accessToken': 'only-access'}));
      final tokenProvider = TokenProvider(client: http.client);

      await expectLater(
        tokenProvider.refreshAccessToken(),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('getAccessToken — 만료 임박 시 갱신 경로', () {
    test('만료가 임박한 액세스 토큰은 갱신 후 새 토큰을 반환한다', () async {
      final storageData = stubSecureStorage(initialData: {
        'accessToken': _fakeJwt(expiresInSeconds: 60), // 3분 임계값보다 짧게 남음
        'refreshToken': 'r1',
      });
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'accessToken': 'refreshed-access',
          'refreshToken': 'refreshed-refresh'
        }),
      );
      final tokenProvider = TokenProvider(client: http.client);

      final result = await tokenProvider.getAccessToken();

      expect(result, 'refreshed-access');
      expect(storageData['accessToken'], 'refreshed-access');
      expect(http.callCount, 1);
    });

    test('선갱신이 네트워크 오류로 실패해도 UnauthorizedException 이 아니면 기존 토큰으로 진행한다',
        () async {
      final existingToken = _fakeJwt(expiresInSeconds: 60);
      stubSecureStorage(initialData: {
        'accessToken': existingToken,
        'refreshToken': 'r1',
      });
      final http = TestHttpClient.throwing(const SocketException('연결 실패'));
      final tokenProvider = TokenProvider(client: http.client);

      final result = await tokenProvider.getAccessToken();

      expect(result, existingToken);
    });
  });
}
