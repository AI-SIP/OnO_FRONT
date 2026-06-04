---
name: ono-pr
description: OnO Flutter 레포에서 사용자가 "pr <커밋 해쉬>"를 입력하거나 PR 제목/본문 초안 작성을 요청할 때 사용한다. 지정 커밋부터 현재까지 diff를 분석해 PR 문서를 작성한다.
---

# OnO PR Skill

사용자가 `pr <커밋 해쉬>` 형태로 요청하면 이 Skill을 따른다. 인자가 없으면 현재 작업 중인 변경사항(`git status`, staged/unstaged diff, untracked 파일)을 기준으로 PR 초안을 작성한다.

## 목표

입력한 커밋부터 현재 작업 상태까지의 변경사항을 분석해 `.github/PULL_REQUEST_TEMPLATE.md` 형식에 맞는 PR 제목과 본문 초안을 작성한다. 커밋 해시가 없으면 현재 변경사항만 기준으로 작성한다.

## 절차

1. 기준 커밋 해시가 있으면 `git log`, `git diff <커밋>..HEAD`, 현재 uncommitted diff를 확인한다.
2. 기준 커밋 해시가 없으면 `git status`, staged/unstaged diff, untracked 파일을 확인해 현재 변경사항 기준으로 작성한다.
3. `.github/PULL_REQUEST_TEMPLATE.md`를 반드시 읽는다.
4. 관련 `docs` 기능 문서 폴더를 찾는다.
5. 저장할 기능 문서 폴더가 명확하지 않으면 사용자에게 확인한다.
6. PR 문서를 해당 기능 문서 폴더 아래 markdown 파일로 저장한다.

## PR 문서 포함 항목

- PR 제목
- 연관 이슈
- 작업 내용
- 사용자 영향
- 반응형 대응
- 검증 결과
- 배포 리스크
- 스크린샷 필요 여부

## 주의

- 실제 PR 생성, push, branch 변경은 사용자 요청 없이는 하지 않는다.
- 변경사항을 과장하지 않는다.
- 검증하지 않은 항목은 검증했다고 쓰지 않는다.
