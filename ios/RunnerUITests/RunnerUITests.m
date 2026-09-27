// Patrol E2E 테스트를 XCTest 로 돌리기 위한 진입점이다. patrol_test/ 의 Dart 테스트가
// 여기서 하나씩 불린다. 앱 코드가 아니라 UI 테스트 번들에만 들어간다.
@import XCTest;
@import patrol;
@import ObjectiveC.runtime;

PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)
