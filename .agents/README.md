# OnO Front Codex 작업 모드

이 디렉터리는 OnO Flutter 프론트 레포에서 Codex가 사용할 레포 전용 Skill과 사용 설명을 담는다.

Codex의 예전 custom prompts 방식은 재사용 프롬프트를 슬래시 명령으로 등록하는 구조였지만, 현재는 Skill 사용이 권장된다. 이 레포에서는 `analysis`, `plan`, `feat`, `pr`, `check`, `commit`, `issue`, `explain`, `release`를 실제 CLI 명령이 아니라 Codex 작업 모드로 해석하고, `.agents/skills/ono-*` Skill이 그 동작을 정의한다.

## 파일 구조

```text
.agents/
  README.md
  skills/
    ono-analysis/SKILL.md
    ono-explain/SKILL.md
    ono-plan/SKILL.md
    ono-feat/SKILL.md
    ono-pr/SKILL.md
    ono-check/SKILL.md
    ono-commit/SKILL.md
    ono-issue/SKILL.md
    ono-release/SKILL.md
    ono-sim/SKILL.md
```

Codex는 레포 안에서 실행될 때 현재 디렉터리부터 레포 루트까지 `.agents/skills`를 스캔한다. 각 Skill은 `SKILL.md`의 front matter에 있는 `name`, `description`을 먼저 보고, 사용자 요청과 맞으면 본문을 읽어 적용한다.

## 공통 인자 생략 규칙

작업 모드에 인자를 넣지 않으면 기본적으로 현재 작업 중인 변경사항을 대상으로 수행한다.

현재 변경사항의 범위:

- `git status`에 잡히는 변경
- staged diff
- unstaged diff
- untracked 파일

예:

```text
check
commit
analysis
explain
pr
release
```

위 요청들은 별도 인자가 없어도 현재 변경사항(PR 은 `origin/develop..HEAD`)을 기준으로 검토, 분석, 설명, PR 생성, 커밋을 수행한다.

단, `plan`은 새 기능 설명이 없으면 명세서를 작성할 수 없으므로 사용자에게 기능 설명을 요청한다. `feat`는 인자가 없으면 최근 `docs` 명세서와 현재 변경사항을 확인해 기준 문서를 찾고, 하나로 명확하지 않으면 사용자에게 확인한다.

## 공통 자가 반증 규칙

`analysis`, `check`, `feat`, `release`는 1차 결론이나 구현 완료 후 반드시 한 번 스스로 반증한다.

자가 반증 질문:

- 내가 놓쳤을 가능성이 큰 것은 무엇인가
- 이 변경이 실제 사용자에게 깨질 수 있는 경로는 무엇인가
- 이 결론이 틀렸다면 어떤 조건 때문인가
- 문제가 있다고 본 코드가 실제 실행 경로에 도달 가능한가
- 문제가 없다고 본 코드가 null, 빈 응답, 느린 네트워크, 화면 이탈 상황에서도 안전한가

반증 결과 기존 결론이 약하면 확신도를 낮추거나 폐기한다. 새 위험이 발견되면 완료 보고나 검토 결과에 포함한다.

## 사용 가능한 작업 모드

| 입력 | Skill | 용도 | 결과물 |
|---|---|---|---|
| `analysis [문제 설명]` | `ono-analysis` | 문제 원인 규명, 버그 분석 | 원인 후보, 코드 근거, 확인 필요 항목 |
| `plan <기능 설명>` | `ono-plan` | 구현 전 기능 명세서 작성 | `docs/<기능 폴더>/<명세서>.md` |
| `feat [명세서 경로/기능명]` | `ono-feat` | `plan` 문서 기준 실제 구현 (커밋 안 함) | 코드 변경, 정적 검증 결과, 커밋 메시지 제안 |
| `check [커밋 번호]` | `ono-check` | 변경사항 위험 검토 | 위험도별 검토 결과 |
| `pr [커밋 해쉬]` | `ono-pr` | 필요 시 push 후 develop 대상 PR 생성 | GitHub PR |
| `commit` | `ono-commit` | 논리 단위로 나눠 실제 커밋 | 커밋 |
| `issue <설명/파일>` | `ono-issue` | GitHub 이슈 생성 | GitHub 이슈 |
| `explain [파일/위젯/기능]` | `ono-explain` | 코드 흐름과 설계 의도 설명 | 흐름 요약, 상태/API 흐름, 주의점 |
| `release <버전> [기준 커밋]` | `ono-release` | release 브랜치, 출시 전 검증, 버전 올림 커밋, 업데이트 내역 | 배포 판정, 버전 커밋, 복붙용 업데이트 내역 |
| `sim [ios\|android] [화면 설명]` | `ono-sim` | dev 서버로 시뮬레이터에 띄워 화면 확인 | 스크린샷 경로, 본 것, 사용자 확인 체크리스트 |

