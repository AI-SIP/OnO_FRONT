# 테스트 작성 규약

## 디렉토리

| 경로 | 무엇을 넣나 |
|---|---|
| `test/helpers/` | 공용 헬퍼. 여기부터 읽는다 |
| `test/fixtures/` | 백엔드 응답을 떠 온 JSON |
| `test/model/` | Model 의 `fromJson` / `toJson` |
| `test/service/` | Service 의 요청 형태와 응답 매핑 |
| `test/provider/` | Provider 의 상태 전이 |
| `test/util/` | Util, Exception 등 |

파일명은 `<대상 파일 스네이크케이스>_test.dart` 로 짓는다.
`lib/Model/Problem/ProblemModel.dart` → `test/model/problem/problem_model_test.dart`.

## 모든 테스트 파일의 시작

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();   // 반드시 첫 줄. 없으면 Service 생성만으로 터진다

  group('...', () { ... });
}
```

`setUpOnoTest()` 가 `AppConfig.loadForTest()` 를 불러 `baseUrl` 을 채운다.
Service 들이 필드 초기화 시점에 `AppConfig.baseUrl` 을 읽기 때문에, 이게 없으면
Service 를 만드는 것만으로 `LateInitializationError` 가 난다.

## Service 테스트는 mock 이 아니라 가짜 HTTP 응답으로 한다

`MockHttpService` 로 `sendRequest` 를 통째로 stub 하면 URL 도 헤더도 바디도 검증되지
않는다. 그러면 백엔드와 어긋나도 테스트는 통과한다. 진짜 `HttpService` 에
`TestHttpClient` 를 넣어서 실제로 나가는 요청을 본다.

```dart
final http = TestHttpClient.respondJson(apiEnvelope({'problemId': 7}));
final service = ProblemService(
  httpService: HttpService(
    client: http.client,
    tokenProvider: buildMockTokenProvider(),
  ),
);

final problem = await service.getProblem(7);

expect(http.lastRequest.method, 'GET');
expect(http.lastRequest.url.toString(), '$testBaseUrl/api/problems/7');
expect(http.lastRequest.authorization, 'test-access-token');
expect(problem.problemId, 7);
```

`TestHttpClient` 에는 이런 것들이 있다.

| 생성자 | 언제 |
|---|---|
| `respondJson(body, statusCode:)` | 모든 요청에 같은 JSON |
| `respondWith(response)` | 모든 요청에 같은 응답 |
| `sequence([r1, r2])` | 호출마다 다른 응답. 401 뒤 재시도 검증 |
| `handler((req) async => ...)` | 요청 내용에 따라 분기 |
| `throwing(error)` | `SocketException` 등 전송 실패 |

응답 빌더는 `jsonResponse`, `emptyResponse`, `textResponse`, `errorResponse`,
그리고 서버 래퍼를 씌우는 `apiEnvelope` 가 있다.

**`http.Response` 를 직접 만들지 않는다.** package:http 는 content-type 에 charset 이
없으면 latin1 으로 인코딩해서 한글이 깨진다. `jsonResponse` 는 utf-8 을 박아 준다.

## Provider 테스트는 Service 를 mock 한다

Provider 는 상태 전이가 관심사라 HTTP 까지 태울 필요가 없다.

```dart
final service = MockProblemService();
when(() => service.getProblem(any())).thenAnswer((_) async => problem);

final provider = ProblemsProvider(problemService: service);
final notified = NotifyRecorder();
provider.addListener(notified.call);

await provider.fetchProblem(7);

expect(provider.problems, hasLength(1));
expect(notified.count, greaterThan(0));
```

`notifyListeners` 가 불렸는지는 `NotifyRecorder` 로 센다. 화면이 갱신되지 않는 버그는
대개 여기가 빠져서 생긴다.

## 무엇을 보나

- **Model**: null 인 필드, 아예 없는 키, 타입이 다른 값(`int` 자리에 `String`),
  날짜 문자열 파싱, 빈 배열, `toJson` 이 서버가 받는 키 이름과 맞는지.
- **Service**: 메서드와 URL, 쿼리 파라미터, 헤더, 바디, 응답 매핑,
  상태 코드와 errorCode 별 예외 타입, 빈 응답(204).
- **Provider**: 초기 상태, 성공 후 상태, 실패 후 상태(예외를 삼키는지 던지는지),
  `notifyListeners` 호출, 캐시와 페이지네이션 커서.

## lib/ 은 고치지 않는다

테스트를 쓰다 프로덕션 버그를 찾으면 **고치지 말고 기록한다.** 실패하는 테스트를
남겨 두면 다른 사람이 CI 가 왜 빨간지 알 수 없으므로, 그 케이스는 주석으로
`// TODO(#174): 실제 버그. <파일:라인> 에서 <무슨 일>` 을 달고 `skip:` 처리한 뒤
발견 내용을 보고한다.
