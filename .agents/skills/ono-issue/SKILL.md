---
name: ono-issue
description: OnO Flutter 레포에서 사용자가 "/issue <내용>" 또는 "issue <내용>"을 입력하면 GitHub 이슈 템플릿에 맞춰 AI-SIP/OnO_FRONT 이슈를 생성한다. 파일 경로가 주어지면 파일 내용을 읽어 이슈 내용을 구성한다.
---

# OnO Issue Skill

> 이 파일이 `issue` 절차의 정본이다. Codex 는 이 파일을 바로 쓰고, Claude Code 의 `/issue` 는 `.claude/skills/issue/SKILL.md` 래퍼가 이 파일을 읽어 따른다. 절차를 고칠 때는 이 파일만 고친다.

사용자가 `/issue <내용>` 또는 `issue <내용>` 형태로 요청하면 이 Skill을 따른다.

## 목표

사용자가 자유롭게 적은 설명이나 전달한 파일 내용을 바탕으로 `AI-SIP/OnO_FRONT` GitHub Repository에 실제 이슈를 생성한다. 이슈는 `.github/ISSUE_TEMPLATE` 아래 템플릿 형식에 맞춰 작성한다. 코드는 수정하지 않는다.

## 고정값

- Repository: `AI-SIP/OnO_FRONT`
- Assignee: `KiSeungMin` (항상 고정)
- 생성 도구: GitHub MCP 의 `issue_write`(method `create`)가 있으면 그것을, 없으면 `gh issue create` 를 쓴다.

## 절차

1. 사용자 입력에서 이슈 원문과 파일 경로를 구분한다.
2. 파일 경로가 있으면 해당 파일을 읽고, 여러 파일이면 모든 내용을 붙이지 말고 이슈 작성에 필요한 핵심만 요약한다.
3. `.github/ISSUE_TEMPLATE/bug-report-template.md`와 `.github/ISSUE_TEMPLATE/common-issue-template.md`를 읽는다.
4. 내용이 실제 버그, 오류, 크래시, 화면 깨짐, 재현 조건, 예상/실제 결과를 포함하면 bug 템플릿을 선택한다.
5. 기능 추가, 개선, 리팩터링, 문서화, 작업 TODO 성격이면 common 템플릿을 선택한다.
6. 사용자가 타입을 명시하지 않았으면 아래 기준으로 제목 prefix와 label을 추론한다.
7. 추론이 어려워도 이슈 생성이 가능하면 가장 보수적인 common 이슈로 생성하고, 본문 `ETC`에 확인 필요 사항을 남긴다.
8. GitHub 이슈를 생성한 뒤 이슈 번호, URL, 적용한 template/label/assignee를 보고한다.

## 제목과 label

label 은 저장소에 실제로 있는 것만 붙인다. 생성 전에 `gh label list -R AI-SIP/OnO_FRONT` 등으로 확인하고, 아래 표와 다르면 실제 목록을 따른다. 확인할 수 없거나 유효성 오류가 우려되면 label 은 생략하고 제목 prefix와 본문으로 의도를 드러낸다.

| 내용 성격 | 템플릿 | 제목 prefix | label (2026-10 기준 실제 목록) |
|---|---|---|---|
| 버그, 오류, 크래시, 예외, 화면 깨짐, 동작 불일치 | Bug Report | `[bug]` | `Bug` |
| 새 기능, 사용자 기능 추가, 화면 추가, API 연동 | Common Issue | `[feat]` | `Feature` |
| UI/UX 개선, 문구 개선, 사용성 개선 | Common Issue | `[improve]` | `enhancement` (디자인 변경이면 `Design`) |
| 리팩터링, 구조 정리, 성능 개선 | Common Issue | `[refactor]` | `Chore` |
| 설정, 빌드, 의존성, 문서, 기타 작업 | Common Issue | `[chore]` | `Chore` |
| 테스트 추가/수정 | Common Issue | `[test]` | `test` |

## 본문 작성 규칙

### Bug Report Template

```markdown
## ⚙️ 어떤 버그인가요?

<한두 문장으로 버그 요약>

### 스크린샷(선택)

## 🔎 어떤 상황에서 발생한 버그인가요?

> Given: <전제 상황>
> When: <어떤 행동을 했을 때>
> Then: <어떤 문제가 발생했는지>

## ✅ 예상 결과

<정상적으로 동작했어야 하는 결과>
```

- 스크린샷은 사용자가 이미지나 경로를 준 경우만 언급한다.
- 알 수 없는 항목은 지어내지 않고 `확인 필요`로 표시한다.

### Common Issue Template

```markdown
## 📝 Description

<작업 목표와 배경>

## ✅ TODO

- [ ] <핵심 작업 1>
- [ ] <핵심 작업 2>

## 💡 ETC (선택)

<참고 파일, 확인 필요 사항, API/디자인/반응형 주의점. 없으면 생략>
```

TODO는 과하게 쪼개지 말고 실제 구현자가 바로 이해할 수 있는 단위로 작성한다.

## 주의

- 실제 운영 중인 앱 기준으로 사용자 영향, 반응형, API 계약, null/빈 상태/에러 상태 위험을 본문에 필요한 만큼 포함한다.
- 사용자가 준 내용을 과장하거나 임의 요구사항을 추가하지 않는다.
- 제목은 짧고 구체적으로 작성한다.
- 한국어 문구는 자연스럽고 간결하게 작성한다.
- GitHub 생성에 실패하면 오류 원인과 필요한 권한을 짧게 보고한다.
