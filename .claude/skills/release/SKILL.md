---
name: release
description: 출시 준비. release 브랜치, analyze, 테스트, 에이전트 검증, pubspec 버전 올림 커밋, 스토어 업데이트 내역까지 하고 빌드 업로드와 스토어 제출은 사람에게 넘긴다.
argument-hint: "<출시 버전, 예: 4.1.2> [기준 커밋 또는 직전 출시 브랜치]"
disable-model-invocation: true
---

인자: $ARGUMENTS

이 스킬의 절차 본문은 레포 루트의 `.agents/skills/ono-release/SKILL.md` 한 곳에만 있다(Codex 와 같은 파일을 쓴다).
**다른 일을 하기 전에 Read 로 그 파일을 끝까지 읽고, 그 절차와 보고 형식을 그대로 따른다.** 위 인자가 그 파일에서 말하는 인자이고, 비어 있으면 그 파일의 "인자가 없으면" 규칙을 따른다.
파일을 읽지 못하면 기억에 기대 진행하지 말고 읽지 못했다고 보고한다.

## Claude Code 에서 더 하는 것

- 3단계 위험 검토는 아래 에이전트 네 개를 병렬로 띄워 출시 범위 diff 를 나눠 맡긴다. 반응형과 API 계약은 직접 본다.
  - `perf-reviewer`, `logic-reviewer`, `side-effect-checker`, `permission-auditor`
- `flutter build` 는 `.claude/settings.json` 에서 확인을 받게 되어 있다. 릴리스 빌드는 안내만 하고 실행하지 않는다.
