---
name: commit
description: 현재 변경사항을 논리 단위로 나눠 OnO 형식 메시지로 실제 커밋한다. push 와 PR 은 하지 않는다.
argument-hint: "[맥락 설명, 생략 가능]"
disable-model-invocation: true
---

인자: $ARGUMENTS

이 스킬의 절차 본문은 레포 루트의 `.agents/skills/ono-commit/SKILL.md` 한 곳에만 있다(Codex 와 같은 파일을 쓴다).
**다른 일을 하기 전에 Read 로 그 파일을 끝까지 읽고, 그 절차와 보고 형식을 그대로 따른다.** 위 인자가 그 파일에서 말하는 인자이고, 비어 있으면 그 파일의 "인자가 없으면" 규칙을 따른다.
파일을 읽지 못하면 기억에 기대 진행하지 말고 읽지 못했다고 보고한다.

## Claude Code 에서 더 하는 것

- push 와 PR 생성은 `/pr` 에서 한다.
