---
name: feat
description: plan 명세서를 기준으로 기능을 구현하고 analyze, 관련 테스트까지 돌린다. 커밋은 하지 않는다.
argument-hint: "[명세서 경로 또는 기능명, 생략 시 확인]"
disable-model-invocation: true
---

인자: $ARGUMENTS

이 스킬의 절차 본문은 레포 루트의 `.agents/skills/ono-feat/SKILL.md` 한 곳에만 있다(Codex 와 같은 파일을 쓴다).
**다른 일을 하기 전에 Read 로 그 파일을 끝까지 읽고, 그 절차와 보고 형식을 그대로 따른다.** 위 인자가 그 파일에서 말하는 인자이고, 비어 있으면 그 파일의 "인자가 없으면" 규칙을 따른다.
파일을 읽지 못하면 기억에 기대 진행하지 말고 읽지 못했다고 보고한다.

## Claude Code 에서 더 하는 것

- 편집할 때마다 `.claude/settings.json` 의 PostToolUse 훅(`.claude/hooks/dart_check.sh`)이 바꾼 dart 파일을 같은 기준으로 analyze 한다. 훅이 알려 준 warning, error 는 바로 고친다.
- 커밋은 사용자가 `/commit` 을 부를 때 한다.
