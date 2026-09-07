import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Model/Folder/FolderRegisterModel.dart';
import 'package:ono/Service/Api/Folder/FolderService.dart';
import 'package:ono/Service/Api/HttpService.dart';

import '../helpers/helpers.dart';

/// FolderService 가 백엔드와 주고받는 계약을 검증한다.
void main() {
  setUpOnoTest();

  FolderService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return FolderService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  Map<String, dynamic> fullFolderJson(
      {int folderId = 3, String folderName = '수학'}) {
    return {
      'folderId': folderId,
      'folderName': folderName,
      'parentFolder': {'folderId': 1, 'folderName': '루트', 'problemCount': 5},
      'problemIdList': [1, 2, 3],
      'subFolderList': [
        {'folderId': 4, 'folderName': '미적분', 'problemCount': 2},
      ],
      'createdAt': '2026-07-01T10:00:00.000Z',
      'updateAt': '2026-07-02T10:00:00.000Z',
    };
  }

  group('fetchFolder', () {
    test('GET /api/folders/{id} 로 폴더를 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(fullFolderJson()));

      final folder = await buildService(http).fetchFolder(3);

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/folders/3');
      expect(http.lastRequest.authorization, 'test-access-token');
      expect(folder.folderId, 3);
      expect(folder.folderName, '수학');
      expect(folder.parentFolder?.folderId, 1);
      expect(folder.problemIdList, [1, 2, 3]);
      expect(folder.subFolderList, hasLength(1));
    });

    test('parentFolder 가 없는 루트 폴더도 정상 매핑된다', () async {
      final json = fullFolderJson()..remove('parentFolder');
      final http = TestHttpClient.respondJson(apiEnvelope(json));

      final folder = await buildService(http).fetchFolder(3);

      expect(folder.parentFolder, isNull);
    });

    test('folderId 가 응답에 없으면 TypeError 로 죽는다', () async {
      final json = fullFolderJson()..remove('folderId');
      final http = TestHttpClient.respondJson(apiEnvelope(json));

      await expectLater(
        buildService(http).fetchFolder(3, showErrorSnackBar: false),
        throwsA(isA<TypeError>()),
      );
    });

    test('400 이면 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, message: '잘못된 요청'),
      );

      await expectLater(
        buildService(http).fetchFolder(3, showErrorSnackBar: false),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('500 이면 ServerException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      await expectLater(
        buildService(http).fetchFolder(3, showErrorSnackBar: false),
        throwsA(isA<ServerException>()),
      );
    });

    test('errorCode 가 1000번대면 401 이 아니어도 UnauthorizedException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 1005, message: '토큰 만료'),
      );

      await expectLater(
        buildService(http).fetchFolder(3, showErrorSnackBar: false),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('전송 자체가 실패하면 NetworkException', () async {
      final http = TestHttpClient.throwing(const SocketException('연결 실패'));

      await expectLater(
        buildService(http).fetchFolder(3, showErrorSnackBar: false),
        throwsA(isA<NetworkException>()),
      );
    });

    test('실패 응답인데 JSON 이 아니면 ParseException', () async {
      final http = TestHttpClient.respondWith(
        textResponse('<html>오류</html>', statusCode: 500),
      );

      await expectLater(
        buildService(http).fetchFolder(3, showErrorSnackBar: false),
        throwsA(isA<ParseException>()),
      );
    });

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(fullFolderJson()));

      await expectLater(
        buildService(http, accessToken: null)
            .fetchFolder(3, showErrorSnackBar: false),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });
  });

  group('getRootFolder', () {
    test('GET /api/folders/root 로 루트 폴더를 조회한다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope(fullFolderJson(folderId: 1, folderName: '루트')),
      );

      final folder = await buildService(http).getRootFolder();

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/folders/root',
      );
      expect(folder.folderId, 1);
    });
  });

  group('getAllFolderThumbnails / getAllFolderDetails', () {
    test('getAllFolderThumbnails 는 GET /api/folders/thumbnails', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([
        {'folderId': 1, 'folderName': '루트', 'problemCount': 3},
        {'folderId': 2, 'folderName': '영어', 'problemCount': 0},
      ]));

      final thumbnails = await buildService(http).getAllFolderThumbnails();

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/folders/thumbnails',
      );
      expect(thumbnails, hasLength(2));
      expect(thumbnails.first.problemCount, 3);
    });

    test('problemCount 가 문자열로 와도 정수로 변환된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([
        {'folderId': 1, 'folderName': '루트', 'problemCount': '7'},
      ]));

      final thumbnails = await buildService(http).getAllFolderThumbnails();

      expect(thumbnails.first.problemCount, 7);
    });

    test('getAllFolderDetails 는 GET /api/folders', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([fullFolderJson()]));

      final folders = await buildService(http).getAllFolderDetails();

      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/folders');
      expect(folders, hasLength(1));
    });
  });

  group('registerFolder', () {
    test('POST /api/folders 로 폴더를 등록하고 id 를 받는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(9));

      final model = FolderRegisterModel(folderName: '새 폴더', parentFolderId: 1);
      final id = await buildService(http).registerFolder(model);

      expect(http.lastRequest.method, 'POST');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/folders');
      expect(http.lastRequest.contentType, contains('application/json'));
      final body = http.lastRequest.jsonBody!;
      expect(body['folderName'], '새 폴더');
      expect(body['parentFolderId'], 1);
      expect(id, 9);
    });
  });

  group('updateFolderInfo', () {
    test('PATCH /api/folders 로 폴더 정보를 수정한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      final model = FolderRegisterModel(
        folderId: 3,
        folderName: '수정된 이름',
        parentFolderId: 1,
      );
      await buildService(http).updateFolderInfo(model);

      expect(http.lastRequest.method, 'PATCH');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/folders');
      expect(http.lastRequest.jsonBody!['folderName'], '수정된 이름');
    });
  });

  group('deleteFolders / deleteUserFolders', () {
    test('deleteFolders 는 DELETE /api/folders, 바디에 삭제할 id 목록을 담는다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).deleteFolders([1, 2]);

      expect(http.lastRequest.method, 'DELETE');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/folders');
      expect(http.lastRequest.jsonBody!['deleteFolderIdList'], [1, 2]);
    });

    test('deleteUserFolders 는 DELETE /api/folders/all', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).deleteUserFolders();

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/folders/all',
      );
    });
  });

  group('getSubfoldersV2 / getAllFolderThumbnailsV2', () {
    Map<String, dynamic> page() => {
          'content': [
            {'folderId': 4, 'folderName': '미적분', 'problemCount': 2},
          ],
          'nextCursor': 8,
          'hasNext': true,
          'size': 1,
        };

    test('getSubfoldersV2: cursor 없이 size 만 보낸다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(page()));

      final result =
          await buildService(http).getSubfoldersV2(folderId: 3, size: 20);

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/folders/3/subfolders/V2?size=20',
      );
      expect(result.content, hasLength(1));
      expect(result.hasNext, isTrue);
      expect(result.isLastPage, isFalse);
    });

    test('getSubfoldersV2: cursor 가 있으면 cursor 와 size 를 함께 보낸다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(page()));

      await buildService(http).getSubfoldersV2(folderId: 3, cursor: 2, size: 5);

      expect(http.lastRequest.queryParameters['cursor'], '2');
      expect(http.lastRequest.queryParameters['size'], '5');
    });

    test('getAllFolderThumbnailsV2: GET /api/folders/thumbnails/V2', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(page()));

      await buildService(http).getAllFolderThumbnailsV2(size: 20);

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/folders/thumbnails/V2?size=20',
      );
    });

    test('hasNext 필드가 응답에서 빠지면 TypeError 로 죽는다', () async {
      final broken = page()..remove('hasNext');
      final http = TestHttpClient.respondJson(apiEnvelope(broken));

      await expectLater(
        buildService(http).getSubfoldersV2(folderId: 3),
        throwsA(isA<TypeError>()),
      );
    });

    test('마지막 페이지(hasNext:false, nextCursor:null)면 isLastPage 가 true',
        () async {
      final lastPage = {
        'content': <dynamic>[],
        'nextCursor': null,
        'hasNext': false,
        'size': 0,
      };
      final http = TestHttpClient.respondJson(apiEnvelope(lastPage));

      final result = await buildService(http).getAllFolderThumbnailsV2();

      expect(result.isLastPage, isTrue);
    });
  });
}
