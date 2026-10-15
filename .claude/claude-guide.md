# OnO_FRONT Claude Code 사용 가이드

> OnO Flutter 프론트엔드 레포에서 Claude Code를 사용하는 방법과 설정 전체를 정리한 문서.

---

## 목차

1. [설정 파일 구조](#1-설정-파일-구조)
2. [스킬 10종](#2-스킬-10종)
3. [전문가 에이전트 6종](#3-전문가-에이전트-6종)
4. [권한 설정](#4-권한-설정)
5. [훅](#5-훅)
6. [작업 파이프라인 권장 흐름](#6-작업-파이프라인-권장-흐름)

---

## 1. 설정 파일 구조

```
OnO_FRONT/
├── CLAUDE.md                          ← 프로젝트 지침 (Claude가 항상 읽음)
├── AGENTS.md                          ← Codex 용 작업 지침 (git 제외, 각자 로컬)
├── .mcp.json                          ← 프로젝트 MCP 서버 (dart mcp-server)
├── .agents/skills/ono-*/SKILL.md      ← 스킬 절차 본문의 정본 (Codex 는 바로, Claude 는 래퍼로 읽음)
└── .claude/
    ├── settings.json                  ← 팀 공유 권한·훅 (git 포함)
    ├── settings.local.json            ← 개인 권한 설정 (git 제외)
    ├── hooks/dart_check.sh            ← 편집 후 dart 파일 analyze 훅
    ├── skills/<이름>/SKILL.md          ← 슬래시 명령 래퍼 (analysis, plan, feat, check, commit,
    │                                      pr, issue, explain, release, sim). 정본을 읽게 하고
    │                                      Claude 전용 설정과 에이전트 위임만 둔다
    └── agents/                        ← 전문가 서브에이전트
        ├── code-tracer.md
        ├── perf-reviewer.md
        ├── logic-reviewer.md
        ├── side-effect-checker.md
        ├── permission-auditor.md
        └── report-writer.md

~/.claude/
└── settings.json                      ← 글로벌 설정 (알림 훅 포함)
```

**설정 우선순위**: 로컬(`.claude/settings.local.json`) > 프로젝트(`.claude/settings.json`) > 글로벌(`~/.claude/settings.json`). 단 권한은 어느 파일에 있든 deny → ask → allow 순서로 먼저 걸리는 규칙이 이긴다.

---

## 2. 스킬 10종

Claude Code 프롬프트 입력창에서 `/명령어` 형태로 호출한다. 예전 `.claude/commands/*.md` 는 `.claude/skills/<이름>/SKILL.md` 로 옮겼고, 호출 이름은 그대로다.

**절차 본문은 한 곳에만 있다.** `.claude/skills/<이름>/SKILL.md` 는 레포 루트의 `.agents/skills/ono-<이름>/SKILL.md`(Codex 가 쓰는 파일)를 Read 로 읽고 따르라는 래퍼다. 래퍼에는 `argument-hint`, `disable-model-invocation`, `$ARGUMENTS`, 에이전트 위임처럼 Claude Code 에만 있는 것만 둔다. 절차를 고칠 때는 정본만 고친다. 왜 이렇게 나눴는지는 `.agents/README.md` 의 「Claude Code 와 나눠 쓰는 구조」에 있다.

**자동 호출**: `/analysis`, `/check`, `/explain` 은 읽기 전용이라 Claude 가 요청 내용을 보고 알아서 부를 수 있다. 나머지는 파일을 쓰거나 커밋, push, 이슈 생성, 시뮬레이터 실행 같은 부수효과가 있어서 `disable-model-invocation: true` 로 막아 두었고, 사람이 `/이름` 으로 불러야만 돈다.

### 명령어 한눈에 보기

| 명령어 | 목적 | 코드 수정 | 커밋 실행 | 자동 호출 |
|---|---|:---:|:---:|:---:|
| `/analysis` | 문제 원인 규명 및 병렬 조사 | ✗ | ✗ | ✓ |
| `/plan` | 구현 명세서 작성 | ✗ | ✗ | ✗ |
| `/feat` | plan 기반 기능 구현 | ✓ | ✗ | ✗ |
| `/check` | 다관점 검증 및 위험도 분류 | ✗ | ✗ | ✓ |
| `/commit` | 논리 단위로 나눠 실제 커밋 | ✗ | ✓ | ✗ |
| `/pr` | 필요 시 push 후 develop 대상 PR 생성 | ✗ | ✗ | ✗ |
| `/issue` | GitHub 이슈 생성 | ✗ | ✗ | ✗ |
| `/release` | 출시 전 검증, 버전 올림 커밋, 업데이트 내역 | ✓ (pubspec 버전만) | ✓ (버전 올림만) | ✗ |
| `/explain` | 코드 흐름·원리 설명 | ✗ | ✗ | ✓ |
| `/sim` | 시뮬레이터에 띄워 화면 확인 | ✗ | ✗ | ✗ |

merge, `main`/`develop` 직접 push, force push, 스토어 업로드는 어떤 명령도 하지 않는다. 사용자가 명시적으로 요청할 때만 한다.

---

### `/analysis [문제 설명]`

**언제**: 버그가 생겼는데 원인을 모를 때, 특정 동작이 왜 그렇게 되는지 파악할 때.

**동작 흐름**:
1. 문제 상황, 원하는 동작, 관련 경로를 먼저 확인 (이미 알면 생략)
2. 문제를 4개 차원으로 분해 (위젯·상태 흐름 / API·데이터 / 비동기·타이밍 / 플랫폼 차이)
3. `code-tracer` 에이전트와 병렬로 각 차원 조사
4. 결과를 교차 반증해 모순·허점 제거
5. 요약 + 근거(`파일:라인`) + 원인 목록(확신도 포함) 보고

**사용 예**:
```
/analysis 오답노트 목록에서 간헐적으로 빈 화면이 뜨는 현상
/analysis 로그인 후 첫 화면 진입 시 API가 두 번 호출됨
```

**출력**:
```
## 요약
## 근거 (파일:라인)
## 원인 목록 (확신도: 높음/중간/낮음)
## 확인이 필요한 부분
```

---

### `/plan <기능 설명>`

**언제**: 새 기능을 구현하기 전에 명세서를 먼저 만들 때. `/feat` 실행 전에 항상 거치는 것을 권장.

**동작 흐름**:
1. `docs/`에서 관련 문서 먼저 확인
2. `code-tracer` 에이전트로 관련 위젯·상태 흐름 파악
3. `docs/` 하위에 기능명 폴더 생성 후 markdown 명세서 작성
4. 명세서 완성 후 검토 요청 → `/feat` 전에 대기

**저장 위치**: `docs/<기능명>/명세서.md` (기존 한글 폴더 스타일 따름)

**명세서 구성**: 요구사항 / 영향 범위 / API·상태 관리 / 반응형 고려사항 / 구현 단계(순서) / 배포 리스크 / 검증 방법

**사용 예**:
```
/plan 오답 복습 달력 주간 뷰 추가
/plan PDF 내보내기 로딩 상태 개선
```

> ⚠️ 코드를 수정하지 않는다. 명세서만 작성하고 검토를 기다린다.

---

### `/feat [명세서 경로 또는 기능명]`

**언제**: `/plan`으로 만든 명세서를 승인한 뒤 실제 구현할 때.

**동작 흐름**:
1. 어떤 명세서를 기준으로 할지 확인 (불명확하면 물어봄)
2. 명세서 + 현재 코드 확인 (차이가 있으면 설명)
3. 명세서 구현 단계를 순서대로 실행
4. 구현 후 바꾼 test 파일만 `dart format`, `flutter analyze --no-fatal-infos`(CI 기준) 실행, 관련 테스트가 있으면 `flutter test`
5. 변경 내용·사용자 영향·반응형 처리·검증 결과·리스크·추천 커밋 보고 (커밋은 하지 않음)

**구현 규칙**:
- 명세서 범위만 수정 (무관한 리팩터링·포맷팅 금지)
- 주변 코드 스타일·패턴 그대로 따름
- null safety, async, 에러/로딩/빈 상태 챙김
- API 계약 불명확 시 임의 단정 금지

**커밋 메시지 형식** (제안만, 커밋은 `/commit` 에서):
```
[Feat] 한 줄 요약 - 상세1 상세2 (#이슈번호)
```

---

### `/check [커밋 해시]`

**언제**: 구현 완료 후 출시 전에 코드를 다각도로 검증할 때. 커밋 해시 없으면 현재 변경사항만 검토.

**동작 흐름**:
1. `git diff` 로 변경된 파일과 사용자 흐름 파악
2. 아래 에이전트를 **병렬** 실행:
   - `perf-reviewer`: 불필요한 rebuild, jank, 메모리 이슈
   - `logic-reviewer`: null safety, async 경합, 상태 전이, 에러 처리
   - `side-effect-checker`: API 중복 호출, 로컬 저장 부작용, FCM
   - `permission-auditor`: 화면 접근 제어 (로그인, 토큰, 라우팅 변경이 있을 때)
   - 반응형 UI 변경은 맡길 에이전트가 없어 직접 확인
3. `flutter analyze --no-fatal-infos` 실행
4. 에이전트 결과를 교차 반증
5. 위험도 분류 보고

**사용 예**:
```
/check                   ← 현재 변경사항 검토
/check a1b2c3d           ← 해당 커밋부터 HEAD까지 검토
```

**출력 위험도**:
- 🔴 즉시 수정 필요
- 🟠 출시 전 수정 권장
- 🟡 주의 필요 (트레이드오프 존재)
- 🟢 이상 없음

---

### `/commit [맥락 설명]`

**언제**: 구현이 끝나 변경사항을 커밋할 때.

**동작 흐름**:
1. `git status` / `git diff` / `git diff --staged` 확인
2. 기능 추가·버그 수정·스타일·설정 변경 등을 논리 단위로 분리
3. 각 단위를 `git add <파일>` + `git commit` 으로 **실제 커밋** (호출 자체가 요청이라 따로 확인받지 않음)
4. `main`/`develop` 브랜치이거나 비밀 파일, 무관한 변경이 섞여 있으면 커밋하지 않고 보고

> push 와 PR 생성은 하지 않는다. `/pr` 에서 한다.

**실행 예**:
```
git add lib/Screen/PracticeNote/PracticeDetailScreen.dart
git commit -m "[Feat] 복습 세트 상세에 다시 풀기 버튼 추가 - 태블릿 가로 배치 대응 (#382)"
```

---

### `/pr <기준 커밋 해시>`

**언제**: 기능 브랜치 작업을 커밋까지 마치고 develop 에 PR 을 올릴 때.

**동작 흐름**:
1. 브랜치가 `main`/`master`/`develop` 이거나 커밋 안 된 변경이 있으면 중단
2. `git log <해시 또는 origin/develop>..HEAD` + diff 로 변경 내역 파악
3. 연관 open 이슈 검색 → 명확하면 `close #번호`
4. `.github/PULL_REQUEST_TEMPLATE.md` 양식으로 본문 작성
5. 원격 브랜치가 없거나 push 안 된 커밋이 있으면 `git push -u origin <브랜치>:<브랜치>`
6. `develop` 대상 PR 을 **확인 없이 바로 생성**, assignee `KiSeungMin`, 있는 label 만 추가

> ⚠️ merge 하지 않는다. `main` 대상 PR 은 만들지 않는다.

---

### `/issue <이슈 설명 또는 파일 경로>`

**언제**: 작업 전에 GitHub 이슈를 만들 때.

**동작 흐름**: 입력을 읽고 `.github/ISSUE_TEMPLATE` 의 버그/공통 템플릿 중 하나를 골라 본문 작성 → 있는 label 만 붙여 `AI-SIP/OnO_FRONT` 에 생성, assignee `KiSeungMin`. 코드는 수정하지 않는다.

---

### `/release <출시 버전> [기준]`

**언제**: 앱스토어/플레이스토어 제출 직전.

**동작 흐름**:
1. `origin/develop` 에서 `release/<버전>` 브랜치
2. `flutter analyze --no-fatal-infos` (warning·error 0개) → `flutter test` → 에이전트 4종 병렬 검증
3. 🟢 배포 가능이면 `pubspec.yaml` 버전 올림 커밋 (`[Chore] 4.1.1 출시 버전으로 올린다 - 4.1.1+75` 형식)
4. 스토어에 붙여 넣을 업데이트 내역 초안 작성
5. 릴리스 빌드 명령과 단계적 출시 방법을 **안내만** 한다

> ⚠️ 릴리스 빌드 업로드, 스토어 제출, `main` merge 는 사람이 한다.

---

### `/explain <파일명, 위젯명, 또는 기능 설명>`

**언제**: 낯선 코드를 이해할 때, 특정 위젯의 데이터가 어디서 오는지 파악할 때, 팀원에게 설명 전 흐름을 정리할 때.

**동작 흐름**:
1. `code-tracer` 에이전트와 함께 진입점부터 추적
   - 위젯 트리: 어디서 시작 → 어느 자식까지
   - 상태 관리: 상태 정의 → 변경 트리거 → UI 반영
   - API 경로: UI 이벤트 → 서비스 → 엔드포인트
2. 단계별로 `파일:라인` 인용 + 설계 의도·트레이드오프 설명
3. 흐름 요약 + 핵심 설계 이유 + 주의할 동작 정리

**사용 예**:
```
/explain lib/Screen/PracticeNote/PracticeDetailScreen.dart
/explain 오답노트 목록 로딩 흐름
/explain AuthProvider
```

---

### `/sim [ios|android] [화면 설명]`

**언제**: 바꾼 화면을 실제 앱으로 띄워 보고 싶을 때.

**동작 흐름**:
1. `.env` 가 있는지, 실기기가 아닌 시뮬레이터나 에뮬레이터가 있는지 확인 (`.env` 내용은 출력하지 않음)
2. 시뮬레이터 부팅 후 `flutter run -d <UDID> --dart-define=ENV=dev` 를 백그라운드로 실행. 로그와 pid 파일은 레포 밖(scratchpad 나 `/tmp/ono-sim`)에 둠
3. 스크린샷을 찍어 직접 열어 보고, 로그의 에러 줄도 확인
4. 사용자가 직접 눌러 볼 체크리스트로 넘김. 앱 안을 누르거나 입력하지는 못함

**hot reload**: `kill -USR1 $(cat <pid 파일>)`. Dart MCP(`.mcp.json` 의 `dart`)의 `hot_reload` 는 터미널에서 띄운 앱에 붙지 못해서 `analyze_files`, `run_tests` 같은 정적 도구로만 쓴다.

> ⚠️ 실기기 설치, `--release` 빌드, `ENV=prod` 실행, 앱 코드 수정은 하지 않는다.

---

## 3. 전문가 에이전트 6종

스킬 래퍼(`.claude/skills/*`)에서 Claude가 자동으로 호출하는 서브에이전트. 직접 호출할 수도 있지만 보통 스킬이 알아서 쓴다.

모든 검증·조사 에이전트는 **읽기 전용** — 코드를 수정하거나 커밋하지 않는다.

---

### `code-tracer`

**역할**: 위젯 트리·상태 관리·API 호출 흐름을 지도로 만든다.

**사용하는 명령어**: `/analysis`, `/plan`, `/explain`

**추적 방향**:
- 위젯 트리: 진입 위젯 → 자식 → 상태 소비 위젯
- 상태 관리: 상태 정의 위치 → 변경 트리거 → UI 반영
- API 호출: UI 이벤트 → 서비스/레포지토리 → HTTP → 엔드포인트

**출력**:
```
[진입점 파일:라인]
  └→ [다음 단계 파일:라인] — 설명
       └→ [다음 단계 파일:라인] — 설명
```

---

### `perf-reviewer`

**역할**: Flutter 성능 문제를 찾는다.

**사용하는 명령어**: `/check`, `/release`

**검토 항목**:
- **불필요한 rebuild**: `setState` 범위, `const` 분리 미적용, 너무 넓은 `Provider.of`/watch
- **jank**: `build()` 안 무거운 연산, 메인 스레드 동기 I/O
- **메모리·이미지**: 컨트롤러 `dispose` 누락, Stream 누수, 이미지 캐시 미사용
- **리스트**: `ListView` → `ListView.builder` 미전환

---

### `logic-reviewer`

**역할**: 비즈 로직 정합성을 검증한다.

**사용하는 명령어**: `/check`, `/release`

**검토 항목**:
- **null safety**: `!` 강제 언래핑 위험, `?.` 조용한 무시, API nullable 미방어
- **async 경합**: `mounted` 체크 누락, Future 순서 미보장, `await` 누락
- **상태 전이**: 로딩→성공→에러→빈 상태 전환 누락, 재진입 시 초기화 여부
- **에러 처리**: catch 후 삼킴, 기술적 에러 메시지 노출

---

### `side-effect-checker`

**역할**: 의도치 않은 외부 영향과 부작용을 찾는다.

**사용하는 명령어**: `/check`, `/release`

**검토 항목**:
- **API 중복 호출**: build/initState 중복, 버튼 debounce 미적용, 페이지네이션 중복
- **로컬 저장**: SharedPreferences 덮어씌움, 민감 정보 평문 저장
- **FCM**: 토큰 갱신 중복 실행, 실사용자 알림 발송 경로 영향
- **화면 이탈**: 타이머·구독 미정리, 이전 세션 상태 잔류

---

### `permission-auditor`

**역할**: 화면 접근 제어와 인증 흐름을 검증한다.

**사용하는 명령어**: `/check` (로그인, 토큰, 라우팅 변경 포함 시), `/release`

> 데이터 격리(남의 오답노트 접근 차단)는 백엔드 책임. 여기서는 앱 화면·네비게이션 레벨만 검토.

**검토 항목**:
- **화면 접근**: 비로그인 사용자가 인증 필요 화면 접근 가능 여부, 딥링크 우회
- **토큰·세션**: 만료 시 리디렉션 여부, 로그아웃 시 정리 여부
- **라우팅**: 뒤로 가기로 인증 전 화면 접근 가능 여부

---

### `report-writer`

**역할**: 기술적 변경사항을 비기술적 언어로 보고서화한다.

**사용하는 명령어**: 없음. 보고서나 비기술적 요약을 직접 요청할 때 부른다.

**작성 원칙**: 존댓말, 핵심 위주, 기술 용어 최소화, Before/After 표 활용

---

### 스킬 ↔ 에이전트 매핑

| 스킬 | 사용 에이전트 |
|---|---|
| `/analysis` | `code-tracer` |
| `/plan` | `code-tracer` |
| `/check` | `perf-reviewer`, `logic-reviewer`, `side-effect-checker` (+로그인·토큰·라우팅 변경 시 `permission-auditor`) |
| `/release` | `perf-reviewer`, `logic-reviewer`, `side-effect-checker`, `permission-auditor` |
| `/explain` | `code-tracer` |
| `/feat`, `/commit`, `/pr`, `/issue`, `/sim` | (없음) |
| (직접 요청) | `report-writer` |

---

## 4. 권한 설정

`.claude/settings.json` — 팀 공유, git 에 포함. 개인 허용 목록은 `.claude/settings.local.json`(git 제외)에 따로 둔다.

### 차단 (deny)

| 차단 항목 | 이유 |
|---|---|
| 비밀 파일 읽기 (`.env`, 서명 키와 인증서, 프로비저닝 파일) | 공개 레포라 대화나 PR 에 섞여 나가면 안 된다 |
| `mcp__github__merge_pull_request`, `gh pr merge` | merge 는 사람이 한다 |
| `git push origin main*`, `git push origin develop*` | 보호 브랜치 직접 push 금지 |
| `git push --force*`, `git push -f*` | 원격 히스토리 파괴 위험 |
| `gh issue delete` | 이슈 삭제는 되돌릴 수 없다 |
| `xcrun altool` | 스토어 업로드는 사람이 한다 |

### 확인 후 실행 (ask)

| 항목 | 이유 |
|---|---|
| `flutter build` | 릴리스 빌드는 시간이 길고 산출물이 업로드로 이어진다 |
| `gh release`, `gh workflow run` | 외부에 보이는 작업이다 |

> 권한은 어느 파일에 있든 deny → ask → allow 순서로 먼저 걸리는 규칙이 이긴다. 개인 local 에 allow 를 두어도 공유 deny/ask 를 넘지 못한다.

---

## 5. 훅

### 편집 후 dart 검사 (`.claude/settings.json`, 팀 공유)

`PostToolUse` 에서 `Edit|Write|MultiEdit` 뒤에 `.claude/hooks/dart_check.sh` 가 돈다.

1. 바꾼 파일이 `.dart` 가 아니거나 레포 밖이면 아무것도 하지 않는다
2. `test/` 아래 파일만 `dart format` (lib 는 기존 미포맷 파일이 많아 CI 도 test 만 검사)
3. 그 파일 하나만 `flutter analyze --no-fatal-infos --no-fatal-warnings` 로 보고, warning 이나 error 가 있으면 요약을 stderr 로 내고 exit 2 → Claude 가 바로 고친다
4. info 만 있거나 문제가 없으면 조용히 exit 0. `flutter`, `jq` 가 없으면 건너뛴다

### 알림 (`~/.claude/settings.json`, 개인 글로벌)

macOS 시스템 알림(`osascript`)을 사용한다. 추가 모듈 설치 불필요.

| 이벤트 | 트리거 시점 | 알림 메시지 |
|---|---|---|
| `Stop` | Claude가 작업을 완료했을 때 | "작업 완료" |
| `Notification` | 권한 승인·입력이 필요할 때 | "확인이 필요해요" |

두 훅 모두 `async: true` — 알림이 Claude 응답을 블로킹하지 않는다.

**설정 확인·수정**: `/hooks` 메뉴에서 언제든 변경 가능.

---

## 6. 작업 파이프라인 권장 흐름

### 일반 기능 구현

```
/plan <기능>  →  검토  →  /feat  →  /check  →  /commit  →  /pr
```

1. `/plan` — 명세서 작성, 코드 건드리지 않음
2. **검토** — 명세서 내용 확인 후 `/feat` 진행 승인
3. `/feat` — 구현 + 바꾼 test 파일 포맷 + `flutter analyze --no-fatal-infos` (커밋 안 함)
4. `/check` — 구현 결과 다관점 검증 (에이전트 병렬)
5. `/commit` — 논리 단위 분할 + 실제 커밋
6. `/pr [기준 커밋]` — 필요 시 push 후 develop 대상 PR 생성 (merge 는 사람)

### 출시

```
/release <버전>  →  release/<버전> 브랜치·검증·버전 올림 커밋  →  /pr  →  (사람) develop→main merge, 빌드 업로드, 심사 제출
```

### 버그 조사

```
/analysis <현상>  →  원인 파악  →  /feat  →  /check  →  /commit  →  /pr
```

### 코드 이해

```
/explain <대상>  →  흐름 파악
```

### 단계별 검토 강도

| 단계 | 강도 | 이유 |
|---|---|---|
| `/plan` 결과 검토 | 🔴 최고 | 방향이 잘못되면 구현 전체가 낭비 |
| `/feat` 완료 후 | 🟠 높음 | 코드가 명세서대로 나왔는지 확인 |
| `/check` 결과 | 🟡 중간 | 도구가 잡은 문제를 판단 |
| `/pr` 결과 | 🟢 낮음 | 문서 수준 확인 |

---

## 부록: 커밋 메시지 형식

```
[태그] 한 줄 요약 - 상세1 상세2 (#이슈번호)
```

| 태그 | 사용 시점 |
|---|---|
| `[Feat]` | 새 기능 추가 |
| `[Fix]` | 버그 수정 |
| `[Refactor]` | 동작 변경 없는 코드 개선 |
| `[Chore]` | 빌드·설정·의존성 변경 |
| `[Test]` | 테스트 코드 추가·수정 |
| `[Docs]` | 문서 변경 |

**예시**:
```
[Feat] 학습 달력 주간 뷰 추가 - 태블릿 레이아웃 대응 빈 상태 처리
[Fix] 오답노트 PDF 내보내기 오류 수정 - null 응답 방어 로딩 상태 개선
[Chore] flutter 3.22로 업그레이드
```
