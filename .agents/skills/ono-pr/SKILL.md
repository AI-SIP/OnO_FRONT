---
name: ono-pr
description: OnO Flutter 레포에서 사용자가 "pr" 또는 "pr <기준 커밋>"을 입력하면 현재 브랜치의 개발 내역을 바탕으로 필요하면 push 하고 develop 브랜치 대상 GitHub PR을 생성한다.
---

# OnO PR Skill

> 이 파일이 `pr` 절차의 정본이다. Codex 는 이 파일을 바로 쓰고, Claude Code 의 `/pr` 은 `.claude/skills/pr/SKILL.md` 래퍼가 이 파일을 읽어 따른다. 절차를 고칠 때는 이 파일만 고친다.

사용자가 `pr` 또는 `pr <기준 커밋>`(Claude Code 에서는 `/pr`) 형태로 요청하면 이 Skill을 따른다.

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
- push 와 PR 생성은 사용자 확인 없이 바로 진행한다 (`pr` 요청 자체가 요청이다)
- PR merge, `main`/`develop` 직접 push, force push 는 사용자가 명시적으로 요청할 때만 한다

## 절차

1. `git branch --show-current`로 현재 브랜치를 확인한다.
2. 현재 브랜치가 `main`, `master`, `develop`이면 PR을 만들지 말고 사용자에게 중단 사유를 보고한다.
3. `git status --short`로 uncommitted 변경사항을 확인한다. 커밋되지 않은 변경이 있으면 PR에 포함되지 않는다는 점을 알리고, 사용자가 명시적으로 계속 요청하지 않는 한 PR 생성을 중단한다.
4. `git fetch origin develop`이 가능하면 실행해 비교 기준을 최신화한다. 실행하지 못하면 로컬 `develop` 또는 `origin/develop` 기준으로 분석하고 남은 리스크를 보고한다.
5. 기준 커밋이 있으면 `git log <기준 커밋>..HEAD --oneline`과 `git diff <기준 커밋>..HEAD`를 확인한다.
6. 기준 커밋이 없으면 `git log origin/develop..HEAD --oneline`과 `git diff origin/develop..HEAD`를 확인한다. `origin/develop`이 없으면 `develop..HEAD`를 사용한다.
7. GitHub에서 open 이슈 중 관련된 것을 검색한다. 키워드는 브랜치명에서 타입 접두사(`feat/`, `fix/` 등)를 뺀 핵심 단어, 그다음 커밋 메시지에서 반복되는 명사와 동사 순서로 쓰고, 둘로 못 찾으면 없음으로 처리한다.
8. 관련 이슈가 명확하면 PR body의 연관 이슈 항목에 `close #번호`를 포함한다. 여러 개면 모두 포함한다. 불명확하면 임의로 연결하지 않고 `없음` 또는 `확인 필요`로 작성한다.
9. `.github/PULL_REQUEST_TEMPLATE.md`를 반드시 읽고 그 형식에 맞춰 PR body를 작성한다.
10. 변경사항 성격에 맞춰 PR title과 label을 정한다.
11. `git ls-remote --exit-code origin <브랜치>` 로 원격 브랜치를 확인한다. 없거나 push 안 된 커밋이 있으면 `git push -u origin <브랜치>:<브랜치>` 로 올린다. 브랜치가 `origin/develop` 을 추적하고 있을 수 있으니 인자 없는 `git push` 는 쓰지 않는다.
12. GitHub MCP 또는 GitHub CLI로 PR을 생성한다(draft 아님).
13. PR 생성 후 PR 번호를 대상으로 assignee `KiSeungMin`을 추가하고, 유효한 label만 추가한다. PR은 GitHub issue와 번호를 공유하므로 issue/label/assignee 도구를 사용할 수 있다.
14. 생성된 PR 번호, URL, base/head, assignee, label, 연결한 이슈, 실행한 검증과 남은 리스크를 보고한다.

## 제목과 label

label 은 저장소에 실제로 있는 것만 붙인다. `gh label list -R AI-SIP/OnO_FRONT` 로 확인하고, 아래 표와 다르면 실제 목록을 따른다. 확인할 수 없으면 label은 생략하고 제목과 본문으로 변경 성격을 드러낸다.

| 변경 성격 | 제목 prefix | label (2026-10 기준 실제 목록) |
|---|---|---|
| 기능 추가, 사용자 기능 변경 | `[Feat]` | `Feature` (개선이면 `enhancement`) |
| 버그 수정, 크래시/오류 수정 | `[Fix]` | `Bug` |
| 리팩터링, 구조 정리 | `[Refactor]` | `Chore` |
| 문서 변경 | `[Docs]` | `Chore` |
| 테스트 변경 | `[Test]` | `test` |
| 빌드, 설정, 의존성, 기타 작업 | `[Chore]` | `Chore` |
| release 브랜치 | `[Release]` | `Release` |

## PR 본문 포함 항목

- 연관 이슈: `close #번호`, 없으면 `없음` 또는 `확인 필요`
- 사용자 관점의 작업 내용
- 주요 변경사항
- UI 변경이 있으면 반응형 대응 여부
- 실행한 검증 결과 (`flutter analyze --no-fatal-infos`, `flutter test`)
- 배포 리스크 또는 확인 필요 사항
- 스크린샷이 필요한 UI 변경이면 스크린샷 필요 여부

## 주의

- 이 명령은 실제 PR을 생성한다.
- 변경사항을 과장하지 않는다.
- 검증하지 않은 항목은 검증했다고 쓰지 않는다.
