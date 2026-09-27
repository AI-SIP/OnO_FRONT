# E2E 테스트

진짜 앱을 시뮬레이터에 띄워 백엔드에 붙이고, 사람이 누르는 순서대로 동선을 끝까지 따라간다.
위젯 테스트(`test/`)는 화면 하나를 가짜 서버로 보고, 여기서는 **화면들이 진짜 서버를 거쳐
이어지는지**를 본다.

느리고 잘 깨지기 때문에 **"이게 안 되면 앱이 망가진 것" 인 동선만** 넣는다. 스무 개가 넘으면
아무도 안 고치고 방치된다.

| 파일 | 동선 | 서버에 쓰는 것 |
|---|---|---|
| `guest_start_test.dart` | 게스트로 시작 → 하단 탭 다섯 | 게스트 가입 |
| `folder_test.dart` | 공책 만들기 → 지우기 | `POST`, `DELETE /api/folders` |
| `practice_test.dart` | 복습 세트 만들기 → 현장에서 풀었어요 → 복습 마치기 | `POST /api/practiceNotes`, `POST /api/problem-solves`, `PATCH .../complete` |

<br>

## 실행

```
# 시뮬레이터 id 확인
flutter devices

# 전부 (세 파일에 3분 남짓)
flutter test integration_test -d <시뮬레이터 id> --dart-define=ENV=dev

# 하나만
flutter test integration_test/practice_test.dart -d <시뮬레이터 id> --dart-define=ENV=dev
```

- **`--dart-define=ENV` 를 빼먹지 않는다.** 기본값이 `local` 이라 `localhost:8080` 에 붙는다.
- **iOS 시뮬레이터를 쓴다.** 시뮬레이터에서는 알림 권한 요청을 건너뛰어서 OS 팝업이 안 뜬다
  (`lib/Util/NotificationService.dart` 의 `init`). Android 에뮬레이터에서는 아직 돌려 보지
  않았다. 알림 권한 요청이 첫 화면보다 먼저 뜨는 구조라 권한을 미리 줘야 할 것 같다.
- **dev 서버가 죽어 있으면 로컬 백엔드에 붙인다.** `OnO_BACKEND/backend` 에서 `make up` 으로
  MySQL, Redis, RabbitMQ 를 띄우고 `./gradlew bootRun --args='--spring.profiles.active=local'`
  로 서버를 켠 뒤 `--dart-define=ENV=local` 로 돌린다. 시뮬레이터는 Mac 의 `localhost` 에 붙는다.

<br>

## 테스트를 쓰는 법

```dart
testWidgets('...', (tester) async {
  await runFreshApp(tester, cleanup: () => deleteGuestAccount(tester), () async {
    await pumpUntilFound(tester, find.text('게스트로 시작하기'),
        timeout: const Duration(seconds: 60));
    await signInAsGuest(tester);

    await tapText(tester, '복습 세트');
    // ...
  });
});
```

- **`runFreshApp` 으로 감싼다.** 로그인 토큰과 튜토리얼 기록을 지우고 진짜 `main()` 을 부른다.
  끝나면(실패해도) `cleanup` 과 `FlutterError.onError` 되돌리기를 한다.
- **게스트 계정은 `cleanup` 에서 지운다.** 게스트로 들어갈 때마다 서버에 계정이 하나씩 생긴다.
- **`pumpAndSettle` 을 쓰지 않는다.** 홈은 탭 다섯을 한꺼번에 띄우고 개구리 대기 모션 같은
  끝나지 않는 연출이 있어서 영영 안정되지 않는다. `pumpUntilFound`, `pumpUntilGone`,
  `tapText` 로 기다린다.
- **글자로 찾는다.** 앱에 `Key` 가 거의 없다. 같은 글자가 여럿이면 `tapText` 는 마지막 것을
  누르는데, 앱바 제목과 버튼 글자가 같은 화면은 `find.widgetWithText(ElevatedButton, ...)`
  처럼 위젯 종류로 좁힌다.
- **`find.text` 는 입력칸의 글자도 찾는다.** 방금 입력한 이름이 목록에 생겼는지 볼 때는
  입력칸이 사라진 뒤(`pumpUntilGone`)에 찾는다.
- **사진이 필요한 데이터는 `seedProblems` 로 서버에 바로 넣는다.** 오답노트 등록은 사진
  선택(OS 화면)을 거쳐야 해서 이 도구로는 누를 수 없다. 앱의 서비스 클래스와 로그인
  토큰을 그대로 쓴다.
- **기다리던 것이 안 나오면 실패 메시지에 그때 화면의 글자가 찍힌다.** 어디서 멈췄는지
  거기서 먼저 본다.

<br>

## 아직 안 하는 것

| 무엇 | 이유 |
|---|---|
| 오답노트 등록 | 사진 선택과 자르기가 OS 화면이라 Patrol 같은 도구가 필요하다 |
| 소셜 로그인 | 외부 계정이 필요하다 |
| CI 에서 돌리기 | 시뮬레이터와 서버가 필요하다. 로컬에서 안정화한 뒤 정한다 |
