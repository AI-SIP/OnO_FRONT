import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/PracticeNote/PracticeNoteService.dart';

import '../helpers/helpers.dart';

/// PracticeNoteService 계약 테스트.
///
/// PracticeNoteService 는 [HttpService] 가 돌려준 데이터를 직접 `as Map<String, dynamic>`
/// / `as List<dynamic>` 로 캐스팅해 모델에 넘긴다(StudyRoomService 의 `_asMap` 같은
/// 방어 코드가 없다). 그래서 응답이 기대한 모양이 아닐 때 어떤 예외가 나는지가
/// 이 서비스에서는 특히 중요하다.
void main() {
  setUpOnoTest();

  PracticeNoteService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return PracticeNoteService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  final detailJson = {
    'practiceNoteId': 1,
    'practiceTitle': '오답노트 1회독',
    'practiceCount': 2,
    'createdAt': '2026-08-01T10:00:00Z',
    'lastSolvedAt': '2026-08-20T10:00:00Z',
    'lastSessionMoodEmojiKey': 'happy',
    'problemIdList': [10, 11, 12],
  };

  final thumbnailJson = {
    'practiceNoteId': 1,
    'practiceTitle': '오답노트 1회독',
    'practiceCount': 2,
    'lastSolvedAt': '2026-08-20T10:00:00Z',
    'lastSessionMoodEmojiKey': 'happy',
  };

  group('getPracticeNoteById', () {
    test('GET /api/practiceNotes/{id}', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(detailJson));
      final note = await buildService(http).getPracticeNoteById(1);

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/practiceNotes/1',
      );
      expect(http.lastRequest.authorization, 'test-access-token');
      expect(note.practiceId, 1);
      expect(note.practiceTitle, '오답노트 1회독');
      expect(note.practiceSize, 3);
      expect(note.problemIdList, [10, 11, 12]);
    });

    // TODO(#174): 실제 버그. lib/Model/PracticeNote/PracticeNoteDetailModel.dart:36-39
    // practiceNoteId/createdAt 이 응답에서 빠지면 fromJson 이 null 을 그대로
    // non-nullable int/DateTime 자리에 넣으려다 TypeError 를 던진다. 다른 필드들처럼
    // `?? 기본값` 처리가 없어서, 백엔드가 필드 하나만 빼도 화면이 통째로 죽는다.
    test(
      'practiceNoteId 가 응답에서 빠지면 TypeError 로 죽는다',
      () async {
        final http = TestHttpClient.respondJson(
          apiEnvelope({
            'practiceTitle': '제목만 있음',
            'practiceCount': 0,
            'createdAt': '2026-08-01T10:00:00Z',
            'problemIdList': <int>[],
          }),
        );
        await buildService(http).getPracticeNoteById(1);
      },
      skip: '#174 에서 수정 예정',
    );

    // TODO(#174): 실제 버그. lib/Model/PracticeNote/PracticeNoteDetailModel.dart:39
    // createdAt 이 없으면 DateTime.parse(null) 이 TypeError 를 던진다.
    test(
      'createdAt 이 응답에서 빠지면 TypeError 로 죽는다',
      () async {
        final http = TestHttpClient.respondJson(
          apiEnvelope({
            'practiceNoteId': 1,
            'practiceTitle': '제목',
            'practiceCount': 0,
            'problemIdList': <int>[],
          }),
        );
        await buildService(http).getPracticeNoteById(1);
      },
      skip: '#174 에서 수정 예정',
    );

    test('showErrorSnackBar:false 로 넘기면 500 에도 스낵바 없이 ServerException',
        () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );
      await expectLater(
        buildService(http).getPracticeNoteById(1, showErrorSnackBar: false),
        throwsA(isA<ServerException>()),
      );
    });

    test('400 + errorCode 는 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 2001, message: '존재하지 않는 노트'),
      );
      await expectLater(
        buildService(http).getPracticeNoteById(1, showErrorSnackBar: false),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('errorCode 1000번대는 UnauthorizedException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 401, errorCode: 1001, message: '인증 실패'),
      );
      await expectLater(
        buildService(http).getPracticeNoteById(1, showErrorSnackBar: false),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('전송 실패는 NetworkException', () async {
      final http = TestHttpClient.throwing(const SocketException(''));
      await expectLater(
        buildService(http).getPracticeNoteById(1, showErrorSnackBar: false),
        throwsA(isA<NetworkException>()),
      );
    });

    test('실패 응답이 JSON 이 아니면 ParseException', () async {
      final http = TestHttpClient.respondWith(
        textResponse('Internal Server Error', statusCode: 500),
      );
      await expectLater(
        buildService(http).getPracticeNoteById(1, showErrorSnackBar: false),
        throwsA(isA<ParseException>()),
      );
    });

    // TODO(#174): 실제 버그. lib/Service/Api/PracticeNote/PracticeNoteService.dart:27
    // `PracticeNoteDetailModel.fromJson(data)` 는 data 를 캐스팅 없이 그대로 넘긴다.
    // 성공(2xx) 응답인데 JSON 이 아니면 HttpService 가 원문 문자열을 돌려주는데,
    // 그 String 이 그대로 fromJson(Map) 자리에 들어가 TypeError 로 죽는다.
    test(
      '성공 상태인데 응답이 JSON 이 아니면 TypeError 로 죽는다',
      () async {
        final http = TestHttpClient.respondWith(textResponse('OK'));
        await buildService(http).getPracticeNoteById(1);
      },
      skip: '#174 에서 수정 예정',
    );

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(detailJson));
      await expectLater(
        buildService(http, accessToken: null).getPracticeNoteById(1),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });
  });

  group('getAllPracticeNoteThumbnails', () {
    test('GET /api/practiceNotes/thumbnail', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([thumbnailJson]));
      final thumbnails =
          await buildService(http).getAllPracticeNoteThumbnails();

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/practiceNotes/thumbnail',
      );
      expect(thumbnails, hasLength(1));
      expect(thumbnails.first.practiceId, 1);
      expect(thumbnails.first.practiceTitle, '오답노트 1회독');
    });

    // TODO(#174): 실제 버그. lib/Service/Api/PracticeNote/PracticeNoteService.dart:34
    // `as List<dynamic>` 캐스팅이라 목록이 비어 apiEnvelope(null) 로 오면(HttpService 가
    // data 를 null 로 돌려줄 때) TypeError(Null 은 List<dynamic> 의 서브타입이 아님)로 죽는다.
    // StudyRoomService._mapList 처럼 null 을 빈 배열로 받아주는 방어가 없다.
    test(
      'data 가 null 이면(목록이 아예 없음) TypeError 로 죽는다',
      () async {
        final http = TestHttpClient.respondJson(apiEnvelope(null));
        await buildService(http).getAllPracticeNoteThumbnails();
      },
      skip: '#174 에서 수정 예정',
    );

    test('빈 배열이면 빈 목록을 돌려준다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<dynamic>[]));
      final thumbnails =
          await buildService(http).getAllPracticeNoteThumbnails();
      expect(thumbnails, isEmpty);
    });
  });

  group('getAllPracticeNoteDetails', () {
    test('GET /api/practiceNotes/all', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([detailJson]));
      final details = await buildService(http).getAllPracticeNoteDetails();

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/practiceNotes/all',
      );
      expect(details, hasLength(1));
      expect(details.first.practiceId, 1);
    });
  });

  group('registerPracticeNote', () {
    test('POST /api/practiceNotes, body 는 모델의 toJson 그대로 전송된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(9));
      final model = PracticeNoteRegisterModel(
        practiceTitle: '새 노트',
        registerProblemIdList: [1, 2, 3],
      );
      final newId = await buildService(http).registerPracticeNote(model);

      expect(http.lastRequest.method, 'POST');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/practiceNotes');
      expect(
        http.lastRequest.jsonBody,
        {
          'practiceId': null,
          'practiceTitle': '새 노트',
          'problemIdList': [1, 2, 3],
        },
      );
      expect(newId, 9);
    });

    // TODO(#174): 실제 버그. lib/Service/Api/PracticeNote/PracticeNoteService.dart:58
    // 반환값을 `as int` 로 캐스팅한다. HttpService 는 응답 본문이 비면(204 혹은 빈 문자열)
    // null 을 돌려주는데, `null as int` 는 TypeError 를 던진다. 등록에 성공했는데
    // 서버가 본문 없이 204 로만 응답하면 클라이언트는 "성공"이 아니라 크래시로 본다.
    test(
      '응답 본문이 비어 있으면(204) TypeError 로 죽는다',
      () async {
        final http = TestHttpClient.respondWith(emptyResponse());
        final model = PracticeNoteRegisterModel(
          practiceTitle: '새 노트',
          registerProblemIdList: [1],
        );
        await buildService(http).registerPracticeNote(model);
      },
      skip: '#174 에서 수정 예정',
    );
  });

  group('addPracticeNoteCount', () {
    test('PATCH /{id}/complete, moodEmojiKey 가 있으면 body 에 포함된다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).addPracticeNoteCount(1, moodEmojiKey: 'happy');

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/practiceNotes/1/complete',
      );
      expect(http.lastRequest.jsonBody, {'moodEmojiKey': 'happy'});
    });

    test('moodEmojiKey 가 없으면 body 없이 요청한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).addPracticeNoteCount(1);

      expect(http.lastRequest.jsonBody, isNull);
    });
  });

  group('updatePracticeNote', () {
    test('PATCH /api/practiceNotes, 모델의 toJson 이 그대로 전송된다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      final model = PracticeNoteUpdateModel(
        practiceNoteId: 1,
        practiceTitle: '수정된 제목',
        addProblemIdList: [4],
        removeProblemIdList: [5],
      );
      await buildService(http).updatePracticeNote(model);

      expect(http.lastRequest.method, 'PATCH');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/practiceNotes');
      expect(
        http.lastRequest.jsonBody,
        {
          'practiceNoteId': 1,
          'practiceTitle': '수정된 제목',
          'addProblemIdList': [4],
          'removeProblemIdList': [5],
        },
      );
    });

    test('실패해도 showErrorSnackBar 기본값(false)으로 스낵바 없이 예외만 던진다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 2002, message: '잘못된 수정'),
      );
      final model = PracticeNoteUpdateModel(
        practiceNoteId: 1,
        addProblemIdList: const [],
        removeProblemIdList: const [],
      );
      await expectLater(
        buildService(http).updatePracticeNote(model),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('deletePracticeNotes', () {
    test('DELETE /api/practiceNotes, 삭제할 id 목록을 body 로 보낸다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).deletePracticeNotes([1, 2, 3]);

      expect(http.lastRequest.method, 'DELETE');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/practiceNotes');
      expect(
        http.lastRequest.jsonBody,
        {
          'deletePracticeIdList': [1, 2, 3]
        },
      );
    });
  });

  group('deleteUserPracticeNotes', () {
    test('DELETE /api/practiceNotes/all', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).deleteUserPracticeNotes();

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/practiceNotes/all',
      );
    });
  });

  group('getPracticeNoteThumbnailsV2', () {
    test('cursor 없이 호출하면 size 만 쿼리로 붙는다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'content': [thumbnailJson],
          'nextCursor': 5,
          'hasNext': true,
          'size': 20,
        }),
      );
      final page = await buildService(http).getPracticeNoteThumbnailsV2();

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/practiceNotes/thumbnail/V2?size=20',
      );
      expect(page.content, hasLength(1));
      expect(page.nextCursor, 5);
      expect(page.hasNext, isTrue);
    });

    test('cursor 를 지정하면 쿼리에 포함된다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'content': <dynamic>[],
          'nextCursor': null,
          'hasNext': false,
          'size': 20,
        }),
      );
      await buildService(http).getPracticeNoteThumbnailsV2(cursor: 7, size: 5);

      expect(http.lastRequest.queryParameters, {'cursor': '7', 'size': '5'});
    });

    // TODO(#174): 실제 버그. lib/Model/Common/PaginatedResponse.dart:23,27,28
    // content/hasNext/size 가 응답에서 빠지면 각각 `as List<dynamic>`, `as bool`,
    // `as int` 캐스팅이 null 을 받아 TypeError 를 던진다. nextCursor 만 `int?` 라
    // 안전하고 나머지 세 필드는 그렇지 않다.
    test(
      'content 가 응답에서 빠지면 TypeError 로 죽는다',
      () async {
        final http = TestHttpClient.respondJson(
          apiEnvelope({'nextCursor': null, 'hasNext': false, 'size': 20}),
        );
        await buildService(http).getPracticeNoteThumbnailsV2();
      },
      skip: '#174 에서 수정 예정',
    );
  });
}
