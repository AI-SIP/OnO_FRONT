---
name: sim
description: 앱을 dev 서버에 붙여 iOS 시뮬레이터(또는 Android 에뮬레이터)에 띄우고, 스크린샷을 찍어 화면을 확인한 뒤 사용자가 볼 것을 체크리스트로 넘긴다.
argument-hint: "[ios|android] [확인할 화면이나 동선 설명]"
disable-model-invocation: true
---

인자: $ARGUMENTS

이 스킬의 절차 본문은 레포 루트의 `.agents/skills/ono-sim/SKILL.md` 한 곳에만 있다(Codex 와 같은 파일을 쓴다).
**다른 일을 하기 전에 Read 로 그 파일을 끝까지 읽고, 그 절차와 보고 형식을 그대로 따른다.** 위 인자가 그 파일에서 말하는 인자이고, 비어 있으면 그 파일의 "인자가 없으면" 규칙을 따른다.
파일을 읽지 못하면 기억에 기대 진행하지 말고 읽지 못했다고 보고한다.

## Claude Code 에서 더 하는 것

- `$SIM_DIR` 는 이 세션의 scratchpad 디렉터리가 있으면 그 아래 `sim/` 으로 잡는다.
- `flutter run` 은 Bash 의 `run_in_background` 로 띄운다. 명령 끝에 `&` 를 붙이지 않는다.
- 찍은 스크린샷은 Read 로 직접 열어 본다.
- `.mcp.json` 의 Dart MCP(`dart`)가 붙어 있어도 `hot_reload`, `get_widget_tree`, `get_runtime_errors` 는 쓰지 않는다(정본 2단계 참고). `analyze_files`, `run_tests` 같은 정적 도구로만 쓴다.
