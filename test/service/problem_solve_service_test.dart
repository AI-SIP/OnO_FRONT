import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Model/Problem/ImprovementType.dart';
import 'package:ono/Model/Problem/ProblemSolveRegisterDto.dart';
import 'package:ono/Model/Problem/ProblemSolveUpdateDto.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/Problem/ProblemSolveService.dart';

import '../helpers/helpers.dart';

/// ProblemSolveService 가 백엔드와 주고받는 계약을 검증한다.
void main() {
  setUpOnoTest();

  ProblemSolveService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return ProblemSolveService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  Map<String, dynamic> fullSolveJson(
      {int problemSolveId = 1, int problemId = 7}) {
    return {
      'problemSolveId': problemSolveId,
      'problemId': problemId,
      'userId': 100,
      'practicedAt': '2026-08-01T10:00:00.000Z',
      'answerStatus': 'CORRECT',
      'reflection': '이번엔 잘 풀었다',
      'improvements': ['NO_REPEAT_MISTAKE', 'FASTER_SOLVING'],
      'timeSpentSeconds': 120,
      'migratedFromLegacy': false,
      'imageUrls': ['https://cdn.test/solve1.png'],
      'createdAt': '2026-08-01T10:00:00.000Z',
      'updatedAt': '2026-08-01T10:05:00.000Z',
    };
  }

  group('getProblemSolve', () {
    test('GET /api/problem-solves/{id} 로 복습 기록을 조회한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(fullSolveJson()));

      final solve = await buildService(http).getProblemSolve(1);

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problem-solves/1',
      );
      expect(http.lastRequest.authorization, 'test-access-token');
      expect(solve.problemSolveId, 1);
      expect(solve.answerStatus, AnswerStatus.CORRECT);
      expect(solve.improvements, [
        ImprovementType.NO_REPEAT_MISTAKE,
        ImprovementType.FASTER_SOLVING,
      ]);
      expect(solve.reflection, '이번엔 잘 풀었다');
    });

    test('problemSolveId 가 응답에 없으면 TypeError 로 죽는다', () async {
      final json = fullSolveJson()..remove('problemSolveId');
      final http = TestHttpClient.respondJson(apiEnvelope(json));

      await expectLater(
        buildService(http).getProblemSolve(1),
        throwsA(isA<TypeError>()),
      );
    });

    test('answerStatus 가 서버가 새로 추가한 미지의 문자열이면 UNKNOWN 으로 대체된다', () async {
      final json = fullSolveJson()..['answerStatus'] = 'RETRIED';
      final http = TestHttpClient.respondJson(apiEnvelope(json));

      final solve = await buildService(http).getProblemSolve(1);

      expect(solve.answerStatus, AnswerStatus.UNKNOWN);
    });

    test('improvements 에 미지의 문자열이 섞이면 조용히 NO_REPEAT_MISTAKE 로 대체된다', () async {
      // 계약 위험: 백엔드가 개선 유형을 추가해도 예외 없이 기존 값으로 둔갑한다.
      // 사용자에게는 실제로 선택하지 않은 항목이 선택된 것처럼 보일 수 있다.
      final json = fullSolveJson()..['improvements'] = ['SOME_NEW_TYPE'];
      final http = TestHttpClient.respondJson(apiEnvelope(json));

      final solve = await buildService(http).getProblemSolve(1);

      expect(solve.improvements, [ImprovementType.NO_REPEAT_MISTAKE]);
    });

    test('400 이면 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, message: '잘못된 요청'),
      );

      await expectLater(
        buildService(http).getProblemSolve(1),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('500 이면 ServerException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );

      await expectLater(
        buildService(http).getProblemSolve(1),
        throwsA(isA<ServerException>()),
      );
    });

    test('전송 자체가 실패하면 NetworkException', () async {
      final http = TestHttpClient.throwing(const SocketException('연결 실패'));

      await expectLater(
        buildService(http).getProblemSolve(1),
        throwsA(isA<NetworkException>()),
      );
    });

    test('성공 응답인데 JSON 이 아니면 원본 텍스트를 그대로 반환한다 (모델 캐스팅에서 TypeError)', () async {
      final http = TestHttpClient.respondWith(textResponse('OK'));

      await expectLater(
        buildService(http).getProblemSolve(1),
        throwsA(isA<TypeError>()),
      );
    });

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(fullSolveJson()));

      await expectLater(
        buildService(http, accessToken: null).getProblemSolve(1),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });
  });

  group('getProblemSolvesByProblemId', () {
    test('GET /api/problem-solves/problem/{problemId} 로 목록을 조회한다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope([
          fullSolveJson(problemSolveId: 1),
          fullSolveJson(problemSolveId: 2)
        ]),
      );

      final solves = await buildService(http).getProblemSolvesByProblemId(7);

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problem-solves/problem/7',
      );
      expect(solves, hasLength(2));
    });

    test('빈 배열이면 빈 리스트를 반환한다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<dynamic>[]));

      final solves = await buildService(http).getProblemSolvesByProblemId(7);

      expect(solves, isEmpty);
    });
  });

  group('getUserProblemSolves', () {
    test('GET /api/problem-solves/user 로 사용자 전체 기록을 조회한다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope([fullSolveJson()]),
      );

      final solves = await buildService(http).getUserProblemSolves();

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problem-solves/user',
      );
      expect(solves, hasLength(1));
    });
  });

  group('getProblemSolveCountByProblemId / getUserProblemSolveCount', () {
    test(
        'getProblemSolveCountByProblemId 는 GET /api/problem-solves/problem/{id}/count',
        () async {
      final http = TestHttpClient.respondJson(apiEnvelope(3));

      final count = await buildService(http).getProblemSolveCountByProblemId(7);

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problem-solves/problem/7/count',
      );
      expect(count, 3);
    });

    test('getUserProblemSolveCount 는 GET /api/problem-solves/user/count',
        () async {
      final http = TestHttpClient.respondJson(apiEnvelope(10));

      final count = await buildService(http).getUserProblemSolveCount();

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problem-solves/user/count',
      );
      expect(count, 10);
    });

    test('204 No Content 이면 null 을 int 로 캐스팅하다 TypeError 로 죽는다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await expectLater(
        buildService(http).getUserProblemSolveCount(),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('createProblemSolve', () {
    test('POST /api/problem-solves 로 복습 기록을 생성하고 id 를 받는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(55));
      final practicedAt = DateTime.utc(2026, 8, 1, 9);

      final dto = ProblemSolveRegisterDto(
        problemId: 7,
        practicedAt: practicedAt,
        answerStatus: AnswerStatus.WRONG,
        reflection: '실수를 반복함',
        improvements: const [ImprovementType.BETTER_UNDERSTANDING],
        timeSpentSeconds: 90,
      );

      final id = await buildService(http).createProblemSolve(dto);

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problem-solves',
      );
      expect(http.lastRequest.contentType, contains('application/json'));
      final body = http.lastRequest.jsonBody!;
      expect(body['problemId'], 7);
      expect(body['practicedAt'], practicedAt.toIso8601String());
      expect(body['answerStatus'], 'WRONG');
      expect(body['improvements'], ['BETTER_UNDERSTANDING']);
      expect(body['timeSpentSeconds'], 90);
      expect(id, 55);
    });
  });

  group('uploadProblemSolveImages', () {
    late File tempImage;

    setUp(() {
      tempImage = File(
        '${Directory.systemTemp.path}/ono_test_solve_image_${DateTime.now().microsecondsSinceEpoch}.png',
      )..writeAsBytesSync([5, 6, 7, 8]);
    });

    tearDown(() {
      if (tempImage.existsSync()) tempImage.deleteSync();
    });

    test('multipart POST 로 이미지를 전송한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).uploadProblemSolveImages(
        problemSolveId: 1,
        images: [tempImage],
      );

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problem-solves/1/images',
      );
      expect(http.lastRequest.contentType, contains('multipart/form-data'));
      // 서버의 @RequestParam 이름과 일치해야 한다.
      expect(http.lastRequest.body, contains('name="images"'));
    });
  });

  group('updateProblemSolve', () {
    test('PATCH /api/problem-solves 로 복습 기록을 수정한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      final dto = ProblemSolveUpdateDto(
        problemSolveId: 1,
        answerStatus: AnswerStatus.PARTIAL,
        reflection: '절반만 맞음',
        improvements: const [ImprovementType.FOUND_NEW_SOLUTION],
        timeSpentSeconds: 30,
      );

      await buildService(http).updateProblemSolve(dto);

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problem-solves',
      );
      final body = http.lastRequest.jsonBody!;
      expect(body['problemSolveId'], 1);
      expect(body['answerStatus'], 'PARTIAL');
      expect(body['improvements'], ['FOUND_NEW_SOLUTION']);
    });
  });

  group('deleteProblemSolve', () {
    test('DELETE /api/problem-solves/{id} 로 복습 기록을 삭제한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());

      await buildService(http).deleteProblemSolve(1);

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/problem-solves/1',
      );
    });

    test('404(errorCode 없이) 면 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 404, message: '복습 기록을 찾을 수 없습니다'),
      );

      await expectLater(
        buildService(http).deleteProblemSolve(1),
        throwsA(isA<BadRequestException>()),
      );
    });
  });
}
