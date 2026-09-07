import 'dart:async' as async_lib;
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart' show XFile;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show runWithClient, Response;
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Service/Api/FileUpload/FileUploadService.dart';
import 'package:ono/Service/Api/HttpService.dart';

import '../helpers/helpers.dart';

/// FileUploadService 가 백엔드(presigned URL 발급)와 S3(실제 업로드)를
/// 오가는 계약을 검증한다.
///
/// 이 서비스는 두 군데로 요청을 보낸다.
/// 1. `GET /api/fileUpload/presigned-urls` — 우리 백엔드. HttpService 로 나가므로
///    TestHttpClient 를 주입해서 본다.
/// 2. presigned URL 로의 직접 PUT — S3. FileUploadService 는 이 부분을
///    HttpService 를 거치지 않고 package:http 최상위 함수(`http.put`)로 직접 보낸다.
///    그래서 이 요청은 TestHttpClient 주입만으로는 잡히지 않고,
///    `package:http` 의 `runWithClient` 로 Zone 안의 기본 클라이언트를 바꿔치기해야
///    가로챌 수 있다. 두 경로 모두 같은 TestHttpClient 로 보내면 한 번에 기록된다.
void main() {
  setUpOnoTest();

  FileUploadService buildService(TestHttpClient http) {
    return FileUploadService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(),
      ),
    );
  }

  /// [service] 호출을 실행하되, package:http 최상위 함수가 쓰는 기본 클라이언트를
  /// [http] 의 것으로 바꿔서(S3 로의 직접 PUT까지) 같은 TestHttpClient 가 기록하게 한다.
  Future<T> runUpload<T>(TestHttpClient http, Future<T> Function() call) {
    return runWithClient(call, () => http.client);
  }

  XFile fakeImage({
    String path = 'photo.png',
    List<int> bytes = const [1, 2, 3, 4],
  }) {
    return XFile.fromData(Uint8List.fromList(bytes), path: path);
  }

  Response presignedUrlsResponse(List<Map<String, String>> entries) =>
      jsonResponse(entries);

  group('uploadImageFile / uploadMultipleImageFiles — 정상 흐름', () {
    test('presigned url 을 받아 S3 로 PUT 하고 fileUrl 을 반환한다', () async {
      final http = TestHttpClient.handler((req) async {
        if (req.url.path.contains('presigned-urls')) {
          return presignedUrlsResponse([
            {
              'presignedUrl': 'https://s3.test/bucket/key1?sig=abc',
              'fileUrl': 'https://cdn.test/key1.png',
            },
          ]);
        }
        // S3 로의 직접 PUT.
        return jsonResponse(null, statusCode: 200);
      });

      final url = await runUpload(
        http,
        () => buildService(http).uploadImageFile(fakeImage()),
      );

      expect(url, 'https://cdn.test/key1.png');
      expect(http.callCount, 2);

      final presignedRequest = http.captured[0];
      expect(presignedRequest.method, 'GET');
      expect(
        presignedRequest.url.toString(),
        '$testBaseUrl/api/fileUpload/presigned-urls?count=1&contentType=image%2Fpng',
      );
      expect(presignedRequest.authorization, 'test-access-token');

      final s3Request = http.captured[1];
      expect(s3Request.method, 'PUT');
      expect(s3Request.url.toString(), 'https://s3.test/bucket/key1?sig=abc');
      expect(s3Request.contentType, 'image/png');
      // 앱의 인증 토큰이 S3 로 새어나가면 안 된다.
      expect(s3Request.authorization, isNull);
      expect(s3Request.bodyBytes, [1, 2, 3, 4]);
    });

    test('확장자에 따라 contentType 쿼리 파라미터가 달라진다', () async {
      final http = TestHttpClient.handler((req) async {
        if (req.url.path.contains('presigned-urls')) {
          return presignedUrlsResponse([
            {
              'presignedUrl': 'https://s3.test/bucket/key.jpg',
              'fileUrl': 'https://cdn.test/key.jpg',
            },
          ]);
        }
        return jsonResponse(null, statusCode: 200);
      });

      await runUpload(
        http,
        () => buildService(http).uploadImageFile(fakeImage(path: 'photo.jpg')),
      );

      expect(
        http.captured.first.queryParameters['contentType'],
        'image/jpeg',
      );
    });

    test(
        '서로 다른 확장자의 파일은 contentType 별로 presigned url 을 따로 요청하지만'
        ' 원래 순서를 유지해 반환한다', () async {
      final requestedContentTypes = <String>[];
      final http = TestHttpClient.handler((req) async {
        if (req.url.path.contains('presigned-urls')) {
          final contentType = req.queryParameters['contentType']!;
          requestedContentTypes.add(contentType);
          final ext = contentType == 'image/png' ? 'png' : 'jpg';
          return presignedUrlsResponse([
            {
              'presignedUrl': 'https://s3.test/$ext',
              'fileUrl': 'https://cdn.test/result.$ext',
            },
          ]);
        }
        return jsonResponse(null, statusCode: 200);
      });

      final urls = await runUpload(
        http,
        () => buildService(http).uploadMultipleImageFiles([
          fakeImage(path: 'a.png'),
          fakeImage(path: 'b.jpg'),
        ]),
      );

      expect(requestedContentTypes.toSet(), {'image/png', 'image/jpeg'});
      // a.png 가 먼저였으니 결과도 png 결과가 먼저 와야 한다.
      expect(
          urls, ['https://cdn.test/result.png', 'https://cdn.test/result.jpg']);
    });

    test('파일 목록이 비어 있으면 요청 없이 빈 리스트를 반환한다', () async {
      final http = TestHttpClient.respondJson(<dynamic>[]);

      final urls = await runUpload(
        http,
        () => buildService(http).uploadMultipleImageFiles([]),
      );

      expect(urls, isEmpty);
      expect(http.callCount, 0);
    });

    test('null 리스트를 넘겨도 빈 리스트를 반환한다', () async {
      final http = TestHttpClient.respondJson(<dynamic>[]);

      final urls = await runUpload(
        http,
        () => buildService(http).uploadMultipleImageFiles(null),
      );

      expect(urls, isEmpty);
    });
  });

  group('uploadImageFile / uploadMultipleImageFiles — 실패 흐름', () {
    test('presigned url 개수가 요청한 파일 수와 다르면 ApiException', () async {
      final http = TestHttpClient.handler((req) async {
        if (req.url.path.contains('presigned-urls')) {
          // 2개를 요청했는데 1개만 내려준다.
          return presignedUrlsResponse([
            {
              'presignedUrl': 'https://s3.test/1',
              'fileUrl': 'https://cdn.test/1'
            },
          ]);
        }
        return jsonResponse(null, statusCode: 200);
      });

      await expectLater(
        runUpload(
          http,
          () => buildService(http).uploadMultipleImageFiles([
            fakeImage(path: 'a.png'),
            fakeImage(path: 'b.png'),
          ]),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('presigned url 응답에 presignedUrl 필드가 없으면 ApiException', () async {
      final http = TestHttpClient.handler((req) async {
        if (req.url.path.contains('presigned-urls')) {
          return jsonResponse([
            {'fileUrl': 'https://cdn.test/1'}, // presignedUrl 누락
          ]);
        }
        return jsonResponse(null, statusCode: 200);
      });

      await expectLater(
        runUpload(http, () => buildService(http).uploadImageFile(fakeImage())),
        throwsA(isA<ApiException>()),
      );
    });

    test('presigned url 발급이 500 이면 ServerException', () async {
      final http = TestHttpClient.handler((req) async {
        if (req.url.path.contains('presigned-urls')) {
          return errorResponse(statusCode: 500, message: '서버 오류');
        }
        return jsonResponse(null, statusCode: 200);
      });

      await expectLater(
        runUpload(http, () => buildService(http).uploadImageFile(fakeImage())),
        throwsA(isA<ServerException>()),
      );
    });

    test('S3 업로드 응답이 실패 상태 코드면 ApiException', () async {
      final http = TestHttpClient.handler((req) async {
        if (req.url.path.contains('presigned-urls')) {
          return presignedUrlsResponse([
            {
              'presignedUrl': 'https://s3.test/1',
              'fileUrl': 'https://cdn.test/1'
            },
          ]);
        }
        return jsonResponse(null, statusCode: 403); // S3 가 서명 만료 등으로 거절
      });

      await expectLater(
        runUpload(http, () => buildService(http).uploadImageFile(fakeImage())),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('S3 로의 전송 자체가 실패하면 NetworkException', () async {
      final http = TestHttpClient.handler((req) async {
        if (req.url.path.contains('presigned-urls')) {
          return presignedUrlsResponse([
            {
              'presignedUrl': 'https://s3.test/1',
              'fileUrl': 'https://cdn.test/1'
            },
          ]);
        }
        throw const SocketException('연결 실패');
      });

      await expectLater(
        runUpload(http, () => buildService(http).uploadImageFile(fakeImage())),
        throwsA(isA<NetworkException>()),
      );
    });

    test('S3 로의 PUT 이 타임아웃되면 TimeoutException', () async {
      final http = TestHttpClient.handler((req) async {
        if (req.url.path.contains('presigned-urls')) {
          return presignedUrlsResponse([
            {
              'presignedUrl': 'https://s3.test/1',
              'fileUrl': 'https://cdn.test/1'
            },
          ]);
        }
        // 실제로 90초를 기다리는 대신 .timeout() 이 던지는 예외를 그대로 재현한다.
        throw async_lib.TimeoutException('timeout');
      });

      await expectLater(
        runUpload(http, () => buildService(http).uploadImageFile(fakeImage())),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('deleteImage', () {
    test('DELETE /api/fileUpload/image 로 쿼리 파라미터에 imageUrl 을 담아 보낸다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).deleteImage('https://cdn.test/1.png');

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        startsWith('$testBaseUrl/api/fileUpload/image'),
      );
      expect(
        http.lastRequest.queryParameters['imageUrl'],
        'https://cdn.test/1.png',
      );
      expect(http.lastRequest.authorization, 'test-access-token');
    });

    test('404 면 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, message: '이미지를 찾을 수 없습니다'),
      );

      await expectLater(
        buildService(http).deleteImage('https://cdn.test/missing.png'),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final tokenlessHttp = TestHttpClient.respondWith(emptyResponse());
      final service = FileUploadService(
        httpService: HttpService(
          client: tokenlessHttp.client,
          tokenProvider: buildMockTokenProvider(accessToken: null),
        ),
      );

      await expectLater(
        service.deleteImage('https://cdn.test/1.png'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(tokenlessHttp.callCount, 0);
    });
  });
}
