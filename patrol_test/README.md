# Patrol E2E 테스트

사진 선택처럼 **OS 가 그리는 화면**을 거치는 동선의 E2E 테스트다. `integration_test/` 는 앱이
그리는 화면만 누를 수 있어서, 거기서 못 하는 동선만 여기에 둔다. 공용 헬퍼(앱 띄우기, 게스트
로그인, 기다리기)는 `integration_test/helpers/` 것을 같이 쓴다.

| 파일 | 동선 | OS 화면 |
|---|---|---|
| `problem_register_test.dart` | 추가 → 오답노트 여러장 작성 → 갤러리에서 사진 선택 → 상세 정보 입력 → 등록 | iOS 사진 선택 화면 |

<br>

## 처음 한 번

```
# Patrol CLI 설치
dart pub global activate patrol_cli

# 시뮬레이터 사진첩에 사진 넣기 (테스트가 첫 사진을 고른다)
xcrun simctl addmedia <시뮬레이터 id> assets/Medal/first_step.png
```

- **`patrol_cli` 는 처음 실행할 때 `~/.zshrc` 에 자동완성 줄을 붙인다.** 원하지 않으면
  `## [Completion]` 부터 `## [/Completion]` 까지 지운다.

<br>

## 실행

```
export PATH="$PATH:$HOME/.pub-cache/bin"
patrol test -t patrol_test/problem_register_test.dart -d <시뮬레이터 id> --dart-define=ENV=dev
```

- `flutter test` 가 아니라 `patrol test` 로 돌린다. Patrol 이 iOS UI 테스트 번들(`RunnerUITests`)을
  같이 빌드해서 OS 화면을 누른다.
- 서버 고르는 법과 로컬 백엔드에 붙이는 법은 `integration_test/README.md` 와 같다.
- 이 테스트는 오답노트를 실제로 등록한다. 등록하면 앱이 문제 분석도 요청해서 분석 API 호출이 한 번
  나간다. 끝나면 게스트 계정을 탈퇴시킨다.

<br>

## iOS 설정에서 바꾼 것

Patrol 은 XCTest UI 테스트 번들 안에서 Dart 테스트를 돌린다. 그래서 iOS 프로젝트에 아래를 더했다.
**Runner 앱의 설정은 건드리지 않았다.**

| 파일 | 무엇 |
|---|---|
| `ios/RunnerUITests/RunnerUITests.m` | Patrol 매크로 한 줄짜리 진입점 |
| `ios/Runner.xcodeproj/project.pbxproj` | `RunnerUITests` 타깃. 앞뒤에 `xcode_backend.sh build` 와 `embed_and_thin` 단계 |
| `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | 테스트 액션에 `RunnerUITests` 추가 |
| `ios/Flutter/RunnerUITests-*.xcconfig` | Pods 설정과 `Generated.xcconfig` 를 같이 읽는 설정 |
| `ios/Podfile` | `RunnerUITests` 가 `:complete` 로 플러그인을 물려받게 |

- **xcconfig 를 따로 둔 이유**: 처음에 CocoaPods 가 만든 설정만 물렸더니 `embed_and_thin` 단계가
  `FLUTTER_BUILD_DIR` 을 못 찾아 `xcode_backend.dart` 에서 null 로 죽었다. 그 값은 Flutter 가 만드는
  `Generated.xcconfig` 에 있다.

<br>

## 아직 안 하는 것

| 무엇 | 이유 |
|---|---|
| Android | `androidTest` 설정이 따로 필요하다. iOS 에서 안정화한 뒤 한다 |
| 1장 작성 | 사진을 고른 뒤 네이티브 자르기 화면을 거친다. 자르기 화면은 OS 버전마다 버튼이 달라 불안정하다 |
| 카메라 촬영 | 시뮬레이터에는 카메라가 없다 |
