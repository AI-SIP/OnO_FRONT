---
name: sim
description: 앱을 dev 서버에 붙여 iOS 시뮬레이터(또는 Android 에뮬레이터)에 띄우고, 스크린샷을 찍어 화면을 확인한 뒤 사용자가 볼 것을 체크리스트로 넘긴다.
argument-hint: "[ios|android] [확인할 화면이나 동선 설명]"
disable-model-invocation: true
---

`$ARGUMENTS` 를 기준으로 앱을 시뮬레이터에 띄우고 화면을 확인한다.

- 첫 단어가 `ios` 나 `android` 면 플랫폼으로 쓰고, 없으면 `ios` 다.
- 나머지는 확인할 화면이나 동선 설명이다. 없으면 현재 변경사항(`git status`, `git diff`)에서 바뀐 화면을 찾는다.

**앱 코드를 고치지 않는다.** 이 스킬은 띄우고 보는 것까지만 한다. 고칠 것이 보이면 무엇을 왜 고쳐야 하는지만 보고한다.

---

## 0단계 - 실행 전에 확인

```bash
test -f .env && echo ".env 있음" || echo ".env 없음"
flutter devices
```

- **`.env` 가 없으면 멈춘다.** `pubspec.yaml` 의 assets 에 `.env` 가 있어서 없으면 빌드가 실패한다. worktree 에서 작업 중이면 대개 없으니 사용자에게 메인 작업 트리의 `.env` 를 이 경로에 두어 달라고 요청한다. **`.env` 내용은 출력하거나 복사하지 않는다.**
- **실기기에는 띄우지 않는다.** `flutter devices` 에 `ksm의 iPhone` 같은 실기기가 보여도 고르지 않는다. 기기는 반드시 시뮬레이터 UDID 나 에뮬레이터 id 로 `-d` 에 직접 넘긴다.
- 로그와 스크린샷은 **레포 밖**에 둔다. Claude Code 가 알려 준 scratchpad 디렉터리가 있으면 그 아래 `sim/`, 없으면 `/tmp/ono-sim/` 을 쓴다. 아래에서는 이 경로를 `$SIM_DIR` 로 부른다.

```bash
SIM_DIR=/tmp/ono-sim   # scratchpad 가 있으면 그쪽으로
mkdir -p "$SIM_DIR"
```

---

## 1단계 - 시뮬레이터 준비

### iOS

```bash
xcrun simctl list devices booted
```

- **부팅된 시뮬레이터가 있으면 그것을 쓴다.** 여러 대면 iPhone 을 먼저 고르고, 설명에 태블릿이나 iPad 가 있으면 iPad 를 고른다.
- **없으면 최근에 부팅했던 기종을 켠다.** `lastBootedAt` 이 가장 최근인 것을 고르고, 기록이 없으면 `iPhone 17 Pro` 를 쓴다. 태블릿 확인이면 `iPad Pro 13-inch (M5)` 다.

```bash
# 최근 부팅 순으로 기종 보기
xcrun simctl list -j devices available | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
rows=[(v.get('lastBootedAt',''),v['name'],v['udid']) for l in d.values() for v in l]
for r in sorted(rows,reverse=True)[:5]: print(*r, sep='  ')"

xcrun simctl boot <UDID>
xcrun simctl bootstatus <UDID> -b   # 부팅이 끝날 때까지 기다린다
open -a Simulator
```

### Android

```bash
flutter emulators                       # 에뮬레이터 id 확인
flutter emulators --launch <에뮬레이터 id>
adb devices                             # emulator-5554 같은 기기 id 확인
```

- Android 에서는 알림 권한 요청이 첫 화면보다 먼저 뜰 수 있다(`integration_test/README.md`). 뜨면 사용자에게 알리고, 허용할지는 사용자에게 맡긴다.

---

## 2단계 - dev 서버로 실행

**`--dart-define=ENV=dev` 를 빼먹지 않는다.** 기본값이 `local` 이라 빼먹으면 `localhost:8080` 에 붙는다(`lib/Config/AppConfig.dart` 의 `load`). 실행 명령은 `BUILD_COMMANDS.md` 의 개발 서버 명령에 기기 지정과 로그 옵션만 더한 것이다.

```bash
flutter run -d <UDID 또는 에뮬레이터 id> --dart-define=ENV=dev \
  --print-dtd --pid-file "$SIM_DIR/flutter.pid" \
  > "$SIM_DIR/flutter-run.log" 2>&1 < /dev/null
```

- **Bash 의 `run_in_background` 로 띄운다.** `&` 를 붙이지 않는다. 표준 입력을 `/dev/null` 로 막아도 앱은 계속 붙어 있다.
- **뜰 때까지는 로그를 기다린다.** `sleep` 을 이어 붙이지 말고 아래처럼 성공과 실패를 모두 잡는 조건으로 기다린다. 처음 빌드는 몇 분 걸린다.

