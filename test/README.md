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

---

# 위젯 테스트 규약 (2차)

## 시작

```dart
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();   // 반드시 첫 줄

  testWidgets('...', (tester) async {
    await pumpOnoWidget(tester, const SomeScreen());
  });
}
```

`setUpOnoWidgetTest()` 는 `setUpOnoTest()` 가 하는 일에 더해 FirebaseAnalytics 와
FlutterSecureStorage 플랫폼 델리게이트를 가짜로 바꿔 끼운다. 이게 없으면
`ThemeHandler` 가 생성자에서 색상을 읽다가 `MissingPluginException` 으로 죽는다.

기준으로 삼을 파일은 `test/screen/user/login_screen_test.dart` 다.

## Provider 는 화면이 읽는 것만 넘긴다

`pumpOnoWidget` 은 넘기지 않은 Provider 를 진짜 구현으로 만든다. 그 안에서 진짜
Service 가 만들어지므로, **화면이 실제로 읽는 Provider 는 반드시 넘겨야 한다.**

두 가지 방법이 있고 상황에 따라 고른다.

| 방법 | 언제 |
|---|---|
| mock 서비스를 물린 **진짜 Provider** | 상태 전이까지 같이 보고 싶을 때. 대체로 이쪽이 낫다 |
| **mock Provider** (`Mock implements XProvider`) | 화면이 특정 상태일 때의 그림만 볼 때 |

mock Provider 를 쓰면 `addListener` / `removeListener` / `dispose` 를 반드시
stub 해야 한다. `ChangeNotifierProvider` 가 구독할 때 부른다.

```dart
when(() => userProvider.addListener(any())).thenReturn(null);
when(() => userProvider.removeListener(any())).thenReturn(null);
when(() => userProvider.dispose()).thenReturn(null);
```

## 화면 크기

`OnoSurface.phone`(기본) / `smallPhone` / `tablet` 이 있다. 폰과 태블릿이 모두
1차 환경이라, **레이아웃이 분기하는 화면은 두 크기 모두 확인한다.** 앱은 폭 600 을
기준으로 갈린다.

```dart
await pumpOnoWidget(tester, const SomeScreen(), surfaceSize: OnoSurface.tablet);
expect(tester.takeException(), isNull);
```

## 네트워크 이미지

`CachedNetworkImage` 나 `Image.network` 를 그리는 화면은 `withMockedNetworkImages` 로
감싼다. 안 감싸면 이미지 로더가 400 을 받아 테스트가 깨진다.

```dart
await withMockedNetworkImages(() async {
  await pumpOnoWidget(tester, const SomeScreen());
});
```

## SVG 는 그대로 로드된다

`assets/` 아래 SVG 는 테스트에서도 실제로 읽힌다. 다만 화면 하나에 `SvgPicture` 가
여러 개인 경우가 많으니 타입으로 찾지 말고 에셋 경로로 찾는다.

```dart
Finder svgAsset(String path) => find.byWidgetPredicate(
      (w) =>
          w is SvgPicture &&
          w.bytesLoader is SvgAssetLoader &&
          (w.bytesLoader as SvgAssetLoader).assetName == path,
    );
```

## pumpAndSettle 이 타임아웃날 때

끝나지 않는 애니메이션(로딩 인디케이터 등)이 있는 화면은 `settle: false` 로 띄우고
`tester.pump(Duration(...))` 으로 직접 진행시킨다.

```dart
await pumpOnoWidget(tester, const SomeScreen(), settle: false);
await tester.pump(const Duration(milliseconds: 100));
```

## 무엇을 보나

화면당 5~15 케이스를 목표로 한다.

- **상태별 그림**: 빈 상태, 로딩, 에러, 정상. 각각에서 무엇이 보이고 무엇이 안 보이는지
- **상호작용**: 주요 버튼 탭 → 무슨 일이 일어나는지 (Provider 메서드 호출, 화면 전환, 다이얼로그)
- **폼**: 입력 검증, 빈 값, 길이 초과, 잘못된 형식
- **조건부 표시**: 권한·소유권·상태에 따라 버튼이 보이거나 숨는지
- **반응형**: 폰과 태블릿에서 예외 없이 그려지는지

화면 전환은 `NavigatorObserver` mock 을 `navigatorObservers` 로 넘겨 `didPush` 가
불렸는지 본다.
