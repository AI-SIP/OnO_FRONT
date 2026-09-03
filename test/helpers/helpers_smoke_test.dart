import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';

import 'helpers.dart';

/// 테스트 인프라 자체가 도는지 확인하는 스모크 테스트.
/// 여기가 깨지면 다른 테스트의 실패는 전부 헬퍼 문제일 수 있으니 여기부터 본다.
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

  test('AppConfig.loadForTest 가 baseUrl 을 채운다', () {
    expect(testBaseUrl, 'https://test.ono.local');
  });

  test('요청을 기록하고 응답을 파싱한다', () async {
    final http = TestHttpClient.respondJson(
      apiEnvelope({
        'problemId': 7,
        'folderId': 3,
        'memo': '메모 한글 확인',
        'solveCount': 2,
      }),
    );

    final problem = await buildService(http).getProblem(7);

    expect(http.callCount, 1);
    expect(http.lastRequest.method, 'GET');
    expect(http.lastRequest.url.toString(), '$testBaseUrl/api/problems/7');
    expect(http.lastRequest.authorization, 'test-access-token');

    expect(problem.problemId, 7);
    // 한글이 깨지지 않는지. jsonResponse 가 charset=utf-8 을 박지 않으면 여기서 깨진다.
    expect(problem.memo, '메모 한글 확인');
    expect(problem.solveCount, 2);
  });

  test('POST 바디가 그대로 전달된다', () async {
    final http = TestHttpClient.respondJson(apiEnvelope(12));

    await buildService(http).registerProblemV2(
      folderId: 3,
      memo: '새 문제',
      problemImageUrls: const ['https://cdn.test/1.png'],
      answerImageUrls: const [],
    );

    expect(http.lastRequest.method, 'POST');
    expect(http.lastRequest.contentType, contains('application/json'));
    expect(http.lastRequest.jsonBody, containsPair('folderId', 3));
  });

  test('상태 코드에 따라 예외 타입이 갈린다', () async {
    final http = TestHttpClient.respondWith(
      errorResponse(statusCode: 500, message: '서버 오류'),
    );

    await expectLater(
      buildService(http).getProblem(1, showErrorSnackBar: false),
      throwsA(isA<ServerException>()),
    );
  });

  test('토큰이 없으면 요청을 보내지 않고 UnauthorizedException 을 던진다', () async {
    final http = TestHttpClient.respondJson(apiEnvelope(null));

    await expectLater(
      buildService(http, accessToken: null)
          .getProblem(1, showErrorSnackBar: false),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(http.callCount, 0);
  });

  test('sequence 로 호출마다 다른 응답을 줄 수 있다', () async {
    final http = TestHttpClient.sequence([
      errorResponse(statusCode: 401, errorCode: 1005, message: '토큰 만료'),
      jsonResponse(apiEnvelope({'problemId': 1, 'folderId': 1})),
    ]);

    final problem =
        await buildService(http).getProblem(1, showErrorSnackBar: false);

    // 401(1005) 을 받고 토큰을 갱신한 뒤 한 번 더 요청한다.
    expect(http.callCount, 2);
    expect(problem.problemId, 1);
  });
}
