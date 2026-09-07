import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/Tag/TagService.dart';

import '../helpers/helpers.dart';

/// TagService 가 백엔드와 주고받는 계약을 검증한다.
void main() {
  setUpOnoTest();

  TagService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return TagService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  group('getMyTags', () {
    test('GET /api/tags 로 태그 목록을 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([
        {'tagId': 1, 'name': '미적분'},
        {'tagId': 2, 'name': '수열'},
      ]));

      final tags = await buildService(http).getMyTags();

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/tags');
      expect(http.lastRequest.authorization, 'test-access-token');
      expect(tags, hasLength(2));
      expect(tags.first.name, '미적분');
    });

    test('빈 배열이면 빈 리스트를 반환한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<dynamic>[]));

      final tags = await buildService(http).getMyTags();

      expect(tags, isEmpty);
    });

    test('tagId 가 응답에 없으면 TypeError 로 죽는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([
        {'name': '이름만 있음'},
      ]));

      await expectLater(
        buildService(http).getMyTags(),
        throwsA(isA<TypeError>()),
      );
    });

    test('name 이 응답에 없으면 빈 문자열로 방어된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([
        {'tagId': 1},
      ]));

      final tags = await buildService(http).getMyTags();

      expect(tags.first.name, '');
    });

    test('400 이면 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, message: '잘못된 요청'),
      );

      await expectLater(
        buildService(http).getMyTags(),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('500 이면 ServerException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      await expectLater(
        buildService(http).getMyTags(),
        throwsA(isA<ServerException>()),
      );
    });

    test('errorCode 가 1000번대면 UnauthorizedException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 1005, message: '토큰 만료'),
      );

      await expectLater(
        buildService(http).getMyTags(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('전송 자체가 실패하면 NetworkException', () async {
      final http = TestHttpClient.throwing(const SocketException('연결 실패'));

      await expectLater(
        buildService(http).getMyTags(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('실패 응답인데 JSON 이 아니면 ParseException', () async {
      final http = TestHttpClient.respondWith(
        textResponse('<html>오류</html>', statusCode: 500),
      );

      await expectLater(
        buildService(http).getMyTags(),
        throwsA(isA<ParseException>()),
      );
    });

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<dynamic>[]));

      await expectLater(
        buildService(http, accessToken: null).getMyTags(),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });
  });

  group('createTag', () {
    test('POST /api/tags 로 태그를 생성하고 TagModel 을 받는다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({'tagId': 10, 'name': '새 태그'}),
      );

      final tag = await buildService(http).createTag('새 태그');

      expect(http.lastRequest.method, 'POST');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/tags');
      expect(http.lastRequest.contentType, contains('application/json'));
      expect(http.lastRequest.jsonBody, {'name': '새 태그'});
      expect(tag.tagId, 10);
      expect(tag.name, '새 태그');
    });

    test('태그 이름 제한 초과(errorCode 로 판별하는 비즈니스 에러)면 BadRequestException',
        () async {
      final http = TestHttpClient.respondWith(
        errorResponse(
            statusCode: 400, errorCode: 4002, message: '태그 이름은 30자 이하여야 합니다'),
      );

      await expectLater(
        buildService(http).createTag(List.filled(10, '아주 긴 이름').join()),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('deleteTag', () {
    test('DELETE /api/tags/{id} 로 태그를 삭제한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).deleteTag(10);

      expect(http.lastRequest.method, 'DELETE');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/tags/10');
    });
  });

  group('deleteTags', () {
    test('DELETE /api/tags 로 여러 태그를 한 번에 삭제한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).deleteTags([1, 2, 3]);

      expect(http.lastRequest.method, 'DELETE');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/tags');
      expect(http.lastRequest.jsonBody!['deleteTagIdList'], [1, 2, 3]);
    });
  });

  group('recommendTags', () {
    test('POST /api/tags/recommend 로 이미지 기반 추천 태그를 받는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([
        {'tagId': 1, 'name': '미적분'},
      ]));

      final tags = await buildService(http)
          .recommendTags(imageUrls: const ['https://cdn.test/1.png']);

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/tags/recommend',
      );
      expect(http.lastRequest.jsonBody, {
        'imageUrls': ['https://cdn.test/1.png'],
      });
      expect(tags, hasLength(1));
    });

    test('imageUrls 가 없으면 빈 객체를 바디로 보낸다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<dynamic>[]));

      await buildService(http).recommendTags();

      expect(http.lastRequest.jsonBody, <String, dynamic>{});
    });

    test('응답이 리스트가 아니면(null 등) 예외 없이 빈 리스트를 반환한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(null));

      final tags = await buildService(http).recommendTags();

      expect(tags, isEmpty);
    });

    test('추천 태그 항목에 tagId 가 없으면 TypeError 로 죽는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([
        {'name': 'id 없는 태그'},
      ]));

      await expectLater(
        buildService(http).recommendTags(),
        throwsA(isA<TypeError>()),
      );
    });

    test('500 이면 ServerException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '추천 서버 오류'),
      );

      await expectLater(
        buildService(http).recommendTags(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
