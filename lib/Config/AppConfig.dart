import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static late final String baseUrl;
  static late final String guidePageUrl;
  static late final String feedbackPageUrl;
  static late final String userInfoProcessRulePageUrl;
  static late final String userTermPageUrl;

  static Future<void> load() async {
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
    feedbackPageUrl = dotenv.env['FEEDBACK_PAGE_URL']!;
    userInfoProcessRulePageUrl = dotenv.env['USER_RULES_URL']!;
    userTermPageUrl = dotenv.env['USER_TERMS_URL']!;
  }
}
