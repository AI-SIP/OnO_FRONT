// HttpService 가 인증 오류(1xxx)를 받았을 때 토큰을 갱신할지, 바로 로그아웃시킬지를 잠근다.
//
// 운영 서버는 만료된 액세스 토큰에도 1005 가 아니라 1007 을 준다. 예전에는 1005 만
// 갱신 대상이라 1007 을 받은 사용자가 갱신 한 번 없이 로그아웃됐고, 게스트는 같은
// 계정으로 돌아올 방법이 없었다 (#236).
//
// 갱신은 한 번만 한다.
//
// 재시도에서도 인증 오류가 나와도 토큰은 지우지 않는다. 백엔드 JwtTokenFilter 가
// 토큰 검증 중의 모든 예외를 1007 로 내리기 때문에, Redis 블랙리스트 조회가 실패하는
// 동안에는 멀쩡한 토큰을 가진 요청도 계속 1007 을 받는다. 그때 방금 갱신받은 유효한
// 토큰을 지우면 게스트는 계정으로 돌아올 방법이 없다. 토큰을 지우는 것은 리프레시
// 토큰 자체가 거절됐을 때뿐이다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Provider/TokenProvider.dart';
import 'package:ono/Service/Api/HttpService.dart';

import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('갱신 후 재시도하는 인증 오류', () {
    for (final code in [1005, 1007, 1009]) {
      test('$code 이면 토큰을 한 번 갱신하고 재시도해 성공한다', () async {
        final client = TestHttpClient.sequence([
          errorResponse(statusCode: 401, errorCode: code, message: '인증 실패'),
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
        verifyNever(() => tokenProvider.notifyAuthFailure());
      });

      test('$code 이 재시도에서도 나오면 로그아웃시키지 않고 잠시 후 다시 시도하게 한다', () async {
        final client = TestHttpClient.respondWith(
          errorResponse(statusCode: 401, errorCode: code, message: '인증 실패'),
        );
        final tokenProvider = buildMockTokenProvider();

        await expectLater(
          HttpService(client: client.client, tokenProvider: tokenProvider)
              .sendRequest(
            method: 'GET',
            url: '$testBaseUrl/api/problems',
            showErrorSnackBar: false,
          ),
          // 갱신은 됐는데 서버가 계속 인증을 못 하고 있는 상황이라 서버 쪽 문제로 본다.
          throwsA(isA<ServerException>()),
        );

        // 재시도는 한 번뿐이라 갱신이 되풀이되지 않는다.
        expect(client.callCount, 2);
        verify(() => tokenProvider.refreshAccessToken()).called(1);
        verifyNever(() => tokenProvider.notifyAuthFailure());
      });
    }

    test('errorCode 없는 401 이 재시도에서도 나와도 로그아웃시키지 않는다', () async {
      final client = TestHttpClient.respondWith(
        errorResponse(statusCode: 401, message: '인증 실패'),
      );
      final tokenProvider = buildMockTokenProvider();

      await expectLater(
        HttpService(client: client.client, tokenProvider: tokenProvider)
            .sendRequest(
          method: 'GET',
          url: '$testBaseUrl/api/problems',
          showErrorSnackBar: false,
        ),
        throwsA(isA<ServerException>()),
      );

      expect(client.callCount, 2);
      verifyNever(() => tokenProvider.notifyAuthFailure());
    });

    test('재시도에서 리프레시 토큰 거절 코드가 오면 그때는 로그아웃시킨다', () async {
      final client = TestHttpClient.sequence([
        errorResponse(statusCode: 401, errorCode: 1007, message: '인증 실패'),
        errorResponse(
            statusCode: 401, errorCode: 1006, message: '리프레시 토큰이 만료되었습니다.'),
      ]);
      final tokenProvider = buildMockTokenProvider();

      await expectLater(
        HttpService(client: client.client, tokenProvider: tokenProvider)
            .sendRequest(
          method: 'GET',
          url: '$testBaseUrl/api/problems',
          showErrorSnackBar: false,
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      verify(() => tokenProvider.notifyAuthFailure()).called(1);
    });
  });

  group('multipart 요청의 갱신 재시도', () {
    // http 의 MultipartFile 은 한 번 전송하면 finalize 되어 두 번 쓸 수 없다.
    // 재시도에 같은 인스턴스를 다시 실으면 StateError 가 나 사용자에게
    // "알 수 없는 오류" 만 보였다. 그래서 파일이 아니라 만드는 방법을 받는다.
    test('1007 을 받으면 파일을 다시 만들어 재시도하고 성공한다', () async {
      final client = TestHttpClient.sequence([
        errorResponse(statusCode: 401, errorCode: 1007, message: '인증이 실패했습니다.'),
        jsonResponse(apiEnvelope({'ok': true})),
      ]);
      final tokenProvider = buildMockTokenProvider();
      var buildCount = 0;

      final result = await HttpService(
        client: client.client,
        tokenProvider: tokenProvider,
      ).sendRequest(
        method: 'POST',
        url: '$testBaseUrl/api/problems/1/imageData',
        isMultipart: true,
        filesBuilder: () async {
          buildCount++;
          return [
            http.MultipartFile.fromString(
              'problemImages',
              'image-bytes',
              filename: 'problem.png',
            ),
          ];
        },
        body: {
          'problemImageTypes': ['PROBLEM_IMAGE'],
        },
        showErrorSnackBar: false,
      );

      expect(result, {'ok': true});
      expect(client.callCount, 2);
      expect(buildCount, 2, reason: '재시도는 파일을 새로 만들어야 한다');
      // 재시도에도 같은 이미지와 같은 필드가 그대로 실린다.
      expect(client.lastRequest.body, contains('image-bytes'));
      expect(client.lastRequest.body, contains('PROBLEM_IMAGE'));
      verify(() => tokenProvider.refreshAccessToken()).called(1);
    });

    test('PATCH multipart 도 파일을 다시 만들어 재시도한다', () async {
      final client = TestHttpClient.sequence([
        errorResponse(
            statusCode: 401, errorCode: 1005, message: '엑세스 토큰이 만료되었습니다.'),
        jsonResponse(apiEnvelope({'thumbnailUrl': 'https://cdn/t.png'})),
      ]);
      final tokenProvider = buildMockTokenProvider();
      var buildCount = 0;

      final result = await HttpService(
        client: client.client,
        tokenProvider: tokenProvider,
      ).sendRequest(
        method: 'PATCH',
        url: '$testBaseUrl/api/study-room/1/thumbnail',
        isMultipart: true,
        filesBuilder: () async {
          buildCount++;
          return [
            http.MultipartFile.fromString('thumbnail', 'thumb-bytes',
                filename: 't.png'),
          ];
        },
        showErrorSnackBar: false,
      );

      expect(result, {'thumbnailUrl': 'https://cdn/t.png'});
      expect(buildCount, 2);
      expect(client.lastRequest.body, contains('thumb-bytes'));
    });

    test('재시도까지 인증 오류면 알 수 없는 오류가 아니라 잠시 후 다시 시도로 끝난다', () async {
      final client = TestHttpClient.respondWith(
        errorResponse(statusCode: 401, errorCode: 1007, message: '인증이 실패했습니다.'),
      );
      final tokenProvider = buildMockTokenProvider();

      await expectLater(
        HttpService(client: client.client, tokenProvider: tokenProvider)
            .sendRequest(
          method: 'POST',
          url: '$testBaseUrl/api/problems/1/imageData',
          isMultipart: true,
          filesBuilder: () async => [
            http.MultipartFile.fromString('problemImages', 'image-bytes',
                filename: 'problem.png'),
          ],
          showErrorSnackBar: false,
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.getUserMessage(),
            '사용자에게 보이는 메시지',
            '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          ),
        ),
      );

      expect(client.callCount, 2);
      verifyNever(() => tokenProvider.notifyAuthFailure());
    });
  });

  group('갱신하지 않는 인증 오류', () {
    // 리프레시 토큰 계열과 권한 부족은 액세스 토큰을 새로 받아도 달라지지 않는다.
    for (final code in [1001, 1002, 1004, 1006, 1008]) {
      test('$code 이면 갱신 없이 바로 인증 실패로 처리한다', () async {
        final client = TestHttpClient.respondWith(
          errorResponse(statusCode: 401, errorCode: code, message: '인증 실패'),
        );
        final tokenProvider = buildMockTokenProvider();

        await expectLater(
          HttpService(client: client.client, tokenProvider: tokenProvider)
              .sendRequest(
            method: 'GET',
            url: '$testBaseUrl/api/problems',
            showErrorSnackBar: false,
          ),
          throwsA(isA<UnauthorizedException>()),
        );

        expect(client.callCount, 1);
        verifyNever(() => tokenProvider.refreshAccessToken());
        verify(() => tokenProvider.notifyAuthFailure()).called(1);
      });
    }
  });

  group('갱신 자체가 실패할 때', () {
    test('네트워크 오류로 갱신하지 못하면 로그아웃시키지 않고 그 오류를 그대로 올린다', () async {
      final client = TestHttpClient.respondWith(
        errorResponse(statusCode: 401, errorCode: 1007, message: '인증 실패'),
      );
      final tokenProvider = buildMockTokenProvider();
      when(() => tokenProvider.refreshAccessToken())
          .thenThrow(NetworkException());

      await expectLater(
        HttpService(client: client.client, tokenProvider: tokenProvider)
            .sendRequest(
          method: 'GET',
          url: '$testBaseUrl/api/problems',
          showErrorSnackBar: false,
        ),
        throwsA(isA<NetworkException>()),
      );

      expect(client.callCount, 1);
      verifyNever(() => tokenProvider.notifyAuthFailure());
    });

    test('갱신이 인증 실패로 끝나면 재시도하지 않는다', () async {
      final client = TestHttpClient.respondWith(
        errorResponse(statusCode: 401, errorCode: 1007, message: '인증 실패'),
      );
      final tokenProvider = buildMockTokenProvider();
      when(() => tokenProvider.refreshAccessToken())
          .thenThrow(UnauthorizedException(errorCode: 1006));

      await expectLater(
        HttpService(client: client.client, tokenProvider: tokenProvider)
            .sendRequest(
          method: 'GET',
          url: '$testBaseUrl/api/problems',
          showErrorSnackBar: false,
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(client.callCount, 1);
    });
  });

  group('여러 요청이 동시에 1007 을 받을 때', () {
    setUp(() => TokenProvider.registerAuthFailureHandler(() async {}));

    test('갱신 요청은 한 번만 나가고 두 요청 모두 새 토큰으로 성공한다', () async {
      final storage = stubSecureStorage(initialData: {
        'accessToken': 'old-access',
        'refreshToken': 'old-refresh',
      });
      final client = TestHttpClient.handler((request) async {
        if (request.url.path == '/api/auth/refresh') {
          // 두 번째 요청이 갱신 도중에 1007 을 받도록 응답을 조금 늦춘다.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return jsonResponse(apiEnvelope({
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
          }));
        }
        if (request.authorization == 'new-access') {
          return jsonResponse(apiEnvelope({'ok': true}));
        }
        return errorResponse(
            statusCode: 401, errorCode: 1007, message: '인증이 실패했습니다.');
      });
      final httpService = HttpService(
        client: client.client,
        tokenProvider: TokenProvider(client: client.client),
      );

      final results = await Future.wait([
        httpService.sendRequest(
          method: 'GET',
          url: '$testBaseUrl/api/problems',
          showErrorSnackBar: false,
        ),
        httpService.sendRequest(
          method: 'GET',
          url: '$testBaseUrl/api/folders',
          showErrorSnackBar: false,
        ),
      ]);

      expect(results, [
        {'ok': true},
        {'ok': true},
      ]);
      final refreshCalls =
          client.captured.where((r) => r.url.path == '/api/auth/refresh');
      expect(refreshCalls.length, 1);
      expect(storage['accessToken'], 'new-access');
      expect(storage['refreshToken'], 'new-refresh');
    });

    test('갱신 응답이 네트워크 오류면 토큰을 지우지 않는다', () async {
      final storage = stubSecureStorage(initialData: {
        'accessToken': 'old-access',
        'refreshToken': 'old-refresh',
      });
      final client = TestHttpClient.handler((request) async {
        if (request.url.path == '/api/auth/refresh') {
          throw const SocketException('연결 실패');
        }
        return errorResponse(
            statusCode: 401, errorCode: 1007, message: '인증이 실패했습니다.');
      });
      final httpService = HttpService(
        client: client.client,
        tokenProvider: TokenProvider(client: client.client),
      );

      await expectLater(
        httpService.sendRequest(
          method: 'GET',
          url: '$testBaseUrl/api/problems',
          showErrorSnackBar: false,
        ),
        throwsA(isA<NetworkException>()),
      );

      expect(storage['accessToken'], 'old-access');
      expect(storage['refreshToken'], 'old-refresh');
    });
  });

  group('서버가 갱신 뒤에도 인증을 못 할 때 저장된 토큰', () {
    // UserProvider._handleAuthFailure → resetUserInfo 가 토큰을 지우는 것을 흉내낸다.
    // 이 핸들러가 불리는지가 곧 사용자가 로그아웃되는지다.
    setUp(() {
      TokenProvider.registerAuthFailureHandler(
        () async => TokenProvider().deleteToken(),
      );
    });

    test('갱신은 됐는데 재시도가 또 1007 이면 새로 받은 토큰을 지우지 않는다', () async {
      final storage = stubSecureStorage(initialData: {
        'accessToken': 'old-access',
        'refreshToken': 'old-refresh',
      });
      final client = TestHttpClient.handler((request) async {
        if (request.url.path == '/api/auth/refresh') {
          // 갱신은 DB 만 보므로 Redis 가 죽어 있어도 성공한다.
          return jsonResponse(apiEnvelope({
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
          }));
        }
        // 블랙리스트 조회가 실패하는 동안에는 새 토큰으로도 1007 이 온다.
        return errorResponse(
            statusCode: 401, errorCode: 1007, message: '인증이 실패했습니다.');
      });
      final httpService = HttpService(
        client: client.client,
        tokenProvider: TokenProvider(client: client.client),
      );

      await expectLater(
        httpService.sendRequest(
          method: 'GET',
          url: '$testBaseUrl/api/problems',
          showErrorSnackBar: false,
        ),
        throwsA(isA<ServerException>()),
      );

      expect(storage['accessToken'], 'new-access');
      expect(storage['refreshToken'], 'new-refresh');
    });

    test('갱신이 리프레시 토큰 거절로 끝나면 토큰을 지운다', () async {
      final storage = stubSecureStorage(initialData: {
        'accessToken': 'old-access',
        'refreshToken': 'old-refresh',
      });
      final client = TestHttpClient.handler((request) async {
        if (request.url.path == '/api/auth/refresh') {
          return errorResponse(
            statusCode: 400,
            errorCode: 1001,
            message: '유효하지 않은 리프레시토큰입니다.',
          );
        }
        return errorResponse(
            statusCode: 401, errorCode: 1007, message: '인증이 실패했습니다.');
      });
      final httpService = HttpService(
        client: client.client,
        tokenProvider: TokenProvider(client: client.client),
      );

      await expectLater(
        httpService.sendRequest(
          method: 'GET',
          url: '$testBaseUrl/api/problems',
          showErrorSnackBar: false,
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(storage['accessToken'], isNull);
      expect(storage['refreshToken'], isNull);
    });

    test('탈퇴 계정처럼 리프레시 토큰을 찾을 수 없으면 토큰을 지운다', () async {
      final storage = stubSecureStorage(initialData: {
        'accessToken': 'old-access',
        'refreshToken': 'old-refresh',
      });
      final client = TestHttpClient.handler((request) async {
        if (request.url.path == '/api/auth/refresh') {
          return errorResponse(
            statusCode: 401,
            errorCode: 1002,
            message: '리프레시 토큰 정보를 찾을 수 없습니다.',
          );
        }
        return errorResponse(
            statusCode: 401, errorCode: 1007, message: '인증이 실패했습니다.');
      });
      final httpService = HttpService(
        client: client.client,
        tokenProvider: TokenProvider(client: client.client),
      );

      await expectLater(
        httpService.sendRequest(
          method: 'GET',
          url: '$testBaseUrl/api/problems',
          showErrorSnackBar: false,
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(storage['accessToken'], isNull);
      expect(storage['refreshToken'], isNull);
    });
  });
}
