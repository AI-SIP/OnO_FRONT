// HttpService 가 오류 응답을 어떤 예외로 옮기는지 잠근다.
//
// 서버의 범용 오류 핸들러는 errorCode 자리에 HTTP 상태값을 그대로 넣는다.
// dev 실측으로 405 → errorCode:405, 잘못된 파라미터 → errorCode:500 이
// 확인됐다. 예전에는 errorCode 가 있으면 인증 구간(1000~1999)만 갈라내고
// 나머지를 전부 BadRequestException 으로 만들어서, 서버가 깨진 것을 "잘못된
// 요청" 으로 안내했다 (#259).
//
// 인증 구간과 토큰 갱신 재시도는 그대로다. 그쪽은
// http_service_auth_refresh_test.dart 가 따로 잠그고, 여기서도 갈라지는
// 경계가 움직이지 않았는지만 확인한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Provider/TokenProvider.dart';
import 'package:ono/Service/Api/HttpService.dart';

import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  Future<Object> errorOf({
    required int statusCode,
    int? errorCode,
    String? message,
    bool requiredToken = true,
    TokenProvider? tokenProvider,
  }) async {
    final client = TestHttpClient.respondWith(
      errorResponse(
        statusCode: statusCode,
        errorCode: errorCode,
        message: message,
      ),
    );

    try {
      await HttpService(
        client: client.client,
        tokenProvider: tokenProvider ?? buildMockTokenProvider(),
      ).sendRequest(
        method: 'GET',
        url: '$testBaseUrl/api/problems',
        requiredToken: requiredToken,
        showErrorSnackBar: false,
      );
    } catch (error) {
      return error;
    }
    fail('예외가 나지 않았다');
  }

  group('errorCode 자리에 HTTP 상태값이 온 경우', () {
    test('500 이면 서버 오류다', () async {
      final error = await errorOf(
        statusCode: 500,
        errorCode: 500,
        message: '서버에서 오류가 발생했습니다.',
      );

      expect(error, isA<ServerException>());
      expect((error as ServerException).statusCode, 500);
    });

    test('응답 상태가 400 이어도 본문의 500 을 믿는다', () async {
      // 서버가 모든 오류를 400 으로 통일해 내리던 경로다. 진짜 원인은 본문에 있다.
      final error = await errorOf(statusCode: 400, errorCode: 500);

      expect(error, isA<ServerException>());
      expect((error as ServerException).statusCode, 500);
    });

    test('502·503 도 서버 오류다', () async {
      expect(await errorOf(statusCode: 502, errorCode: 502),
          isA<ServerException>());
      expect(await errorOf(statusCode: 503, errorCode: 503),
          isA<ServerException>());
    });

    test('405 는 그대로 잘못된 요청이다', () async {
      final error = await errorOf(
        statusCode: 405,
        errorCode: 405,
        message: 'Method Not Allowed',
      );

      expect(error, isA<BadRequestException>());
      expect((error as BadRequestException).errorCode, 405);
    });

    test('404 도 그대로 잘못된 요청이다', () async {
      expect(
        await errorOf(statusCode: 404, errorCode: 404),
        isA<BadRequestException>(),
      );
    });
  });

  group('업무 에러 코드', () {
    test('네 자리 업무 코드는 500 이상이어도 잘못된 요청이다', () async {
      // 7011(아직 완료하지 않은 미션)처럼 앱이 문구를 갈라 쓰는 코드들이다.
      // 상태 코드로 읽어서는 안 된다.
      final error = await errorOf(
        statusCode: 400,
        errorCode: 7011,
        message: '아직 완료하지 않은 미션이에요.',
      );

      expect(error, isA<BadRequestException>());
      expect((error as BadRequestException).errorCode, 7011);
    });

    test('2000번대 업무 코드도 그대로 잘못된 요청이다', () async {
      final error = await errorOf(statusCode: 400, errorCode: 2001);

      expect(error, isA<BadRequestException>());
      expect((error as BadRequestException).errorCode, 2001);
    });
  });

  group('인증 구간(1000~1999)은 그대로다', () {
    test('1008 은 여전히 인증 오류이고 로그아웃 판정으로 간다', () async {
      final tokenProvider = buildMockTokenProvider();

      final error = await errorOf(
        statusCode: 403,
        errorCode: 1008,
        message: '권한이 없습니다.',
        tokenProvider: tokenProvider,
      );

      expect(error, isA<UnauthorizedException>());
      expect((error as UnauthorizedException).errorCode, 1008);
      verify(() => tokenProvider.notifyAuthFailure()).called(1);
      verifyNever(() => tokenProvider.refreshAccessToken());
    });

    test('상태가 500 이어도 인증 코드면 인증 오류로 간다', () async {
      // 인증 구간을 먼저 가른다. 5xx 판정이 그 앞으로 끼어들면 안 된다.
      final tokenProvider = buildMockTokenProvider();

      final error = await errorOf(
        statusCode: 500,
        errorCode: 1008,
        tokenProvider: tokenProvider,
      );

      expect(error, isA<UnauthorizedException>());
      verify(() => tokenProvider.notifyAuthFailure()).called(1);
    });

    test('1005 는 여전히 토큰을 갱신하고 한 번 재시도한다', () async {
      final client = TestHttpClient.sequence([
        errorResponse(statusCode: 401, errorCode: 1005, message: '인증 실패'),
        jsonResponse(apiEnvelope({'ok': true})),
      ]);
      final tokenProvider = buildMockTokenProvider();

      final result = await HttpService(
        client: client.client,
        tokenProvider: tokenProvider,
      ).sendRequest(
        method: 'GET',
        url: '$testBaseUrl/api/problems',
        showErrorSnackBar: false,
      );

      expect(result, {'ok': true});
      expect(client.callCount, 2);
      verify(() => tokenProvider.refreshAccessToken()).called(1);
    });

    test('갱신 뒤 재시도에서도 인증 오류면 토큰을 지우지 않는다', () async {
      final tokenProvider = buildMockTokenProvider();

      final error = await errorOf(
        statusCode: 401,
        errorCode: 1007,
        tokenProvider: tokenProvider,
      );

      // 서버가 일시적으로 인증을 못 하는 상황으로 본다 (#251).
      expect(error, isA<ServerException>());
      verify(() => tokenProvider.refreshAccessToken()).called(1);
      verifyNever(() => tokenProvider.notifyAuthFailure());
    });
  });

  group('errorCode 가 없는 응답', () {
    test('5xx 는 예전처럼 서버 오류다', () async {
      expect(await errorOf(statusCode: 500), isA<ServerException>());
    });

    test('4xx 는 예전처럼 잘못된 요청이다', () async {
      expect(await errorOf(statusCode: 400), isA<BadRequestException>());
    });

    test('401 은 예전처럼 인증 오류 경로로 간다', () async {
      final tokenProvider = buildMockTokenProvider();

      final error = await errorOf(
        statusCode: 401,
        tokenProvider: tokenProvider,
      );

      expect(error, isA<ServerException>());
      verify(() => tokenProvider.refreshAccessToken()).called(1);
    });
  });
}
