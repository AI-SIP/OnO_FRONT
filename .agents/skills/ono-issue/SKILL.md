---
name: ono-issue
description: OnO Flutter 레포에서 사용자가 "/issue <내용>" 또는 "issue <내용>"을 입력하면 GitHub 이슈 템플릿에 맞춰 AI-SIP/OnO_FRONT 이슈를 생성한다. 파일 경로가 주어지면 파일 내용을 읽어 이슈 내용을 구성한다.
---

# OnO Issue Skill

사용자가 `/issue <내용>` 또는 `issue <내용>` 형태로 요청하면 이 Skill을 따른다.

## 목표

사용자가 자유롭게 적은 설명이나 전달한 파일 내용을 바탕으로 `AI-SIP/OnO_FRONT` GitHub Repository에 실제 이슈를 생성한다. 이슈는 `.github/ISSUE_TEMPLATE` 아래 템플릿 형식에 맞춰 작성한다.

## 고정값

- Repository: `AI-SIP/OnO_FRONT`
- Assignee: `KiSeungMin`
- 생성 도구: 가능한 경우 GitHub MCP의 `issue_write` create 작업을 사용한다.

## 절차

1. 사용자 입력에서 이슈 원문과 파일 경로를 구분한다.
2. 파일 경로가 있으면 해당 파일을 읽고, 여러 파일이면 이슈 작성에 필요한 핵심 내용만 요약한다.
3. `.github/ISSUE_TEMPLATE/bug-report-template.md`와 `.github/ISSUE_TEMPLATE/common-issue-template.md`를 읽는다.
4. 내용이 실제 버그, 오류, 크래시, 화면 깨짐, 재현 조건, 예상/실제 결과를 포함하면 bug 템플릿을 선택한다.
5. 기능 추가, 개선, 리팩터링, 문서화, 작업 TODO 성격이면 common 템플릿을 선택한다.
6. 사용자가 타입을 명시하지 않았으면 아래 기준으로 제목 prefix, label, type을 추론한다.
7. 추론이 어려워도 이슈 생성이 가능하면 가장 보수적인 common 이슈로 생성하고, 본문 `ETC`에 확인 필요 사항을 남긴다.
8. GitHub 이슈를 생성한 뒤 이슈 번호, URL, 적용한 template/type/label/assignee를 보고한다.

## 타입과 라벨 추론

- 버그, 오류, 크래시, 예외, 화면 깨짐, 동작 불일치: 제목 prefix `[bug]`, label `bug`, type은 저장소가 지원하면 `Bug`
- 새 기능, 사용자 기능 추가, 화면 추가: 제목 prefix `[feat]`, label은 저장소에 `feature` 또는 `enhancement`가 있으면 적용, type은 저장소가 지원하면 `Feature`
- UI/UX 개선, 문구 개선, 사용성 개선: 제목 prefix `[improve]`, label은 저장소에 `enhancement`가 있으면 적용
- 리팩터링, 구조 정리: 제목 prefix `[refactor]`, label은 저장소에 `refactor`가 있으면 적용
- 문서, README, 명세: 제목 prefix `[docs]`, label은 저장소에 `documentation` 또는 `docs`가 있으면 적용
- 설정, 빌드, 의존성, 기타 작업: 제목 prefix `[chore]`, label은 저장소에 `chore`가 있으면 적용

저장소에 어떤 label/type이 존재하는지 확인할 수 있는 도구가 있으면 먼저 조회한다. 확인할 수 없거나 유효성 오류가 우려되면 label/type은 생략하고 제목 prefix와 본문으로 의도를 명확히 한다.

## 본문 작성 규칙

### Bug Report Template

아래 항목을 채운다.

- `## ⚙️ 어떤 버그인가요?`: 한두 문장으로 버그 요약
- `### 스크린샷(선택)`: 사용자가 스크린샷이나 이미지 경로를 제공한 경우만 언급
- `## 🔎 어떤 상황에서 발생한 버그인가요?`: 재현 조건을 Given-When-Then 또는 번호 목록으로 정리
- `## ✅ 예상 결과`: 기대 동작을 사용자 관점으로 작성

알 수 없는 항목은 지어내지 않고 `확인 필요`로 표시한다.

### Common Issue Template

아래 항목을 채운다.

- `## 📝 Description`: 작업 목표와 배경을 짧게 정리
- `## ✅ TODO`: 실행 가능한 작업 항목을 체크박스로 작성
- `## 💡 ETC (선택)`: 참고 파일, 확인 필요 사항, API/디자인/반응형 주의점이 있을 때만 작성

TODO는 과하게 쪼개지 말고 실제 구현자가 바로 이해할 수 있는 단위로 작성한다.

## 주의

- 실제 운영 중인 앱 기준으로 사용자 영향, 반응형, API 계약, null/빈 상태/에러 상태 위험을 본문에 필요한 만큼 포함한다.
- 사용자가 준 내용을 과장하거나 임의 요구사항을 추가하지 않는다.
- 제목은 짧고 구체적으로 작성한다.
- 한국어 문구는 자연스럽고 간결하게 작성한다.
- GitHub 생성에 실패하면 오류 원인과 필요한 권한을 짧게 보고한다.
