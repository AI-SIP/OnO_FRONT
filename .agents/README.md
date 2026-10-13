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

Claude Code 용 래퍼는 `.claude/skills/<이름>/SKILL.md` 에 있다. 아래 「Claude Code 와 나눠 쓰는 구조」 참고.

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

각 작업 모드의 순서와 보고 형식은 `.agents/skills/ono-*/SKILL.md` 에만 적는다. 이 README 에 절차를 다시 옮겨 적지 않는다. 같은 내용이 두 곳에 있으면 한쪽만 고쳐져 어긋나기 때문이다.

## Claude Code 와 나눠 쓰는 구조

Claude Code 의 슬래시 명령(`/analysis`, `/plan`, `/feat`, `/check`, `/commit`, `/pr`, `/issue`, `/explain`, `/release`, `/sim`)도 이 디렉터리의 `SKILL.md` 를 정본으로 쓴다.

```text
.agents/skills/ono-<이름>/SKILL.md   ← 절차 본문 (정본). name, description 만 둔다
.claude/skills/<이름>/SKILL.md       ← Claude 래퍼. 정본을 Read 로 읽고 따르라는 지시와
                                        Claude 전용 frontmatter, 에이전트 위임만 둔다
```

- **절차를 고칠 때는 `.agents/skills/ono-*/SKILL.md` 만 고친다.** Claude 래퍼에는 절차를 적지 않는다.
- **도구마다 다른 것만 래퍼에 둔다.** `argument-hint`, `disable-model-invocation`, `$ARGUMENTS`, `.claude/agents` 위임, Bash `run_in_background` 같은 Claude Code 기능이 여기에 해당한다.
- **정본 본문은 도구 중립으로 쓴다.** "서브에이전트를 띄울 수 있는 도구에서는 관점별로 병렬로" 처럼 쓰고, 특정 에이전트 이름은 래퍼에 둔다.
- 예전 `.claude/commands/*.md` 는 지웠다. 공식 문서 기준으로 commands 는 skills 에 합쳐졌고 같은 이름이면 skill 이 우선해서, 둘을 같이 두면 어느 쪽이 도는지 헷갈린다.

`.claude/agents` 의 전문 에이전트는 Claude 래퍼가 부르고, 정본에는 그 관점만 들어 있다.

| 에이전트 | 부르는 Claude 스킬 | 정본에 들어 있는 관점 |
|---|---|---|
| `code-tracer` | `/analysis`, `/plan`, `/explain` | `ono-analysis`, `ono-explain` 의 흐름 추적 |
| `perf-reviewer` | `/check`, `/release` | rebuild, jank, 메모리, 리스트 |
| `logic-reviewer` | `/check`, `/release` | null safety, async, 상태 전이, 에러 처리 |
| `side-effect-checker` | `/check`, `/release` | API 중복 호출, 로컬 저장소, FCM |
| `permission-auditor` | `/check`(인증, 라우팅 변경 시), `/release` | 화면 접근 제어와 인증 흐름 |
| `report-writer` | 없음 (직접 요청할 때) | 별도 Codex Skill 없음 |

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