```bash
until grep -qE "Flutter run key commands|Error|Exception|exited|Lost connection" "$SIM_DIR/flutter-run.log"; do sleep 2; done
tail -20 "$SIM_DIR/flutter-run.log"
```

- `ENV=local` 로 띄워야 하는 경우(dev 서버가 죽어 있을 때)는 `integration_test/README.md` 의 로컬 백엔드 순서를 따른다. 사용자가 원하지 않으면 prod 로 띄우지 않는다.

### 코드를 고친 뒤 다시 보기

| 하고 싶은 것 | 방법 |
|---|---|
| hot reload | `kill -USR1 $(cat "$SIM_DIR/flutter.pid")` |
| hot restart | `kill -USR2 $(cat "$SIM_DIR/flutter.pid")` |
| 끝내기 | `kill $(cat "$SIM_DIR/flutter.pid")` |

- 신호를 보낸 뒤 로그에 `Reloaded` 나 `Restarted` 가 찍혔는지 확인하고 스크린샷을 다시 찍는다.
- **Dart MCP(`dart` 서버)의 `hot_reload`, `get_widget_tree`, `get_runtime_errors` 는 지금 쓰지 않는다.** 로그의 `The Dart Tooling Daemon is available at: ws://...` 주소로 `connect_dart_tooling_daemon` 까지는 되지만, Dart 3.9.2 의 MCP 서버로 터미널에서 띄운 앱에 실행해 보면 `No active debug session` 으로 실패한다(에디터가 띄운 디버그 세션을 기준으로 동작하는 것으로 보인다). Dart MCP 는 `analyze_files`, `run_tests`, `dart_format`, `pub_dev_search` 같은 정적 도구로 쓴다.

---

## 3단계 - 화면 확인

```bash
# iOS
xcrun simctl io <UDID> screenshot "$SIM_DIR/<화면이름>-$(date +%H%M%S).png"

# Android
adb -s <기기 id> exec-out screencap -p > "$SIM_DIR/<화면이름>-$(date +%H%M%S).png"
```

- **찍은 파일은 Read 로 직접 열어 본다.** 글자가 잘리거나 넘치는 곳, 로딩이 안 끝난 상태, 에러 스낵바가 있는지 본다.
- 실행 로그도 같이 본다. `grep -nE "Exception|Error|════" "$SIM_DIR/flutter-run.log"` 에 걸리는 줄이 있으면 화면이 멀쩡해 보여도 보고한다.
- **에이전트는 앱 안을 누르거나 입력할 수 없다.** 원하는 화면이 첫 화면이 아니면 사용자에게 어디까지 들어가 달라고 요청하고, 들어갔다고 하면 그때 찍는다.

### 로그인이 필요한 화면

- **게스트로 시작하기를 쓴다.** 첫 화면의 `게스트로 시작하기` 를 누르면 dev 서버에 게스트 계정이 새로 생긴다(`integration_test/guest_start_test.dart`). 별도 테스트 계정은 레포에 없다.
- 소셜 로그인은 외부 계정이 필요해서 사용자가 직접 한다.
- 게스트 계정은 들어갈 때마다 서버에 하나씩 쌓인다. 확인이 끝나면 마이페이지에서 탈퇴해 달라고 체크리스트에 넣는다.

---

## 4단계 - 사용자에게 넘기기

아래 형식으로 보고한다.

```text
## 띄운 환경
- 기기: <기종> (<UDID>), ENV=dev
- 로그: <$SIM_DIR/flutter-run.log 경로>
- 스크린샷: <경로들>

## 스크린샷에서 본 것
- <무엇이 보였고, 이상한 점이 있었는지>

## 직접 확인해 주세요
- [ ] <변경한 화면에 들어가는 순서>
- [ ] <눌러 봐야 할 버튼과 기대 결과>
- [ ] <빈 상태, 긴 텍스트, 에러 상태처럼 스크린샷으로는 못 본 경우>
- [ ] <태블릿이나 가로 화면이 필요하면 그 기종>
- [ ] 게스트로 들어갔다면 확인 후 탈퇴

## 정리
- 앱은 아직 떠 있습니다. 끝내려면: kill $(cat <pid 파일>)
```

- 체크리스트는 **이번 변경이나 요청한 화면에 맞춰** 쓴다. 일반적인 항목을 늘어놓지 않는다.
- 빌드가 실패했으면 체크리스트 대신 로그의 첫 에러 줄과 원인 추정을 보고한다. 원인을 확인하지 못했으면 그렇다고 적는다.

## 하지 않는 것

- 실기기 설치, `--release` 빌드, `flutter build ipa`/`appbundle`, 스토어 업로드
- `ENV=prod` 실행 (사용자가 명시하지 않은 경우)
- `.env` 내용 출력, 서명 파일 접근
- 확인을 위해 앱 코드나 `pubspec.yaml` 을 고치는 것