명시 호출이 필요하면 `$ono-analysis`, `$ono-plan`, `$ono-feat`, `$ono-check`, `$ono-pr`, `$ono-commit`, `$ono-issue`, `$ono-explain`, `$ono-release`, `$ono-sim`처럼 Skill 이름을 직접 언급한다.

## 동작 방식

### `analysis [문제 설명]`

문제 원인을 읽기 전용으로 조사하는 모드다. 코드를 수정하지 않는다.

동작 순서:

1. 인자가 없으면 현재 변경사항을 대상으로 잡는다.
2. 문제 현상, 원하는 동작, 관련 파일/위젯/API 경로가 충분한지 확인한다.
3. 문제를 위젯·상태 흐름, API·데이터 흐름, 비동기·타이밍, 플랫폼·화면 조건, 부작용 관점으로 나눈다.
4. 관련 문서와 코드 진입점을 찾는다.
5. 위젯 트리, 상태 변경, API 호출 경로를 `파일:라인` 근거로 추적한다.
6. 가능한 원인을 확신도별로 정리한다.
7. 각 원인을 다시 반증해 실제 도달 가능한지 확인한다.

출력은 요약, 근거, 원인 목록, 확인 필요 항목, 다음 조치 제안으로 구성한다.
보고 전에는 자가 반증을 수행하고 `자가 반증 결과`를 함께 적는다.

### `plan <기능 설명>`

구현 전에 명세서를 작성하는 모드다. 앱 코드는 수정하지 않는다.

동작 순서:

1. 요구사항을 정리하고 애매하면 먼저 확인한다.
2. `docs` 아래 기존 기획/명세/PR 문서를 확인한다.
3. 관련 코드의 화면 흐름, 상태 관리, 라우팅, API 연동 위치를 읽는다.
4. `docs` 아래 새 기능 폴더를 만든다.
5. 이후 `feat`가 바로 구현할 수 있을 정도로 구체적인 markdown 명세서를 작성한다.

명세서에는 사용자 영향, 화면 흐름, 수정 예상 파일, API/상태 관리 영향, null/빈 상태/에러 상태, 반응형 고려사항, 배포 리스크, 검증 방법, 구현 순서가 포함되어야 한다.

### `feat`

`plan`으로 만든 명세서를 기준으로 구현하는 모드다.

동작 순서:

1. 기준이 될 명세서를 확인한다.
2. 인자가 없으면 최근 `docs` 명세서와 현재 변경사항을 확인해 기준 문서를 찾는다.
3. 명세서가 여러 개라 모호하면 사용자에게 물어본다.
4. 실제 코드와 명세가 다르면 실제 코드 기준으로 판단하고 차이를 설명한다.
5. 구현 전 어떤 파일을 어떤 방향으로 바꿀지 짧게 공유한다.
6. 필요한 줄만 수정한다.
7. 바꾼 test 파일만 `dart format` 하고(lib 전체 포맷 금지, CI 도 test 만 검사) `flutter analyze --no-fatal-infos` 로 warning, error 0개를 확인한다. 관련 테스트가 있으면 `flutter test` 도 돌린다.
8. 화면 변경이면 폰/태블릿/가로세로 레이아웃 리스크를 검토한다.
9. 완료 보고 전 자가 반증을 수행한다.

사용자가 따로 요청하지 않으면 Flutter 테스트 코드를 새로 만들지 않는다. 다만 바꾼 동작을 검사하는 기존 테스트(`test/`)가 깨지면 함께 고친다.

커밋은 하지 않는다. 커밋은 사용자가 `commit` 을 요청할 때 한다.

### `check [커밋 번호]`

변경사항을 운영 앱 관점에서 검토하는 모드다.

동작 순서:

1. 커밋 번호가 있으면 해당 커밋부터 현재까지 diff를 본다.
2. 커밋 번호가 없으면 현재 작업 중인 변경사항을 본다.
3. 변경된 파일과 영향받는 사용자 흐름을 기준으로 검토한다.
4. 1차로 diff 기반 위험을 찾는다.
5. 2차로 1차 결론을 반증한다. 실제 도달 가능한지, 상위 조건에서 막히지 않는지 다시 본다.
6. 가능한 경우 `flutter analyze --no-fatal-infos`를 실행한다(CI 기준, info 제외). 파일을 수정하지 않으므로 `dart format` 은 `--output=none --set-exit-if-changed` 로 검사만 한다.

검토 관점:

- null safety와 런타임 예외
- API 계약, 응답 필드, 에러 응답, 중복 요청
- 상태/async 경합
- 로딩/빈 상태/에러 상태
- 작은 폰, 일반 폰, 태블릿, 가로/세로 화면 overflow
- 앱스토어/플레이스토어 배포 후 롤백이 어려운 리스크
- 기존 데이터, 학습 기록, 결제/인증/동기화 흐름 영향

