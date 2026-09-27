---
name: ono-pr
description: OnO Flutter 레포에서 사용자가 "pr" 또는 "pr <기준 커밋>"을 입력하면 현재 브랜치의 개발 내역을 바탕으로 develop 브랜치 대상 GitHub PR을 생성한다.
---

# OnO PR Skill

사용자가 `pr` 또는 `pr <기준 커밋>` 형태로 요청하면 이 Skill을 따른다.

## 목표

현재 브랜치의 개발 내역을 분석해 `AI-SIP/OnO_FRONT` GitHub Repository에서 현재 브랜치를 `develop` 브랜치에 merge 요청하는 PR을 실제로 생성한다.

## 고정값

- Repository: `AI-SIP/OnO_FRONT`
- Base branch: `develop`
- Head branch: 현재 로컬 브랜치
- Assignee: `KiSeungMin`
- Reviewers: 지정하지 않음
- Milestone, project, linked development: 지정하지 않음
- `main` 대상 PR은 생성하지 않음

## 절차

1. `git branch --show-current`로 현재 브랜치를 확인한다.
2. 현재 브랜치가 `main`, `master`, `develop`이면 PR을 만들지 말고 사용자에게 중단 사유를 보고한다.
3. `git status --short`로 uncommitted 변경사항을 확인한다. 커밋되지 않은 변경이 있으면 PR에 포함되지 않는다는 점을 알리고, 사용자가 명시적으로 계속 요청하지 않는 한 PR 생성을 중단한다.
4. `git fetch origin develop`이 가능하면 실행해 비교 기준을 최신화한다. 실행하지 못하면 로컬 `develop` 또는 `origin/develop` 기준으로 분석하고 남은 리스크를 보고한다.
5. 기준 커밋이 있으면 `git log <기준 커밋>..HEAD --oneline`과 `git diff <기준 커밋>..HEAD`를 확인한다.
6. 기준 커밋이 없으면 `git log origin/develop..HEAD --oneline`과 `git diff origin/develop..HEAD`를 확인한다. `origin/develop`이 없으면 `develop..HEAD`를 사용한다.
7. GitHub에서 현재 브랜치명, 커밋 메시지, 변경사항 키워드와 관련된 open issue를 먼저 검색한다.
8. 관련 이슈가 명확하면 PR body의 연관 이슈 항목에 `close #번호`를 포함한다. 여러 개면 모두 포함한다.
9. 관련 이슈가 불명확하면 임의로 연결하지 않고 `없음` 또는 `확인 필요`로 작성한다.
10. `.github/PULL_REQUEST_TEMPLATE.md`를 반드시 읽고 그 형식에 맞춰 PR body를 작성한다.
11. 변경사항 성격에 맞춰 PR title과 label 후보를 정한다.
12. GitHub MCP 또는 GitHub CLI로 PR을 생성한다.
13. PR 생성 후 PR 번호를 대상으로 assignee `KiSeungMin`을 추가하고, 유효한 label만 추가한다. PR은 GitHub issue와 번호를 공유하므로 issue/label/assignee 도구를 사용할 수 있다.
14. 생성된 PR 번호, URL, base/head, assignee, label, 연결한 이슈, 검증 여부를 보고한다.

## 제목과 라벨 기준

- 기능 추가, 사용자 기능 변경: 제목 prefix `[Feat]`, label 후보 `feature`, `enhancement`
- 버그 수정, 크래시/오류 수정: 제목 prefix `[Fix]`, label 후보 `bug`
- 리팩터링, 구조 정리: 제목 prefix `[Refactor]`, label 후보 `refactor`
- 문서 변경: 제목 prefix `[Docs]`, label 후보 `documentation`, `docs`
- 테스트 변경: 제목 prefix `[Test]`, label 후보 `test`
- 빌드, 설정, 의존성, 기타 작업: 제목 prefix `[Chore]`, label 후보 `chore`

저장소에 어떤 label이 존재하는지 확인할 수 있으면 먼저 조회한다. 확인할 수 없거나 유효성 오류가 우려되면 label은 생략하고 PR 제목과 본문으로 변경 성격을 명확히 한다.

## PR 본문 포함 항목

- GitHub에서 검색한 연관 이슈가 명확하면 `close #번호`, 없으면 `없음` 또는 `확인 필요`
- 사용자 관점의 작업 내용
- 주요 변경사항
- UI 변경이 있으면 반응형 대응 여부
- 실행한 검증 결과
- 배포 리스크 또는 확인 필요 사항
- 스크린샷이 필요한 UI 변경이면 스크린샷 필요 여부

## 주의

- 이 명령은 실제 PR을 생성한다.
- base branch는 항상 `develop`이다.
- `main` 대상 PR은 생성하지 않는다.
- 현재 브랜치를 push해야 PR 생성이 가능하지만 원격 브랜치가 없으면 사용자에게 push 필요 여부를 확인한다. 사용자가 명시적으로 허용하기 전에는 push하지 않는다.
- Reviewers는 지정하지 않는다.
- Assignee는 항상 `KiSeungMin`으로 지정한다.
- 변경사항을 과장하지 않는다.
- 검증하지 않은 항목은 검증했다고 쓰지 않는다.
