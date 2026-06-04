# OnO 프론트엔드 (Flutter)

실사용자가 있는 운영 중인 오답노트 앱. Flutter + Dart, 앱스토어/플레이스토어 배포. 1인 개발자 운영.

**최우선 원칙**: 버그를 사용자에게 보내지 않기. 한 번 나간 릴리즈는 다음 심사 통과까지 롤백 불가.

## 운영 가드레일

**자유롭게:**
- git 작업 (커밋·push·브랜치·머지 등) 자유
- 코드·설정·문서 변경 자유

**반드시 확인:**
- 앱스토어/플레이스토어 릴리즈 배포 전 영향 범위 설명 후 확인
- API 계약(요청/응답 shape) 변경은 백엔드 레포와 동기화 여부 확인
- FCM 알림 발송 경로 수정 전 경고

## 빌드·검증 명령

```
dart format .                    # 포맷
flutter analyze                  # 정적 분석 (경고 0개 목표)
flutter test                     # 테스트
flutter build apk / ios          # 빌드
flutter run                      # 실행
```

출시 전: `flutter analyze` 무경고 + 테스트 통과 필수.

## 작업 방식

- **응답·주석·커밋 언어**: 한국어
- **커밋 형식**:
  ```
  [Feat] 한 줄 요약 - 상세1 상세2
  ```
  태그: `[Feat]` / `[Fix]` / `[Refactor]` / `[Chore]` / `[Test]` / `[Docs]`
- 요청 범위 안에서만 수정. 무관한 리팩터링·포맷팅 금지.
- 불확실하면 추정하지 말고 먼저 드러냄.
- 관련 기획/개발 문서: `docs/` 우선 참고.

## UI 원칙

폰·태블릿 모두 1차 환경. 모든 UI는 반응형 기본. 고정 width/height 지양.

## 커스텀 명령어 (`.claude/commands/`)

| 명령 | 목적 |
|---|---|
| `/analysis` | 원인 규명·병렬 조사 |
| `/plan` | 구현 명세서 작성 (코드 수정 X) |
| `/feat` | plan 기반 기능 구현 |
| `/check` | 다관점 검증·위험도 분류 |
| `/commit` | 커밋 단위 및 메시지 제안 |
| `/pr` | PR 초안 작성 |
| `/explain` | 코드 흐름·원리 설명 |

## 에이전트 (`.claude/agents/`)

`code-tracer` · `perf-reviewer` · `logic-reviewer` · `side-effect-checker` · `permission-auditor` · `report-writer`