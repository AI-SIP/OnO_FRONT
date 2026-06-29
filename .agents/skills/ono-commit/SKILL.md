---
name: ono-commit
description: OnO Flutter 레포에서 사용자가 "commit" 또는 현재 변경사항의 커밋 단위와 커밋 메시지를 알맞게 작성해 커밋을 수행한다.
---

# OnO Commit Skill

사용자가 `commit` 또는 커밋 메시지 추천을 요청하면 이 Skill을 따른다. 인자가 없으면 현재 작업 중인 변경사항(`git status`, staged/unstaged diff, untracked 파일)을 대상으로 추천한다.

## 목표

현재 변경사항을 분석해 적절한 커밋 단위와 OnO 형식의 커밋 메시지를 바탕으로 커밋을 수행한다. 

## 절차

1. `git status`, staged/unstaged diff, untracked 파일을 확인한다.
2. 변경 파일을 기능/수정/문서/설정 단위로 묶는다.
3. unrelated 변경이 섞여 있으면 분리 커밋을 제안한다.
4. 운영 앱 영향과 검증 필요 여부를 짧게 덧붙인다.

## 커밋 메시지 형식

```text
[Feat] 구현 타이틀 - 구현 상세1 구현 상세2
```

태그는 변경 성격에 맞춰 `[Feat]`, `[Fix]`, `[Refactor]`, `[Chore]`, `[Test]`, `[Docs]` 중 하나를 사용한다.

## 보고 형식

- 추천 커밋 단위
- 각 단위에 포함할 파일
- 커밋 메시지
- 커밋 전 확인할 검증
