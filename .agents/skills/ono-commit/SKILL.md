---
name: ono-commit
description: OnO Flutter 레포에서 사용자가 "commit" 을 요청하면 현재 변경사항을 논리 단위로 나누고 OnO 형식 메시지로 실제 커밋까지 수행한다. push 와 PR 은 하지 않는다.
---

# OnO Commit Skill

사용자가 `commit` 을 요청하면 이 Skill을 따른다. 인자가 없으면 현재 작업 중인 변경사항(`git status`, staged/unstaged diff, untracked 파일)을 대상으로 한다. 메시지 추천만 원한다고 명시하면 커밋하지 않고 추천만 한다.

## 목표

현재 변경사항을 분석해 적절한 커밋 단위와 OnO 형식의 커밋 메시지를 바탕으로 커밋을 수행한다. 

## 절차

1. `git status`, staged/unstaged diff, untracked 파일을 확인한다.
2. 변경 파일을 기능/수정/문서/설정 단위로 묶는다.
3. unrelated 변경이 섞여 있으면 분리 커밋한다.
4. 단위마다 `git add <파일>` 과 `git commit` 을 실행한다. `commit` 요청 자체가 커밋 요청이라 따로 확인받지 않는다.
5. 아래 경우는 커밋하지 않고 보고한다.
   - 현재 브랜치가 `main` 또는 `develop`
   - 비밀 파일(`.env`, 서명 파일)이나 빌드 산출물이 섞여 있음
   - 요청과 무관한 사용자의 다른 변경이 섞여 있어 어디까지 커밋할지 불분명함
6. `git log --oneline -5` 로 결과를 확인한다. push 와 PR 생성은 `ono-pr` 에서 한다.

## 커밋 메시지 형식

```text
[Feat] 구현 타이틀 - 구현 상세1 구현 상세2 (#이슈번호)
```

태그는 변경 성격에 맞춰 `[Feat]`, `[Fix]`, `[Refactor]`, `[Chore]`, `[Test]`, `[Docs]` 중 하나를 사용한다.

## 보고 형식

- 만든 커밋 (해시, 메시지, 포함 파일)
- 커밋하지 않고 남긴 변경과 그 이유
- 커밋 전에 실행한 검증과 아직 안 한 검증
