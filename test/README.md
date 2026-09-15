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

---

# 골든 테스트 규약 (3차)

위젯 테스트는 무엇이 몇 개 그려지는지와 넘치지 않는지를 본다. 패딩이나 색이 바뀌어도
레이아웃 제약만 안 깨지면 통과한다. 골든 테스트는 화면을 PNG 로 떠 두고 다음 실행에서
픽셀을 비교해서, **어제와 달라졌는지**를 잡는다. "보기 좋은가"는 여전히 사람이 본다.

도구는 [alchemist](https://pub.dev/packages/alchemist) 를 쓴다. 기준으로 삼을 파일은
`test/screen/achievement/achievement_screen_golden_test.dart` 다.

## 이미지가 두 벌 나온다

| 경로 | 글자 | 커밋 | 쓰임 |
|---|---|---|---|
| `goldens/ci/` | 네모로 가림 | 한다 | CI 가 비교한다 |
| `goldens/macos/` (로컬 OS 이름) | 진짜 폰트 | 안 한다 | 로컬에서 눈으로 확인한다 |

글자를 가리는 이유는 **폰트 렌더링이 OS 마다 달라서**다. 로컬(macOS)에서 진짜 폰트로 뜬
이미지는 CI(Ubuntu)에서 반드시 어긋난다. 가린 이미지는 OS 와 상관없이 거의 같게 나온다.

"거의"라서 CI 비교에는 0.2% 허용치가 있다. 글자를 1.6배로 키우면 진행 막대 끝 같은
테두리가 OS 마다 1px 안쪽으로 다르게 번지기 때문이다(실측 0.07%). 설정은
`test/flutter_test_config.dart` 에 있다.

## 쓰는 법

```dart
void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '훈장 화면',
    fileName: 'achievement_screen',
    buildApp: () async => buildOnoApp(
      const AchievementScreen(),
      cosmeticProvider: await loadedCosmeticProvider(),
      achievementProvider: AchievementProvider(service: fakeService, store: fakeStore),
    ),
  );
}
```

- **파일은 위젯 테스트 옆에 `<대상>_golden_test.dart` 로 둔다.** 이미지는 그 옆
  `goldens/` 에 생긴다.
- **`buildApp` 은 `buildOnoApp` 으로 만든다.** `pumpOnoWidget` 과 같은 Provider 트리다.
  화면이 읽는 Provider 는 가짜 서비스를 물려서 넘기는 규칙도 같다.
- **크기는 기본으로 네 벌이다.** `GoldenSurface.all` (작은 폰, 폰, 폰 글자 1.6배, 태블릿).
  넘치는지는 위젯 테스트의 `크기` 그룹이 이미 보고 있으니, 생김새만 잠그면 되는 화면은
  `surfaces: GoldenSurface.layouts` (폰, 태블릿) 로 줄인다. 작은 폰과 큰 글씨에서의
  배치 자체가 약속인 화면(훈장, 옷장, 캐릭터)만 네 벌을 뜬다.
- **네트워크 그림은 비워 둔다.** 골든을 비교하는 동안 진짜 비동기가 흐르는데, 그때
  `CachedNetworkImage` 가 캐시 폴더를 찾다가 `MissingPluginException` 으로 깨진다.
  그림을 비우면 기본 그림이 들어가서 카드의 틀은 똑같이 잠긴다.
- **서비스를 주입할 수 없어 HTTP 를 가로채야 하는 화면은 `runWith:` 로 넘긴다.**
  기본값인 `withMockedNetworkImages` 와 같은 `HttpOverrides` 라 겹쳐 쓰면 안쪽 것만
  먹는다. `tag_selection_screen_golden_test.dart` 가 예다.
- **동작 줄이기가 켜진 채로 뜬다.** 연출 중간 프레임이 찍히면 매번 다른 이미지가 나온다.
  시간이 흐르는 알림(축하 토스트 등)도 끄고 뜬다.
- **날짜나 랜덤처럼 실행마다 달라지는 값은 픽스처로 고정한다.** 안 그러면 매일 깨진다.
  화면이 `DateTime.now()` 로 문구를 만들면 픽스처로는 못 막는다. `MissionHistoryScreen`
  처럼 `clock` 을 받는 화면만 골든을 뜬다.

## 아직 골든이 없는 화면

위젯 테스트는 있지만 골든을 뜨지 않은 화면과 그 이유다. 날짜와 플랫폼에 매인 화면은 #222 에서 다룬다.

| 화면 | 이유 |
|---|---|
| `SplashScreen` | 글씨를 쓰는 연출이 끝나면 다음 화면으로 넘어가서, 멈춰 있는 모습이 없다 |
| `LoginScreen` | Apple 로그인 버튼이 `Platform.isIOS || isMacOS` 로 갈려서 로컬(macOS)과 CI(Linux) 이미지가 다르다 |
| `StudyRoomListScreen`, `StudyRoomDetailScreen` | 공유 문제 카드가 `DateTime.now()` 로 `N일 전` 을 만든다 |
| `MyPageScreen` | 스트릭 카드가 `DateTime.now()` 로 이번 달 달력을 그린다 |
| `PracticeTitleWriteScreen` | 알림 시각 기본값이 지금 시각이다 |

## 기준 이미지를 다시 뜰 때

화면을 **일부러** 바꿨으면 기준 이미지도 같이 바꿔서 같은 PR 에 올린다.

```
flutter test --update-goldens test/screen/achievement/achievement_screen_golden_test.dart
```

- **파일을 지정해서 돌린다.** 전체에 `--update-goldens` 를 걸면 의도하지 않은 화면의
  이미지까지 조용히 덮어써서 비교하는 의미가 없어진다.
- **커밋 전에 `goldens/macos/` 이미지를 열어서 눈으로 본다.** 가린 이미지로는 글자가
  잘렸는지 알 수 없다.
- **PR diff 에서 바뀐 PNG 를 확인한다.** GitHub 은 이미지 diff 를 나란히 보여준다.

## CI 에서 깨졌을 때

1. Actions 실행 페이지 아래 **Artifacts 의 `golden-failures`** 를 받는다.
2. `*_isolatedDiff.png` 가 달라진 픽셀만, `*_maskedDiff.png` 가 원본 위에 달라진 곳을
   표시한 것이다.
3. 의도한 변경이면 위 방법으로 기준 이미지를 다시 뜨고, 아니면 코드를 고친다.

골든만 돌리거나 빼고 돌릴 수 있다. 태그는 `dart_test.yaml` 에 있다.

```
flutter test --tags golden
flutter test --exclude-tags golden
```
