import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppConfig {
  static late final String baseUrl;
  static late final String guidePageUrl;
  static late final String feedbackPageUrl;
  static late final String userInfoProcessRulePageUrl;
  static late final String userTermPageUrl;

  static String? _appVersion;

  /// `4.0.0+70` 꼴의 앱 버전. 아직 읽지 못했으면 null 이다.
  ///
  /// 서버는 이 값으로 요청이 구버전 앱에서 왔는지 판단해 XP 자동 적립 여부를
  /// 정한다. 모든 API 요청이 HttpService 에서 이 값을 읽어 가므로,
  /// `late` 로 두면 초기화 전에 읽는 순간 앱의 모든 요청이 죽는다.
  /// 값을 못 구한 상태를 정상으로 보고 null 을 허용한다.
  static String? get appVersion => _appVersion;

  /// 테스트에서 버전을 읽은/못 읽은 상태를 직접 만든다.
  /// 정적 필드라 테스트 사이로 새어 나가므로 쓴 쪽이 null 로 되돌린다.
  @visibleForTesting
  static void setAppVersionForTest(String? version) {
    _appVersion = version;
  }

  static bool _loaded = false;

  /// 테스트에서 .env 파일 없이 설정값을 채운다.
  /// Service 들이 필드 초기화 시점에 [baseUrl] 을 읽기 때문에,
  /// 이 값이 비어 있으면 Service 를 생성하는 것만으로 LateInitializationError 가 난다.
  /// 같은 isolate 안에서 두 번 호출되어도 안전하도록 한 번만 대입한다.
  @visibleForTesting
  static void loadForTest({
    String baseUrl = 'https://test.ono.local',
    String guidePageUrl = 'https://test.ono.local/guide',
    String userInfoProcessRulePageUrl = 'https://test.ono.local/privacy',
    String userTermPageUrl = 'https://test.ono.local/terms',
  }) {
    if (_loaded) return;
    _loaded = true;

    AppConfig.baseUrl = baseUrl;
    AppConfig.guidePageUrl = guidePageUrl;
    AppConfig.feedbackPageUrl = '$baseUrl/feedback';
    AppConfig.userInfoProcessRulePageUrl = userInfoProcessRulePageUrl;
    AppConfig.userTermPageUrl = userTermPageUrl;
  }

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    await dotenv.load(fileName: ".env");

    // Environment 구분: local, dev, prod
    const environment = String.fromEnvironment('ENV', defaultValue: 'local');

    if (environment == 'prod') {
      baseUrl = dotenv.env['BASE_URL_PROD']!;
    } else if (environment == 'dev') {
      baseUrl = dotenv.env['BASE_URL_DEV']!;
    } else {
      baseUrl = dotenv.env['BASE_URL_LOCAL']!;
    }

    guidePageUrl = dotenv.env['GUIDE_PAGE_URL']!;
    feedbackPageUrl = '$baseUrl/feedback';
    userInfoProcessRulePageUrl = dotenv.env['USER_RULES_URL']!;
    userTermPageUrl = dotenv.env['USER_TERMS_URL']!;

    await _loadAppVersion();
  }

  /// 앱 버전을 읽는 경로를 테스트에서 직접 태운다.
  /// 실제 앱에서는 [load] 안에서만 불린다.
  @visibleForTesting
  static Future<void> loadAppVersionForTest() => _loadAppVersion();

  /// 앱 버전을 한 번만 읽어 들고 있는다.
  ///
  /// `PackageInfo.fromPlatform()` 은 플랫폼 채널을 타는 비동기 호출이다.
  /// 요청마다 부르면 앱의 모든 API 호출에 await 가 하나씩 더 붙으므로
  /// 앱이 뜰 때 여기서 한 번만 읽는다.
  static Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      if (version.isEmpty) return;

      final buildNumber = info.buildNumber.trim();
      // 서버는 `+` 앞만 보지만 빌드 번호까지 붙여 보낸다.
      // 나중에 서버가 빌드 번호를 봐야 할 때 앱을 다시 내보내지 않아도 된다.
      _appVersion = buildNumber.isEmpty ? version : '$version+$buildNumber';
    } catch (error) {
      // 플랫폼 채널이 없거나 정보를 못 읽는 경우(MissingPluginException 등).
      // 여기서 던지면 앱 부팅이 통째로 막히고, 버전을 모르면 헤더를 빼는 쪽이
      // 안전하다. 서버는 헤더가 없으면 구버전으로 보고 자동 적립을 켠다.
      debugPrint('[AppConfig] 앱 버전을 읽지 못했다: $error');
    }
  }
}
