import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static late final String baseUrl;
  static late final String guidePageUrl;
  static late final String feedbackPageUrl;
  static late final String userInfoProcessRulePageUrl;
  static late final String userTermPageUrl;

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
  }
}
