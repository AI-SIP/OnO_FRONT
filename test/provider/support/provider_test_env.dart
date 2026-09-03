// Provider 테스트 전역에서 공통으로 필요한 환경 스텁을 모아 둔다.
//
// `AppErrorReporter.report()` 는 (lib/Util/AppErrorReporter.dart) 내부에서
// `dotenv.env.isNotEmpty` 로 초기화 여부를 확인하는데, `dotenv.env` 자체가
// 초기화 전에는 `NotInitializedError` 를 던진다. 그 확인 코드가 try/catch 밖에
// 있어서, `.env` 를 로드한 적 없는 테스트 프로세스에서는 "실패를 삼키고 그냥
// 리포트만 하는" catch 블록(_runPostMutationRefresh 등)이 오히려 예외를 던지며
// 테스트를 깨뜨린다. flutter_dotenv 가 제공하는 testLoad 로 미리 빈 값을 채워
// 이 문제를 피한다. (프로덕션 버그는 아니다 — 실제 앱은 main() 에서 dotenv.load 를
// 먼저 하기 때문에 겪지 않는다.)
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../helpers/firebase_analytics_stub.dart';

/// Provider 테스트 파일의 `setUpAll` 에서 한 번 부른다.
///
/// 주의: `dotenv.testLoad(fileInput: '')` 처럼 완전히 빈 값으로 초기화하면 안
/// 된다. `_ensureDotenvLoaded()` 의 가드는 `dotenv.env.isNotEmpty` 로 "이미
/// 로드됐는지"를 판단하는데, 맵이 비어 있으면 이 조건이 false 가 되어 매번
/// 실제 `dotenv.load(fileName: '.env')` 를 다시 시도한다. 이 프로젝트 루트에는
/// 진짜 `.env` 가 있고 거기엔 실제 Discord 웹훅 URL 이 들어있어서, 테스트가
/// 실패 경로를 탈 때마다(예: 로딩 실패를 흡수하는 catch 블록에서 severity=error
/// 로 AppErrorReporter.report 를 부를 때) 진짜 웹훅으로 HTTP 요청이 나간다.
/// 더미 키를 하나 넣어 맵을 비지 않게 만들어 이 경로 자체를 막는다.
void setUpProviderTestEnv() {
  if (!dotenv.isInitialized) {
    dotenv.testLoad(fileInput: 'ONO_TEST_ENV=1');
  }
  stubFirebaseAnalytics();
}
