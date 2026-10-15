---
name: pr
description: 현재 브랜치를 필요하면 push 하고 develop 대상 GitHub PR 을 확인 없이 만든다. merge 는 하지 않는다.
argument-hint: "[기준 커밋 해시]"
disable-model-invocation: true
---

인자: $ARGUMENTS

이 스킬의 절차 본문은 레포 루트의 `.agents/skills/ono-pr/SKILL.md` 한 곳에만 있다(Codex 와 같은 파일을 쓴다).
**다른 일을 하기 전에 Read 로 그 파일을 끝까지 읽고, 그 절차와 보고 형식을 그대로 따른다.** 위 인자가 그 파일에서 말하는 인자이고, 비어 있으면 그 파일의 "인자가 없으면" 규칙을 따른다.
파일을 읽지 못하면 기억에 기대 진행하지 말고 읽지 못했다고 보고한다.

## Claude Code 에서 더 하는 것

- 이슈 검색과 PR 생성은 `mcp__github__*` 도구를 먼저 쓰고, 없으면 `gh` 를 쓴다.
- merge, `main`/`develop` 직접 push, force push 는 `.claude/settings.json` 에서도 막혀 있다.
