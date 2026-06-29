import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'SendDiscordAlert.dart';

enum AppErrorSeverity { warning, error, fatal }

class AppErrorReporter {
  static const String _appEnv = String.fromEnvironment(
    'ENV',
    defaultValue: 'local',
  );

  static Future<void> report(
    Object error,
    StackTrace stackTrace, {
    String source = 'app',
    AppErrorSeverity severity = AppErrorSeverity.error,
    bool sendToDiscord = true,
  }) async {
    await _ensureDotenvLoaded();

    debugPrint('[AppErrorReporter][${severity.name}] $source\nError: $error\n$stackTrace');

    try {
      await Sentry.captureException(error, stackTrace: stackTrace);
    } catch (sentryError, sentryStackTrace) {
      debugPrint('[AppErrorReporter] Failed to report to Sentry\nError: $sentryError\n$sentryStackTrace');
    }

    if (!sendToDiscord) return;

    final webhookUrl = _resolveDiscordWebhookUrl();
    if (webhookUrl == null) {
      debugPrint('[AppErrorReporter] Discord webhook URL is not configured for env=$_appEnv');
      return;
    }

    final result = await sendDiscordAlert(
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

  static Future<void> _ensureDotenvLoaded() async {
    if (dotenv.env.isNotEmpty) return;

    try {
      await dotenv.load(fileName: '.env');
    } catch (error, stackTrace) {
      debugPrint('[AppErrorReporter] Failed to load dotenv for error reporting\nError: $error\n$stackTrace');
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
