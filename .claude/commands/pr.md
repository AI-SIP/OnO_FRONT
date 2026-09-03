---
description: 현재 브랜치 개발 내역을 develop 브랜치로 merge 요청하는 GitHub PR 생성
argument-hint: "[기준 커밋 해시]"
---

현재 브랜치의 개발 내역을 분석해 `AI-SIP/OnO_FRONT` 리포지토리에서 현재 브랜치를 `develop` 브랜치에 merge 요청하는 GitHub PR을 생성한다.

**고정 규칙**

- base branch는 항상 `develop`
- head branch는 현재 브랜치
- assignee는 항상 `KiSeungMin`
- reviewers는 지정하지 않음
- milestone, project 등 나머지 항목은 지정하지 않음
- `main` 대상 PR은 절대 생성하지 않음

**1단계 - 브랜치와 작업 상태 확인**

```
git branch --show-current
git status --short
```

현재 브랜치가 `main`, `master`, `develop`이면 PR을 생성하지 않는다. 커밋되지 않은 변경사항이 있으면 PR에 포함되지 않는다고 보고하고, 사용자가 명시적으로 계속 요청하지 않는 한 PR 생성을 중단한다.

**2단계 - 변경사항 파악**

가능하면 `git fetch origin develop`으로 비교 기준을 최신화한다.

`$ARGUMENTS` 기준 커밋이 있으면:

```
git log <커밋해시>..HEAD --oneline
git diff <커밋해시>..HEAD
```

기준 커밋이 없으면:

```
git log origin/develop..HEAD --oneline
git diff origin/develop..HEAD
```

`origin/develop`이 없으면 `develop..HEAD`를 사용한다.

**3단계 - 연관 이슈 검색**

`mcp__github__search_issues` 또는 `mcp__github__list_issues` 툴로 `AI-SIP/OnO_FRONT` 저장소의 open 이슈 중 연관된 것을 찾는다.

검색 키워드 순서:
1. 브랜치명에서 타입 접두사(`feat/`, `fix/` 등)를 제거한 핵심 단어
2. 커밋 메시지에서 반복되는 명사·동사 조합
3. 위 두 가지로 찾지 못하면 추가 검색 없이 없음으로 처리

연관 이슈가 명확하면 PR body의 연관 이슈 항목에 `close #번호`를 포함한다. 여러 개면 모두 포함한다. 관련 이슈가 불명확하면 임의로 연결하지 않고 `없음` 또는 `확인 필요`로 작성한다.

**4단계 - PR 템플릿 확인**

`.github/PULL_REQUEST_TEMPLATE.md` 양식을 반드시 확인하고 그 형식을 따른다.

**5단계 - PR 제목, 본문, label 결정**

PR 내용에 포함할 항목:

- 3단계에서 연관 이슈를 찾았으면 `close #이슈번호`, 없으면 `없음` 또는 `확인 필요`
- 사용자 관점의 작업 내용
- 주요 변경사항
- 반응형 대응 여부 (UI 변경이 있는 경우)
- 실행한 검증 결과 (`flutter analyze`, 테스트)
- 배포 리스크 및 확인이 필요한 부분
- 스크린샷 안내 (해당하는 경우)

label 후보:

| 변경 성격 | title 접두사 | label 후보 |
|---|---|---|
| 기능 추가, 사용자 기능 변경 | `[Feat]` | `feature`, `enhancement` |
| 버그 수정, 오류 수정 | `[Fix]` | `bug` |
| 리팩터링, 구조 정리 | `[Refactor]` | `refactor` |
| 문서 변경 | `[Docs]` | `documentation`, `docs` |
| 테스트 변경 | `[Test]` | `test` |
| 빌드, 설정, 의존성, 기타 작업 | `[Chore]` | `chore` |

가능하면 저장소에 존재하는 label을 먼저 확인한다. 존재 여부를 확인할 수 없거나 유효성 오류가 우려되면 label은 생략한다.

**6단계 - GitHub PR 생성**

가능한 도구를 사용해 PR을 생성한다.

- repository: `AI-SIP/OnO_FRONT`
- base: `develop`
- head: 현재 브랜치
- title: `[접두사] <한 줄 요약>`
- body: `.github/PULL_REQUEST_TEMPLATE.md` 형식
- draft: false

PR 생성 후 PR 번호를 대상으로 assignee와 label을 설정한다. GitHub PR은 issue 번호를 공유하므로 issue assignee/label 도구를 사용할 수 있다.

- assignees: `["KiSeungMin"]`
- labels: 존재하는 label만 추가
- reviewers: 생략

PR 생성 전에 `git ls-remote --exit-code origin <브랜치명>`으로 원격 브랜치 존재 여부를 확인한다. 원격에 브랜치가 없으면 `git push -u origin <브랜치명>`으로 먼저 push하여 브랜치를 생성한 뒤 PR을 생성한다.

**7단계 - 결과 보고**

생성된 PR 번호와 URL, base/head, assignee, label, 연결한 이슈, 실행한 검증과 남은 리스크를 보고한다.
