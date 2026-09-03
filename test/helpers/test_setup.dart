import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Config/AppConfig.dart';

/// 모든 테스트 파일의 main() 맨 앞에서 한 번 부른다.
///
/// ```dart
/// void main() {
///   setUpOnoTest();
///
///   group('ProblemService', () { ... });
/// }
/// ```
///
/// 두 가지를 한다.
///
/// 1. [AppConfig.loadForTest] 로 baseUrl 을 채운다. Service 들은 필드 초기화
///    시점에 [AppConfig.baseUrl] 을 읽기 때문에, 이게 없으면 Service 를 만드는
///    것만으로 LateInitializationError 가 난다.
///
/// 2. dotenv 를 더미 값으로 초기화한다. 이게 없으면 실제 `.env` 가 로드된다.
///    `AppErrorReporter._ensureDotenvLoaded()` 는 `dotenv.env.isNotEmpty` 로
///    초기화 여부를 판단하는데, 비어 있으면 매번 진짜 `.env` 를 다시 읽는다.
///    레포 루트의 `.env` 에는 운영 Discord 웹훅 URL 이 들어 있어서, 에러 경로를
///    타는 테스트가 실제 웹훅으로 HTTP 요청을 보낸다. 실제로 한 번 나갔다.
///    맵을 비어 있지 않게 만들어 그 경로를 차단한다.
void setUpOnoTest() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppConfig.loadForTest();
  setUpTestDotenv();
}

/// dotenv 를 더미 값으로 채운다. 이미 초기화되어 있으면 그대로 둔다.
///
/// 테스트가 실제 `.env` 를 읽어 운영 Discord 웹훅이나 Sentry DSN 을 집어드는 것을
/// 막는다. 빈 문자열로 초기화하면 안 된다. `dotenv.env` 가 비어 있으면
/// `AppErrorReporter` 가 초기화되지 않은 것으로 보고 진짜 `.env` 를 다시 읽는다.
void setUpTestDotenv() {
  if (dotenv.isInitialized) return;
  dotenv.testLoad(
    fileInput: [
      'ONO_TEST_ENV=1',
      'BASE_URL_LOCAL=$testBaseUrl',
      'BASE_URL_DEV=$testBaseUrl',
      'BASE_URL_PROD=$testBaseUrl',
      // 비워 둔다. AppErrorReporter 가 웹훅 URL 을 못 찾고 전송을 건너뛴다.
      'DISCORD_WEBHOOK_LOCAL_URL=',
      'DISCORD_WEBHOOK_PROD_URL=',
      'SENTRY_DSN=',
    ].join('\n'),
  );
}

/// 테스트에서 쓰는 API 기본 주소. [AppConfig.loadForTest] 의 기본값과 같다.
/// URL 검증에서 문자열을 직접 쓰지 말고 이걸 쓴다.
const String testBaseUrl = 'https://test.ono.local';