보고는 `🔴`, `🟠`, `🟡`, `🟢` 위험도 순서로 한다.
보고 마지막에는 자가 반증 결과를 짧게 포함한다.

### `pr [커밋 해쉬]`

현재 브랜치를 `develop` 에 merge 요청하는 GitHub PR 을 실제로 만드는 모드다.

동작 순서:

1. 현재 브랜치가 `main`, `master`, `develop` 이거나 커밋 안 된 변경이 있으면 중단하고 보고한다.
2. 기준 커밋이 있으면 `<커밋>..HEAD`, 없으면 `origin/develop..HEAD` 의 로그와 diff 를 본다.
3. 관련 open 이슈를 검색해 명확하면 `close #번호` 를 넣는다.
4. `.github/PULL_REQUEST_TEMPLATE.md` 형식으로 본문을 쓴다.
5. 원격 브랜치가 없거나 push 안 된 커밋이 있으면 `git push -u origin <브랜치>:<브랜치>` 로 올린다.
6. 사용자 확인 없이 `develop` 대상 PR 을 만들고 assignee `KiSeungMin`, 있는 label 만 붙인다.

merge, `main`/`develop` 직접 push, force push 는 사용자가 명시적으로 요청할 때만 한다.

### `commit`

현재 변경사항을 논리 단위로 나눠 실제로 커밋하는 모드다.

동작 순서:

1. `git status`와 diff를 확인한다.
2. 기능/수정/문서/설정 단위로 변경을 묶는다.
3. 관련 없는 변경이 섞여 있으면 분리 커밋한다.
4. 단위마다 `git add <파일>` 과 `git commit` 을 실행한다. `commit` 요청 자체가 커밋 요청이라 따로 확인받지 않는다.
5. `main`/`develop` 브랜치이거나, 비밀 파일이나 빌드 산출물이 섞였거나, 어디까지 커밋할지 불분명하면 커밋하지 않고 보고한다.

push 와 PR 생성은 하지 않는다. `pr` 에서 한다.

커밋 메시지 형식:

```text
[Feat] 구현 타이틀 - 구현 상세1 구현 상세2 (#이슈번호)
```

태그는 `[Feat]`, `[Fix]`, `[Refactor]`, `[Chore]`, `[Test]`, `[Docs]` 중 변경 성격에 맞춰 선택한다.

### `release <버전> [기준 커밋]`

앱스토어/플레이스토어 제출 직전까지 준비하는 모드다. 자세한 절차는 `ono-release` Skill 과 `.claude/commands/release.md` 가 같다.

동작 순서:

1. `origin/develop` 에서 `release/<버전>` 브랜치를 만든다(`--no-track`).
2. 기준 커밋이 없으면 직전 `origin/release/*` 이후 범위를 보고, 명확하지 않으면 확인한다.
3. `flutter analyze --no-fatal-infos` 로 warning, error 0개, `flutter test` 통과를 확인한다.
4. diff 위험, API 계약, null 처리, 인증/동기화/FCM 부작용, 폰/태블릿 반응형 리스크를 검토한다.
5. 배포 가능이면 `pubspec.yaml` 버전을 올려 `[Chore] <버전> 출시 버전으로 올린다 - <버전>+<빌드>` 로 커밋한다.
6. 배포 판정과 업데이트 내역 초안을 함께 보고한다.

업데이트 내역은 앱스토어/플레이스토어에 바로 붙여 넣을 수 있도록 번호 목록과 짧은 bullet로 작성한다. 내부 구현명, 클래스명, API명, PR 번호, 커밋 해시는 포함하지 않는다.

릴리스 빌드 업로드, 스토어 제출, `main` merge, tag 생성은 사람이 한다.

### `explain [파일/위젯/기능]`

낯선 Flutter 코드를 학습용으로 이해하는 모드다. 코드를 수정하지 않는다.

동작 순서:

1. 지정한 파일, 위젯, 기능명을 기준으로 진입점을 찾는다. 인자가 없으면 현재 변경된 파일을 진입점으로 삼는다.
2. 위젯 트리, 상태 관리, API 호출 경로를 `파일:라인` 근거로 추적한다.
3. 실행 순서대로 흐름을 설명한다.
4. 왜 이렇게 구현되어 있는지 설계 의도와 트레이드오프를 설명한다.
5. 수정할 때 조심해야 할 동작을 정리한다.

출력은 흐름 요약, 상태와 데이터 흐름, 핵심 설계 이유, 주의할 동작, Flutter 개념 메모로 구성한다.

## Claude 설정에서 이식한 항목

