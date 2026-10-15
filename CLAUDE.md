# OnO 프론트엔드 (Flutter)

실사용자가 있는 운영 중인 오답노트 앱. Flutter + Dart, 앱스토어/플레이스토어 배포. 1인 개발자 운영.

**최우선 원칙**: 버그를 사용자에게 보내지 않기. 한 번 나간 릴리즈는 다음 심사 통과까지 롤백 불가.

## 운영 가드레일

**자유롭게:**
- 코드·설정·문서 변경, 브랜치 생성, `/commit` 의 커밋, `/pr` 의 원격 브랜치 push 와 develop 대상 PR 생성
- merge, main/develop 직접 push, force push 는 사용자가 명시적으로 요청할 때만

**반드시 확인:**
- 앱스토어/플레이스토어 릴리즈 빌드·업로드 전 영향 범위 설명 후 확인 (업로드는 사람이 한다)
- API 계약(요청/응답 shape) 변경은 백엔드 레포와 동기화 여부 확인
- FCM 알림 발송 경로 수정 전 경고

공유 가드레일은 `.claude/settings.json` (권한 deny/ask, 편집 후 dart 파일 analyze 훅).

## 빌드·검증 명령

```
dart format <바꾼 test 파일>     # 포맷은 test 만 (CI 와 같음, lib 전체 포맷 금지)
flutter analyze --no-fatal-infos # CI 기준: warning·error 0개 (info 는 기존에 많음)
flutter test                     # 단위·위젯·골든 테스트 (test/)
flutter run                      # 실행
```

출시 전: 위 analyze 기준 통과 + `flutter test` 통과 필수. 절차는 `/release`.

## 작업 방식

- **응답·주석·커밋 언어**: 한국어
- **커밋 형식**:
  ```
  [Feat] 한 줄 요약 - 상세1 상세2 (#이슈번호)
  ```
  태그: `[Feat]` / `[Fix]` / `[Refactor]` / `[Chore]` / `[Test]` / `[Docs]`
- 요청 범위 안에서만 수정. 무관한 리팩터링·포맷팅 금지.
- 불확실하면 추정하지 말고 먼저 드러냄.
- 관련 기획/개발 문서: `docs/` 우선 참고.
- 코드 구조: `lib/Screen`(화면) · `lib/Module`(공용 위젯) · `lib/Provider`(상태, provider 패키지만 사용) · `lib/Service/Api`(API 호출) · `lib/Model` · `lib/Util` · `lib/Config`.

## 지표 수집 (Firebase Analytics)

- 새 화면은 `initState` 에서 `AppAnalytics.logScreenView('화면이름')`, 새 행동은 성공한 뒤 `AppAnalytics.logEvent`.
- 이름 규칙, 파라미터 사전, 콘솔 등록 목록: `docs/애널리틱스 지표/이벤트 목록.md` (8절이 새 기능 체크리스트).
- `test/util/analytics_*_test.dart` 가 이름 규칙과 화면 조회 누락을 막는다.

## UI 원칙

폰·태블릿 모두 1차 환경. 모든 UI는 반응형 기본. 고정 width/height 지양.

## 스킬 (`.claude/skills/`)

절차 본문은 `.agents/skills/ono-*/SKILL.md` 한 곳에만 있고(Codex 와 같이 씀), `.claude/skills/` 는 그 파일을 읽게 하는 래퍼다. 절차는 정본만 고친다.

| 명령 | 목적 | 자동 호출 |
|---|---|---|
| `/analysis` | 원인 규명·병렬 조사 (읽기 전용) | O |
| `/check` | 다관점 검증·위험도 분류 (읽기 전용) | O |
| `/explain` | 코드 흐름·원리 설명 (읽기 전용) | O |
| `/plan` | 구현 명세서 작성 (코드 수정 X) | X |
| `/feat` | plan 기반 구현 (커밋 X) | X |
| `/commit` | 논리 단위로 나눠 실제 커밋 | X |
| `/pr` | 필요 시 push 후 develop 대상 PR 생성 | X |
| `/issue` | GitHub 이슈 생성 | X |
| `/release` | 출시 전 검증·버전 올림·업데이트 내역 (업로드는 사람) | X |
| `/sim` | 시뮬레이터에 띄워 화면 확인 | X |

- 시뮬레이터 확인: `/sim [ios|android] [화면 설명]`. 반드시 `--dart-define=ENV=dev`, 실기기 금지, 로그와 스크린샷은 레포 밖에 둔다.
- Dart MCP(`.mcp.json` 의 `dart`)는 `analyze_files`, `run_tests` 같은 정적 도구로 쓴다. 터미널에서 띄운 앱의 hot reload 는 `kill -USR1 $(cat <pid 파일>)`.

## 에이전트 (`.claude/agents/`)

`code-tracer` · `perf-reviewer` · `logic-reviewer` · `side-effect-checker` · `permission-auditor` · `report-writer`