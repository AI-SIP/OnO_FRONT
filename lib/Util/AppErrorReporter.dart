import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../Exception/ApiException.dart';
import 'SendDiscordAlert.dart';

enum AppErrorSeverity { warning, error, fatal }

class AppErrorReporter {
  static const String _appEnv = String.fromEnvironment(
    'ENV',
    defaultValue: 'local',
  );

  /// 실제 Discord 전송기. 테스트에서 가짜로 바꿔 끼운다.
  /// 이 클래스는 전부 static 이라 생성자 주입을 쓸 수 없어 이 방식으로 연다.
  @visibleForTesting
  static DiscordAlertSender discordAlertSender = sendDiscordAlert;

  /// 끄면 Sentry 와 Discord 어디로도 보내지 않는다.
  ///
  /// E2E 는 진짜 `main()` 을 띄워서 테스트의 실패와 일부러 만든 데이터가
  /// 운영 이슈처럼 Sentry 에 쌓였다. E2E 가 앱을 띄우기 전에 끈다.
  /// 앱 코드에서는 바꾸지 않는다.
  static bool enabled = true;

  /// 테스트가 바꿔 끼운 전송기를 원래대로 되돌린다. tearDown 에서 부른다.
  @visibleForTesting
  static void resetDiscordAlertSender() {
    discordAlertSender = sendDiscordAlert;
  }

  static Future<void> report(
    Object error,
    StackTrace stackTrace, {
    String source = 'app',
    AppErrorSeverity severity = AppErrorSeverity.error,
    bool sendToDiscord = true,
    bool sendToSentry = true,
  }) async {
    if (!enabled) return;
    await _ensureDotenvLoaded();

    // 사용자 단말의 일시적인 통신 문제는 앱 결함이 아니므로 warning 으로 낮춘다.
    final effectiveSeverity =
        _isTransientNetworkError(error) ? AppErrorSeverity.warning : severity;

    debugPrint(
        '[AppErrorReporter][${effectiveSeverity.name}] $source\nError: $error\n$stackTrace');

    // FlutterError.onError 와 PlatformDispatcher.onError 는 SentryFlutter 가
    // 제 통합으로 감싸 한 번 더 보낸다. 그 두 곳은 여기서 보내지 않아야 같은
    // 에러가 두 건씩 쌓이지 않는다.
    if (sendToSentry) {
      await _captureToSentry(error, stackTrace, source, effectiveSeverity);
    }

    // warning 은 디스코드로 알리지 않는다. (네트워크 끊김 등으로 알림이 묻히는 것을 막는다)
    if (!sendToDiscord || effectiveSeverity == AppErrorSeverity.warning) return;
    await _sendToDiscord(error, stackTrace, source);
  }

  static Future<void> _captureToSentry(
    Object error,
    StackTrace stackTrace,
    String source,
    AppErrorSeverity effectiveSeverity,
  ) async {
    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.level = _toSentryLevel(effectiveSeverity);
          scope.setTag('error_source', source);
        },
      );
    } catch (sentryError, sentryStackTrace) {
      debugPrint(
          '[AppErrorReporter] Failed to report to Sentry\nError: $sentryError\n$sentryStackTrace');
    }
  }

  static Future<void> _sendToDiscord(
    Object error,
    StackTrace stackTrace,
    String source,
  ) async {
    final webhookUrl = _resolveDiscordWebhookUrl();
    if (webhookUrl == null) {
      debugPrint(
          '[AppErrorReporter] Discord webhook URL is not configured for env=$_appEnv');
      return;
    }

    final result = await discordAlertSender(
      message: '[$source] $error',
      stack: stackTrace,
      webhookUrl: webhookUrl,
    );

    if (!result.isSuccess) {
      debugPrint('[AppErrorReporter] Discord webhook failed'
          '${result.statusCode != null ? ' status=${result.statusCode}' : ''}'
          '${result.error != null ? ' error=${result.error}' : ''}');
    }
  }

  static SentryLevel _toSentryLevel(AppErrorSeverity severity) {
    switch (severity) {
      case AppErrorSeverity.warning:
        return SentryLevel.warning;
      case AppErrorSeverity.error:
        return SentryLevel.error;
      case AppErrorSeverity.fatal:
        return SentryLevel.fatal;
    }
  }

  /// 앱 결함이 아니라 통신이나 서버 쪽이 잠깐 흔들린 것.
  ///
  /// 서버가 502·503·504 를 본문 없이 주면 [ApiException] 으로 올라온다.
  /// 그것까지 error 로 보내면 서버가 재시작하는 몇 분 사이에 Discord 가
  /// 알림으로 찼다. 500 은 서버 결함일 수 있어 그대로 둔다.
  static bool _isTransientNetworkError(Object error) {
    if (error is NetworkException || error is TimeoutException) return true;
    final status = switch (error) {
      ApiException(:final statusCode) => statusCode,
      ServerException(:final statusCode) => statusCode,
      _ => null,
    };
    return status == 502 || status == 503 || status == 504;
  }

  static Future<void> _ensureDotenvLoaded() async {
    if (dotenv.env.isNotEmpty) return;

    try {
      await dotenv.load(fileName: '.env');
    } catch (error, stackTrace) {
      debugPrint(
          '[AppErrorReporter] Failed to load dotenv for error reporting\nError: $error\n$stackTrace');
    }
  }

  static String? _resolveDiscordWebhookUrl() {
    final prodUrl = _normalize(dotenv.env['DISCORD_WEBHOOK_PROD_URL']);
    final localUrl = _normalize(dotenv.env['DISCORD_WEBHOOK_LOCAL_URL']);

    switch (_appEnv) {
      case 'prod':
        return prodUrl ?? localUrl;
      case 'dev':
        return localUrl ?? prodUrl;
      default:
        if (kReleaseMode) {
          return prodUrl ?? localUrl;
        }
        return localUrl ?? prodUrl;
    }
  }

  static String? _normalize(String? value) {
    if (value == null) return null;

    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    return trimmed;
  }
}
