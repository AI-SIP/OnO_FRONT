---
name: plan
description: 새 기능의 구현 명세서를 docs/ 아래에 작성한다. 코드는 수정하지 않는다.
argument-hint: "<기능 설명>"
disable-model-invocation: true
---

인자: $ARGUMENTS

이 스킬의 절차 본문은 레포 루트의 `.agents/skills/ono-plan/SKILL.md` 한 곳에만 있다(Codex 와 같은 파일을 쓴다).
**다른 일을 하기 전에 Read 로 그 파일을 끝까지 읽고, 그 절차와 보고 형식을 그대로 따른다.** 위 인자가 그 파일에서 말하는 인자이고, 비어 있으면 그 파일의 "인자가 없으면" 규칙을 따른다.
파일을 읽지 못하면 기억에 기대 진행하지 말고 읽지 못했다고 보고한다.

## Claude Code 에서 더 하는 것

- 현재 코드의 위젯, 상태, API 흐름 파악은 `code-tracer` 에이전트에 맡긴다.
- 명세서를 쓰고 나면 멈추고 사용자 검토를 기다린다. `/feat` 로 이어서 진행하지 않는다.
