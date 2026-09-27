import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/Problem/ProblemImageDataRegisterModel.dart';
import 'package:ono/Model/Problem/ProblemRegisterModel.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';

import '../helpers/helpers.dart';

/// ProblemService 가 백엔드와 주고받는 계약을 검증한다.
///
/// MockHttpService 로 sendRequest 를 통째로 stub 하지 않고, 진짜 HttpService 에
/// TestHttpClient 를 주입해서 실제로 나가는 요청(URL, 헤더, 바디)을 확인한다.
void main() {
  setUpOnoTest();

  ProblemService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return ProblemService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  /// ProblemModel.fromJson 이 요구하는 모든 필드를 채운 표준 응답.
  Map<String, dynamic> fullProblemJson({
    int problemId = 7,
    int? folderId = 3,
  }) {
    return {
      'problemId': problemId,
      'folderId': folderId,
      'memo': '한글 메모 확인',
      'reference': '수학의 정석 p.42',
      'solvedAt': '2026-08-01T10:00:00.000Z',
      'lastSolvedAt': '2026-08-02T10:00:00.000Z',
      'createdAt': '2026-07-01T10:00:00.000Z',
      'updatedAt': '2026-07-02T10:00:00.000Z',
      'solveCount': 2,
      'imageUrlList': [
        {
          'imageUrl': 'https://cdn.test/problem1.png',
          'problemImageType': 'PROBLEM_IMAGE',
          'createdAt': '2026-07-01T10:00:00.000Z',
        },
        {
          'imageUrl': 'https://cdn.test/answer1.png',
          'problemImageType': 'ANSWER_IMAGE',
          'createdAt': '2026-07-01T10:00:00.000Z',
        },
      ],
      'analysis': null,
      'tagIdList': [1, 2],
      'tags': [
        {'tagId': 1, 'name': '미적분'},
        {'tagId': 2, 'name': '수열'},
      ],
    };
  }

  group('getProblem', () {
    test('GET /api/problems/{id} 로 요청하고 응답을 ProblemModel 로 매핑한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(fullProblemJson()));

      final problem = await buildService(http).getProblem(7);

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/problems/7');
      expect(http.lastRequest.authorization, 'test-access-token');

      expect(problem.problemId, 7);
      expect(problem.folderId, 3);
      expect(problem.memo, '한글 메모 확인');
      expect(problem.solveCount, 2);
      expect(problem.problemImageDataList, hasLength(1));
      expect(problem.answerImageDataList, hasLength(1));
      expect(problem.tags, hasLength(2));
      expect(problem.tagIdList, [1, 2]);
    });

    test('folderId 가 null 이면 TypeError 로 죽는다 (모델은 int? 인데 fromJson 은 강제 캐스팅)',
        () async {
      // TODO(#174): 실제 버그. lib/Model/Problem/ProblemModel.dart:74
      // `folderId: json['folderId'] as int` — ProblemModel.folderId 필드는 int? 로
      // 선언되어 있는데 fromJson 은 non-null int 로 강제 캐스팅한다. 루트에 바로 등록된
      // 문제 등 folderId 가 null 인 정상적인 응답에서도 앱이 TypeError 로 죽는다.
      final http = TestHttpClient.respondJson(
          apiEnvelope(fullProblemJson(folderId: null)));

      await expectLater(
        buildService(http).getProblem(7, showErrorSnackBar: false),
        completes,
      );
    }, skip: '#174 에서 수정 예정 — 현재는 folderId 가 null 이면 TypeError 로 크래시한다');

    test('problemId 가 응답에 없으면 TypeError 로 죽는다 (ApiException 이 아니다)', () async {
      final json = fullProblemJson()..remove('problemId');
      final http = TestHttpClient.respondJson(apiEnvelope(json));

      await expectLater(
        buildService(http).getProblem(7, showErrorSnackBar: false),
        throwsA(isA<TypeError>()),
      );
    });

    test('상태 코드 400 이면 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, message: '잘못된 요청'),
      );

      await expectLater(
        buildService(http).getProblem(7, showErrorSnackBar: false),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('상태 코드 500 이면 ServerException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      await expectLater(
        buildService(http).getProblem(7, showErrorSnackBar: false),
        throwsA(isA<ServerException>()),
      );
    });

    test('errorCode 가 1000~1999 이면 401 이 아니어도 UnauthorizedException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 1010, message: '토큰 유효하지 않음'),
      );

      await expectLater(
        buildService(http).getProblem(7, showErrorSnackBar: false),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('전송 자체가 실패하면 NetworkException', () async {
      final http = TestHttpClient.throwing(const SocketException('연결 실패'));

      await expectLater(
        buildService(http).getProblem(7, showErrorSnackBar: false),
        throwsA(isA<NetworkException>()),
      );
    });

    test('실패 응답인데 JSON 이 아니면 ParseException', () async {
      final http = TestHttpClient.respondWith(
        textResponse('<html>서버 오류 페이지</html>', statusCode: 500),
      );

      await expectLater(
        buildService(http).getProblem(7, showErrorSnackBar: false),
        throwsA(isA<ParseException>()),
      );
    });

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(fullProblemJson()));

      await expectLater(
        buildService(http, accessToken: null)
            .getProblem(7, showErrorSnackBar: false),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });
  });

  group('getAllProblems', () {
    test('GET /api/problems/user 로 문제 목록을 조회한다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope(
            [fullProblemJson(problemId: 1), fullProblemJson(problemId: 2)]),
      );

      final problems = await buildService(http).getAllProblems();

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/problems/user');
      expect(problems, hasLength(2));
      expect(problems.map((p) => p.problemId), [1, 2]);
    });

    test('빈 배열이면 빈 리스트를 반환한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<dynamic>[]));

      final problems = await buildService(http).getAllProblems();

      expect(problems, isEmpty);
    });
  });

  group('getProblemCount', () {
    test('GET /api/problems/problemCount 로 개수를 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(42));

      final count = await buildService(http).getProblemCount();

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/problemCount',
      );
      expect(count, 42);
    });

    test('204 No Content 이면 null 을 int 로 캐스팅하다 TypeError 로 죽는다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await expectLater(
        buildService(http).getProblemCount(showErrorSnackBar: false),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('registerProblem', () {
    test('POST /api/problems 로 문제를 등록하고 생성된 id 를 받는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(99));

      final model = ProblemRegisterModel(
        memo: '새 문제',
        reference: '기출 3번',
        folderId: 5,
        solvedAt: DateTime.utc(2026, 8, 1),
        imageDataDtoList: [
          ProblemImageDataRegisterModel(
            problemId: null,
            imageUrl: 'https://cdn.test/1.png',
            problemImageType: ProblemImageType.PROBLEM_IMAGE,
          ),
        ],
        tagIds: [1, 2],
      );

      final id = await buildService(http).registerProblem(model);

      expect(http.lastRequest.method, 'POST');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/problems');
      expect(http.lastRequest.contentType, contains('application/json'));
      final body = http.lastRequest.jsonBody!;
      expect(body['memo'], '새 문제');
      expect(body['folderId'], 5);
      expect(body['tagIds'], [1, 2]);
      expect(
        (body['imageDataDtoList'] as List).first['problemImageType'],
        'PROBLEM_IMAGE',
      );
      expect(id, 99);
    });
  });

  group('registerProblemV2', () {
    test('POST /api/problems/v2 로 문제를 등록한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(12));
      final solvedAt = DateTime.utc(2026, 8, 1, 12);

      final id = await buildService(http).registerProblemV2(
        memo: '새 문제',
        reference: '기출',
        folderId: 3,
        solvedAt: solvedAt,
        problemImageUrls: const ['https://cdn.test/1.png'],
        answerImageUrls: const ['https://cdn.test/2.png'],
        tagIds: const [4, 5],
      );

      expect(http.lastRequest.method, 'POST');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/problems/v2');
      final body = http.lastRequest.jsonBody!;
      expect(body['folderId'], 3);
      expect(body['solvedAt'], solvedAt.toIso8601String());
      expect(body['problemImageUrls'], ['https://cdn.test/1.png']);
      expect(body['answerImageUrls'], ['https://cdn.test/2.png']);
      expect(body['tagIds'], [4, 5]);
      expect(id, 12);
    });

    test('problemId, tagIds 등 옵션 필드가 없으면 null 로 보낸다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(1));

      await buildService(http).registerProblemV2(
        folderId: 1,
        problemImageUrls: const [],
        answerImageUrls: const [],
      );

      final body = http.lastRequest.jsonBody!;
      expect(body['problemId'], isNull);
      expect(body['tagIds'], isNull);
      expect(body['memo'], isNull);
    });
  });

  group('registerProblemsBatchV2', () {
    test('POST /api/problems/v2/batch 로 여러 문제를 한 번에 등록한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope([1, 2, 3]));

      final ids = await buildService(http).registerProblemsBatchV2(
        problems: [
          {'folderId': 1, 'memo': '문제1'},
          {'folderId': 1, 'memo': '문제2'},
        ],
      );

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/v2/batch',
      );
      expect(
        (http.lastRequest.jsonBody!['problems'] as List).length,
        2,
      );
      expect(ids, [1, 2, 3]);
    });
  });

  group('requestProblemAnalysis', () {
    test('POST /api/problems/{id}/analysis 로 분석을 요청한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).requestProblemAnalysis(7);

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/7/analysis',
      );
    });

    test('500 이면 ServerException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '분석 서버 오류'),
      );

      await expectLater(
        buildService(http).requestProblemAnalysis(7, showErrorSnackBar: false),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('registerProblemImageData', () {
    late File tempImage;

    setUp(() {
      tempImage = File(
        '${Directory.systemTemp.path}/ono_test_problem_image_${DateTime.now().microsecondsSinceEpoch}.png',
      )..writeAsBytesSync([1, 2, 3, 4]);
    });

    tearDown(() {
      if (tempImage.existsSync()) tempImage.deleteSync();
    });

    test('multipart POST 로 이미지와 타입을 함께 전송한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).registerProblemImageData(
        problemId: 7,
        problemImages: [tempImage],
        problemImageTypes: const ['PROBLEM_IMAGE'],
      );

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/7/imageData',
      );
      expect(http.lastRequest.contentType, contains('multipart/form-data'));
      // 서버의 @RequestParam 이름과 일치해야 한다.
      expect(http.lastRequest.body, contains('name="problemImages"'));
      expect(http.lastRequest.body, contains('name="problemImageTypes"'));
      expect(http.lastRequest.body, contains('PROBLEM_IMAGE'));
    });
  });

  group('updateProblemAnalysisStatus', () {
    test('PATCH /api/problems/{id}/no-image', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).updateProblemAnalysisStatus(problemId: 7);

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/7/no-image',
      );
    });
  });

  group('updateProblemInfo / updateProblemPath / updateProblemImageData', () {
    final model = ProblemRegisterModel(
      problemId: 7,
      memo: '수정된 메모',
      folderId: 2,
    );

    test('updateProblemInfo 는 PATCH /api/problems/info', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).updateProblemInfo(model);

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/info',
      );
      expect(http.lastRequest.jsonBody!['memo'], '수정된 메모');
    });

    test('updateProblemPath 는 PATCH /api/problems/path', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).updateProblemPath(model);

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/path',
      );
    });

    test('updateProblemImageData 는 PATCH /api/problems/imageData', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).updateProblemImageData(model);

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/imageData',
      );
    });
  });

  group('deleteProblems / deleteUserProblems / deleteProblemImageData', () {
    test('deleteProblems 는 DELETE /api/problems, 바디에 삭제할 id 목록을 담는다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).deleteProblems([1, 2, 3]);

      expect(http.lastRequest.method, 'DELETE');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/problems');
      expect(http.lastRequest.jsonBody!['deleteProblemIdList'], [1, 2, 3]);
    });

    test('deleteUserProblems 는 DELETE /api/problems/all', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).deleteUserProblems();

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/all',
      );
    });

    test('deleteProblemImageData 는 쿼리 파라미터로 imageUrl 을 전달한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http)
          .deleteProblemImageData('https://cdn.test/1.png?x=1');

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        startsWith('$testBaseUrl/api/problems/imageData'),
      );
      expect(
        http.lastRequest.queryParameters['imageUrl'],
        'https://cdn.test/1.png?x=1',
      );
    });
  });

  group('getProblemAnalysis', () {
    test('GET /api/problems/{id}/analysis 로 분석 결과를 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope({
        'id': 1,
        'problemId': 7,
        'subject': '미적분',
        'problemType': '계산',
        'keyPoints': ['치환적분'],
        'solution': '풀이',
        'commonMistakes': '부호 실수',
        'studyTips': '검산 습관',
        'status': 'COMPLETED',
        'errorMessage': null,
      }));

      final analysis = await buildService(http).getProblemAnalysis(7);

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/7/analysis',
      );
      expect(analysis.subject, '미적분');
      expect(analysis.status.toString(), contains('COMPLETED'));
    });

    test('status 값이 서버가 새로 추가한 미지의 문자열이면 조용히 null 로 사라진다', () async {
      // 계약 위험: 백엔드가 새 상태값을 추가해도 앱은 예외 없이 null 로 삼켜서
      // 화면에서 분석 상태가 원인 불명으로 사라질 수 있다.
      final http = TestHttpClient.respondJson(apiEnvelope({
        'id': 1,
        'problemId': 7,
        'status': 'RETRYING', // 클라이언트가 모르는 새 상태값
      }));

      final analysis = await buildService(http).getProblemAnalysis(7);

      expect(analysis.status, isNull);
    });
  });

  group('getFolderProblemsV2 / getTagProblemsV2 / getTitleProblemsV2', () {
    Map<String, dynamic> page() => {
          'content': [fullProblemJson(problemId: 1)],
          'nextCursor': 10,
          'hasNext': true,
          'size': 1,
        };

    test('getFolderProblemsV2: cursor 가 없으면 size 만 쿼리로 보낸다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(page()));

      final result =
          await buildService(http).getFolderProblemsV2(folderId: 3, size: 20);

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/folder/3/V2?size=20',
      );
      expect(result.content, hasLength(1));
      expect(result.nextCursor, 10);
      expect(result.hasNext, isTrue);
    });

    test('getFolderProblemsV2: cursor 가 있으면 cursor 와 size 를 함께 보낸다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(page()));

      await buildService(http)
          .getFolderProblemsV2(folderId: 3, cursor: 5, size: 10);

      expect(http.lastRequest.queryParameters['cursor'], '5');
      expect(http.lastRequest.queryParameters['size'], '10');
    });

    test('getTagProblemsV2: GET /api/problems/tag/{id}/V2', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(page()));

      await buildService(http).getTagProblemsV2(tagId: 9, cursor: 1, size: 5);

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/tag/9/V2?size=5&cursor=1',
      );
    });

    test('getTitleProblemsV2: query 파라미터를 함께 보낸다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(page()));

      await buildService(http)
          .getTitleProblemsV2(query: '적분', cursor: 2, size: 5);

      expect(http.lastRequest.queryParameters['query'], '적분');
      expect(http.lastRequest.queryParameters['cursor'], '2');
      expect(http.lastRequest.queryParameters['size'], '5');
    });

    test('hasNext 필드가 응답에서 빠지면 TypeError 로 죽는다', () async {
      final broken = page()..remove('hasNext');
      final http = TestHttpClient.respondJson(apiEnvelope(broken));

      await expectLater(
        buildService(http).getFolderProblemsV2(folderId: 3),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('getReviewDueProblems', () {
    test('GET /api/problems/review-due 로 복습 대상 목록을 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope({
        'dueCount': 2,
        'overdueCount': 1,
        'problems': [
          {
            'problemId': 1,
            'memo': '복습할 문제',
            'reference': null,
            'nextReviewAt': '2026-09-03T00:00:00.000Z',
            'reviewInterval': 3,
            'consecutiveCorrectCount': 2,
          },
        ],
      }));

      final response = await buildService(http).getReviewDueProblems();

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problems/review-due',
      );
      expect(response.dueCount, 2);
      expect(response.overdueCount, 1);
      expect(response.problems, hasLength(1));
      expect(response.problems.first.problemId, 1);
    });

    test('dueCount, problems 가 응답에서 빠져도 기본값(0, 빈 리스트)으로 방어된다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<String, dynamic>{}));

      final response = await buildService(http).getReviewDueProblems();

      expect(response.dueCount, 0);
      expect(response.overdueCount, 0);
      expect(response.problems, isEmpty);
    });
  });
}
