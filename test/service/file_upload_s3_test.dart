// FileUploadService 의 S3 presigned PUT 경로 검증.
//
// 커밋 c2a6cdd 이전에는 `_uploadToS3` 가 최상위 `http.put` 을 직접 불러서 Client 를
// 갈아끼울 수 없었다(기존 test/service/file_upload_service_test.dart 가 `runWithClient`
// 로 Zone 의 기본 클라이언트를 바꿔치우는 우회를 쓴 이유). 지금은 `s3Client:` 로 직접
// 주입할 수 있어서 백엔드로 가는 요청(httpService)과 S3 로 가는 요청(s3Client)을
// 서로 다른 TestHttpClient 로 완전히 분리해서 볼 수 있다.
import 'dart:async' as async_lib;
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart' show XFile;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Response;
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Service/Api/FileUpload/FileUploadService.dart';
import 'package:ono/Service/Api/HttpService.dart';

import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  XFile fakeImage({
    String path = 'photo.png',
    List<int> bytes = const [1, 2, 3, 4],
  }) {
    return XFile.fromData(Uint8List.fromList(bytes), path: path);
  }

  Response presignedUrlsResponse(List<Map<String, String>> entries) =>
      jsonResponse(entries);

  FileUploadService buildService({
    required TestHttpClient backend,
    required TestHttpClient s3,
  }) {
    return FileUploadService(
      httpService: HttpService(
        client: backend.client,
        tokenProvider: buildMockTokenProvider(),
      ),
      s3Client: s3.client,
    );
  }

  group('정상 흐름 — 백엔드와 S3 요청이 서로 다른 client 로 나간다', () {
    test('presigned url 발급은 backend client 로, PUT 은 s3Client 로 나간다', () async {
      final backend = TestHttpClient.respondWith(
        presignedUrlsResponse([
          {
            'presignedUrl': 'https://s3.test/bucket/key1?sig=abc',
            'fileUrl': 'https://cdn.test/key1.png',
          },
        ]),
      );
      final s3 =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 200));

      final url = await buildService(backend: backend, s3: s3)
          .uploadImageFile(fakeImage());

      expect(url, 'https://cdn.test/key1.png');

      // 백엔드로는 presigned url 요청 딱 하나만 나가야 한다.
      expect(backend.callCount, 1);
      expect(backend.lastRequest.method, 'GET');
      expect(
        backend.lastRequest.url.toString(),
        '$testBaseUrl/api/fileUpload/presigned-urls?count=1&contentType=image%2Fpng',
      );
      expect(backend.lastRequest.authorization, 'test-access-token');

      // S3 로는 PUT 하나만 나가야 하고, 앱의 인증 토큰이 새어나가면 안 된다.
      expect(s3.callCount, 1);
      final s3Request = s3.lastRequest;
      expect(s3Request.method, 'PUT');
      expect(s3Request.url.toString(), 'https://s3.test/bucket/key1?sig=abc');
      expect(s3Request.authorization, isNull);
      expect(s3Request.bodyBytes, [1, 2, 3, 4]);
    });

    test('S3 PUT 의 Content-Type 헤더가 파일 확장자에 맞게 실린다', () async {
      final cases = <String, String>{
        'photo.jpg': 'image/jpeg',
        'photo.jpeg': 'image/jpeg',
        'photo.png': 'image/png',
        'photo.gif': 'image/gif',
        'photo.webp': 'image/webp',
        'photo.heic': 'image/heic',
        'photo.unknown': 'application/octet-stream',
      };

      for (final entry in cases.entries) {
        final backend = TestHttpClient.respondWith(
          presignedUrlsResponse([
            {
              'presignedUrl': 'https://s3.test/x',
              'fileUrl': 'https://cdn.test/x'
            },
          ]),
        );
        final s3 =
            TestHttpClient.respondWith(jsonResponse(null, statusCode: 200));

        await buildService(backend: backend, s3: s3)
            .uploadImageFile(fakeImage(path: entry.key));

        expect(
          s3.lastRequest.contentType,
          entry.value,
          reason: '${entry.key} 는 ${entry.value} 로 업로드되어야 한다',
        );
        expect(
          backend.lastRequest.queryParameters['contentType'],
          entry.value,
        );
      }
    });
  });

  group('실패 흐름', () {
    test('S3 가 4xx 를 응답하면 ApiException(statusCode 그대로)', () async {
      final backend = TestHttpClient.respondWith(
        presignedUrlsResponse([
          {
            'presignedUrl': 'https://s3.test/1',
            'fileUrl': 'https://cdn.test/1'
          },
        ]),
      );
      final s3 =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 403));

      await expectLater(
        buildService(backend: backend, s3: s3).uploadImageFile(fakeImage()),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('S3 가 5xx 를 응답해도 ApiException 으로 처리한다', () async {
      final backend = TestHttpClient.respondWith(
        presignedUrlsResponse([
          {
            'presignedUrl': 'https://s3.test/1',
            'fileUrl': 'https://cdn.test/1'
          },
        ]),
      );
      final s3 =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 500));

      await expectLater(
        buildService(backend: backend, s3: s3).uploadImageFile(fakeImage()),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('S3 로의 전송 자체가 실패하면(SocketException) NetworkException', () async {
      final backend = TestHttpClient.respondWith(
        presignedUrlsResponse([
          {
            'presignedUrl': 'https://s3.test/1',
            'fileUrl': 'https://cdn.test/1'
          },
        ]),
      );
      final s3 = TestHttpClient.throwing(const SocketException('연결 실패'));

      await expectLater(
        buildService(backend: backend, s3: s3).uploadImageFile(fakeImage()),
        throwsA(isA<NetworkException>()),
      );
    });

    test('S3 PUT 이 타임아웃되면 TimeoutException', () async {
      final backend = TestHttpClient.respondWith(
        presignedUrlsResponse([
          {
            'presignedUrl': 'https://s3.test/1',
            'fileUrl': 'https://cdn.test/1'
          },
        ]),
      );
      // 실제로 90초를 기다리는 대신 .timeout() 이 던지는 예외를 그대로 재현한다.
      final s3 = TestHttpClient.throwing(async_lib.TimeoutException('timeout'));

      await expectLater(
        buildService(backend: backend, s3: s3).uploadImageFile(fakeImage()),
        throwsA(isA<TimeoutException>()),
      );
    });

    test(
      '같은 확장자 그룹에서 한 파일이 실패해도 다른 파일의 PUT 은 이미 나간 뒤다 (Future.wait, eagerError 미설정)',
      () async {
        final backend = TestHttpClient.respondWith(
          presignedUrlsResponse([
            {
              'presignedUrl': 'https://s3.test/ok',
              'fileUrl': 'https://cdn.test/ok.png'
            },
            {
              'presignedUrl': 'https://s3.test/fail',
              'fileUrl': 'https://cdn.test/fail.png'
            },
          ]),
        );
        final s3 = TestHttpClient.handler((req) async {
          if (req.url.toString().contains('fail')) {
            throw const SocketException('연결 실패');
          }
          return jsonResponse(null, statusCode: 200);
        });

        await expectLater(
          buildService(backend: backend, s3: s3).uploadMultipleImageFiles([
            fakeImage(path: 'a.png'),
            fakeImage(path: 'b.png'),
          ]),
          throwsA(isA<NetworkException>()),
        );

        // Future.wait 는 기본값(eagerError: false)이라, 그룹 안의 한 파일이 실패해도
        // 다른 파일의 PUT 요청은 이미 나간 뒤에야 예외가 던져진다. 다만 그 결과(fileUrl)는
        // 예외 때문에 버려지고 호출자에게는 반환되지 않는다 — 성공한 S3 업로드가 있어도
        // 전체 호출은 실패로 끝난다는 뜻이다.
        expect(s3.callCount, 2);
      },
    );

    test('presigned url 개수가 요청한 파일 수와 다르면 ApiException (S3 요청 없음)', () async {
      final backend = TestHttpClient.respondWith(
        presignedUrlsResponse([
          {
            'presignedUrl': 'https://s3.test/1',
            'fileUrl': 'https://cdn.test/1'
          },
        ]),
      );
      final s3 =
          TestHttpClient.respondWith(jsonResponse(null, statusCode: 200));

      await expectLater(
        buildService(backend: backend, s3: s3).uploadMultipleImageFiles([
          fakeImage(path: 'a.png'),
          fakeImage(path: 'b.png'),
        ]),
        throwsA(isA<ApiException>()),
      );
      expect(s3.callCount, 0);
    });
  });
}