`.claude/commands`와 비교해 `.agents`에 없던 작업 모드 중 다음을 추가했다.

- `.claude/commands/analysis.md` -> `.agents/skills/ono-analysis/SKILL.md`
- `.claude/commands/explain.md` -> `.agents/skills/ono-explain/SKILL.md`

`.claude/agents`의 전문 에이전트 관점은 Codex Skill에 다음처럼 흡수되어 있다.

- `code-tracer`: `ono-analysis`, `ono-explain`의 흐름 추적 관점
- `perf-reviewer`: `ono-check`, `ono-release`의 rebuild, jank, 메모리, 리스트 검토 관점
- `logic-reviewer`: `ono-check`의 null safety, async, 상태 전이, 에러 처리 관점
- `side-effect-checker`: `ono-check`, `ono-analysis`, `ono-release`의 API 중복 호출, 로컬 저장소, FCM 부작용 관점
- `permission-auditor`: `ono-check`, `ono-release`의 화면 접근 제어와 인증 흐름 관점
- `report-writer`: 현재 별도 Codex Skill로 만들지 않았다. PR/완료 보고는 `ono-pr`, `ono-feat`, `ono-commit`에 필요한 범위만 포함한다.

## 현재 Codex 설정

현재 사용자 레벨 설정은 `~/.codex/config.toml`에 있다. 프로젝트 로컬 `.codex/config.toml`이 아니라 사용자 레벨 설정이므로, 이 Mac의 Codex 세션 전체에 적용된다.

핵심 설정:

```toml
model = "gpt-5.5"
model_reasoning_effort = "medium"
remote_connections = true
approval_policy = "on-request"
approvals_reviewer = "guardian_subagent"
sandbox_mode = "workspace-write"
```

의미:

- 기본 모델은 `gpt-5.5`다.
- 기본 추론 강도는 `medium`이다.
- 기본 sandbox는 `workspace-write`라서 레포 작업공간 안의 파일 수정은 가능하다.
- 권한이 필요한 명령은 `on-request`로 승인 요청을 띄운다.
- 승인 검토자는 현재 `guardian_subagent`로 설정되어 있다.
- 이 레포 `/Users/ksm/programing/sw_maestro/OnO_FRONT`는 trusted project로 등록되어 있다.

## 프로파일

`~/.codex/review.config.toml`:

```toml
model_reasoning_effort = "xhigh"
sandbox_mode = "read-only"
approval_policy = "on-request"
```

검토, 분석, 계획처럼 쓰기 작업이 필요 없는 세션에 쓴다.

사용 예:

```bash
codex --profile review
```

`~/.codex/build.config.toml`:

```toml
model_reasoning_effort = "high"
sandbox_mode = "workspace-write"
approval_policy = "on-request"
```

구현, 포맷, 정적 검증처럼 파일 수정이 필요한 세션에 쓴다.

사용 예:

```bash
codex --profile build
```

## 알림 설정

작업 완료와 권한 승인 요청을 놓치지 않도록 macOS 알림이 설정되어 있다.

완료 알림:

```toml
notify = [
  "/Users/ksm/.codex/scripts/codex-notify-macos.sh",
  "/Users/ksm/.codex/computer-use/Codex Computer Use.app/Contents/SharedSupport/SkyComputerUseClient.app/Contents/MacOS/SkyComputerUseClient",
  "turn-ended"
]
```

권한 승인 요청 알림:

```toml
[[hooks.PermissionRequest]]
matcher = "*"

[[hooks.PermissionRequest.hooks]]
type = "command"
command = "/Users/ksm/.codex/scripts/codex-permission-notify-macos.sh"
timeout = 5
statusMessage = "Sending approval notification"
```

관련 스크립트:

```text
~/.codex/scripts/codex-notify-macos.sh
~/.codex/scripts/codex-permission-notify-macos.sh
```

알림이 안 뜨면 macOS 시스템 설정에서 Codex 또는 Terminal의 알림 권한을 확인한다. 설정 변경 후에는 Codex를 재시작해야 확실히 적용된다.

## 운영 앱 기준 주의사항

이 레포는 실제 출시된 OnO Flutter 앱이다. 모든 작업 모드는 다음 기준을 공유한다.

- 기존 사용자 데이터, 학습 기록, 결제/인증/동기화 흐름을 깨지 않는다.
- API 응답 필드와 null 가능성을 임의로 단정하지 않는다.
- 에러를 조용히 삼키지 않고 사용자에게 이해 가능한 상태를 보여준다.
- 폰과 태블릿을 모두 1차 사용자 환경으로 본다.
- 작은 화면과 긴 텍스트에서 overflow, 버튼 잘림, 스크롤 불가를 확인한다.
- 요청 범위 밖 리팩터링, 포맷팅, 파일 이동, 이름 변경을 하지 않는다.
