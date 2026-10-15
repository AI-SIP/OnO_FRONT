---
name: issue
description: AI-SIP/OnO_FRONT 에 이슈 템플릿 형식으로 GitHub 이슈를 만든다. 코드는 수정하지 않는다.
argument-hint: "<이슈 설명 또는 파일 경로>"
disable-model-invocation: true
---

인자: $ARGUMENTS

이 스킬의 절차 본문은 레포 루트의 `.agents/skills/ono-issue/SKILL.md` 한 곳에만 있다(Codex 와 같은 파일을 쓴다).
**다른 일을 하기 전에 Read 로 그 파일을 끝까지 읽고, 그 절차와 보고 형식을 그대로 따른다.** 위 인자가 그 파일에서 말하는 인자이고, 비어 있으면 그 파일의 "인자가 없으면" 규칙을 따른다.
파일을 읽지 못하면 기억에 기대 진행하지 말고 읽지 못했다고 보고한다.

## Claude Code 에서 더 하는 것

- 이슈 생성은 `mcp__github__issue_write`(method `create`)를 먼저 쓰고, 없으면 `gh issue create` 를 쓴다.
