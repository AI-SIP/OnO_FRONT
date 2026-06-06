---
description: AI-SIP/OnO_FRONT 리포지토리에 GitHub 이슈 생성
argument-hint: "<이슈 설명 또는 파일 경로>"
---

$ARGUMENTS 내용을 바탕으로 AI-SIP/OnO_FRONT 리포지토리에 GitHub 이슈를 생성한다.

**코드를 수정하지 않는다.**
**Assignee는 항상 `KiSeungMin`으로 지정한다.**
**이슈 본문은 `.github/ISSUE_TEMPLATE` 아래 템플릿 형식에 맞춘다.**

---

## 1단계 – 입력 파악

`$ARGUMENTS`가 파일 경로처럼 보이면 해당 파일을 읽어 내용을 파악한다.  
아니면 텍스트 그대로를 이슈 내용으로 사용한다.

입력 파일이 여러 개면 모든 내용을 그대로 붙이지 말고 이슈 생성에 필요한 핵심만 요약한다.

---

## 2단계 – 이슈 분류

먼저 아래 템플릿을 읽고, 입력 내용을 보고 **템플릿**, **label**, **type**을 결정한다.

- `.github/ISSUE_TEMPLATE/bug-report-template.md`
- `.github/ISSUE_TEMPLATE/common-issue-template.md`

| 내용 성격 | 템플릿 | label 후보 | type 후보 | title 접두사 |
|---|---|---|---|---|
| 비정상 동작, 크래시, 오류, 화면 깨짐 | Bug Report | `bug` | `Bug` | `[bug]` |
| 새 기능, 화면, API 연동 | Common Issue | `feature`, `enhancement` | `Feature` | `[feat]` |
| 사용성, UI/UX, 문구 개선 | Common Issue | `enhancement` | `Feature` | `[improve]` |
| 성능 개선, 코드 정리 | Common Issue | `refactor` | 없음 | `[refactor]` |
| 배포, 설정, 문서, 의존성 | Common Issue | `chore`, `documentation`, `docs` | 없음 | `[chore]` |
| 테스트 추가/수정 | Common Issue | `test` | 없음 | `[test]` |

가능하면 저장소에 존재하는 label/type을 먼저 확인한다. 존재 여부를 확인할 수 없거나 유효성 오류가 우려되면 label/type은 생략하고 제목 접두사와 본문으로 의도를 명확히 한다. 모호하면 가장 가까운 common 이슈로 판단하고 `ETC`에 확인 필요 사항을 남긴다.

---

## 3단계 – 이슈 본문 작성

### Bug Report 템플릿 (`label: bug`)

```
## ⚙️ 어떤 버그인가요?

<입력 내용을 바탕으로 간결하게 설명>

### 스크린샷(선택)

## 🔎 어떤 상황에서 발생한 버그인가요?

> Given: <전제 상황>
> When: <어떤 행동을 했을 때>
> Then: <어떤 문제가 발생했는지>

## ✅ 예상 결과

<정상적으로 동작했어야 하는 결과>
```

### Common Issue 템플릿 (`label: feature / refactor / chore / test`)

```
## 📝 Description

<입력 내용을 바탕으로 작업 설명>

## ✅ TODO

- [ ] <핵심 작업 1>
- [ ] <핵심 작업 2>
(입력 내용에서 파악 가능한 TODO를 최대한 구체적으로 작성)

## 💡 ETC (선택)

<입력 내용에서 기타 고려사항이 있으면 작성, 없으면 생략>
```

---

## 4단계 – GitHub 이슈 생성

`mcp__github__issue_write` 툴로 이슈를 생성한다.

- **owner**: `AI-SIP`
- **repo**: `OnO_FRONT`
- **method**: `create`
- **assignees**: `["KiSeungMin"]` (항상 고정)
- **title**: `[접두사] <한 줄 요약>` 형식
- **labels**: 위 분류 기준에 따라 설정하되, 저장소에 존재하는 label만 사용
- **type**: 저장소가 지원하고 유효한 type일 때만 설정
- **body**: 3단계에서 작성한 본문

---

## 5단계 – 결과 보고

생성된 이슈 번호와 URL, 적용한 템플릿/type/label/assignee를 사용자에게 알린다.
