import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Config/AppConfig.dart';

class UrlLauncher {
  static Future<void> launchGuidePageURL() async {
    final url = Uri.parse(AppConfig.guidePageUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      // Firebase Analytics 이벤트 로그
      FirebaseAnalytics.instance.logEvent(
        name: 'ono_guide_button_click',
        parameters: {'url': AppConfig.guidePageUrl},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<void> launchFeedbackPageURL() async {
    final url = Uri.parse(AppConfig.feedbackPageUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      // Firebase Analytics 이벤트 로그
      FirebaseAnalytics.instance.logEvent(
        name: 'feedbackPage_button_click',
        parameters: {'url': AppConfig.feedbackPageUrl},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<void> launchUserTemPageURL() async {
    final url = Uri.parse(AppConfig.userTermPageUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      // Firebase Analytics 이벤트 로그
      FirebaseAnalytics.instance.logEvent(
        name: 'userTermPage_button_click',
        parameters: {'url': AppConfig.userTermPageUrl},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  // 다른 URL을 열 때 사용할 수 있는 메서드도 추가 가능
  static Future<void> launchURL(String urlString) async {
    final url = Uri.parse(urlString);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
  }
}