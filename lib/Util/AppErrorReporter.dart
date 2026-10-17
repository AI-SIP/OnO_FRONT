import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../Exception/ApiException.dart';
import 'SendDiscordAlert.dart';

enum AppErrorSeverity { warning, error, fatal }

typedef SentryExceptionCapturer = Future<void> Function(
  Object error,
  StackTrace stackTrace,
  String source,
  SentryLevel level,
);

typedef SentryBreadcrumbAdder = Future<void> Function(Breadcrumb breadcrumb);

class AppErrorReporter {
  static const String _appEnv = String.fromEnvironment(
    'ENV',
    defaultValue: 'local',
  );

  /// 실제 Discord 전송기. 테스트에서 가짜로 바꿔 끼운다.
  /// 이 클래스는 전부 static 이라 생성자 주입을 쓸 수 없어 이 방식으로 연다.
  @visibleForTesting
  static DiscordAlertSender discordAlertSender = sendDiscordAlert;

  /// Sentry 로 예외를 보내는 함수. 테스트에서 가짜로 바꿔 끼운다.
  @visibleForTesting
  static SentryExceptionCapturer sentryCapturer = _captureWithSentry;

  /// Sentry 에 breadcrumb 을 남기는 함수. 테스트에서 가짜로 바꿔 끼운다.
  @visibleForTesting
  static SentryBreadcrumbAdder breadcrumbAdder = _addSentryBreadcrumb;

  /// 리프레시 토큰이 만료됐거나 서버에 없다는 errorCode.
  /// `TokenProvider._isRefreshTokenInvalidResponse` 가 로그아웃으로 처리하는 값과 같다.
  static const Set<int> _refreshTokenInvalidErrorCodes = {
    1001,
    1002,
    1003,
    1004,
    1006,
  };

  /// 사용자가 로그인 창을 직접 닫았을 때 플랫폼이 주는 코드.
  /// CANCELED 는 카카오 SDK, sign_in_canceled 는 google_sign_in 이다.
  /// REDIRECT_URI_MISMATCH, sign_in_failed 같은 다른 코드는 설정 문제라 그대로 보낸다.
  static const Set<String> _userCanceledPlatformCodes = {
    'CANCELED',
    'sign_in_canceled',
  };

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

  /// 테스트가 바꿔 끼운 Sentry 전송기를 원래대로 되돌린다. tearDown 에서 부른다.
  @visibleForTesting
  static void resetSentrySenders() {
    sentryCapturer = _captureWithSentry;
    breadcrumbAdder = _addSentryBreadcrumb;
  }

  /// 앱이 이미 처리하고 있는 실패인지 본다. 이런 실패는 Sentry 이벤트로 보내지 않고
  /// breadcrumb 으로만 남긴다. 다음에 진짜 오류가 나면 그 이벤트에 맥락으로 붙는다.
  ///
  /// - 네트워크 끊김([NetworkException])과 앱이 정한 시간 초과([TimeoutException]).
  ///   스플래시의 다시 시도 버튼을 누를 때마다 한 건씩 쌓였다. (FLUTTER-19Y, Z9)
  /// - 리프레시 토큰 만료처럼 다시 로그인하면 되는 [UnauthorizedException]. (FLUTTER-18K)
  ///   errorCode 가 없는 것은 토큰을 못 찾은 경우라 결함일 수 있어 그대로 보낸다.
  /// - 사용자가 로그인 창을 닫은 [PlatformException]. (FLUTTER-18G)
  ///
  /// 5xx 인 [ApiException], [ServerException] 은 여기에 넣지 않는다. 서버 쪽 문제를
  /// 알아야 하므로 지금처럼 보낸다.
  static bool isExpectedFailure(Object error) {
    return switch (error) {
      NetworkException() || TimeoutException() => true,
      UnauthorizedException(:final errorCode) =>
        _refreshTokenInvalidErrorCodes.contains(errorCode),
      PlatformException(:final code) =>
        _userCanceledPlatformCodes.contains(code),
      _ => false,
    };
  }

  /// `SentryFlutter.init` 의 `beforeSend`.
  ///
  /// [report] 를 거치지 않는 경로가 있다. FlutterError, PlatformDispatcher 통합이
  /// 직접 보내는 미처리 예외와 소셜 로그인 서비스의 `Sentry.captureException` 이다.
  /// 여기서 한 번 더 걸러 예상된 실패는 breadcrumb 으로 바꾸고 이벤트는 버린다.
  static Future<SentryEvent?> beforeSend(SentryEvent event, Hint hint) async {
    final throwable = event.throwable;
    if (throwable == null || !isExpectedFailure(throwable)) return event;

    final source = event.tags?['error_source'] ?? 'sentry_integration';
    debugPrint('[AppErrorReporter][expected] $source\nError: $throwable');
    await _leaveBreadcrumb(throwable, source);
    return null;
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

    if (isExpectedFailure(error)) {
      debugPrint(
          '[AppErrorReporter][expected] $source\nError: $error\n$stackTrace');
      // sendToSentry 가 false 인 곳은 SentryFlutter 통합이 따로 보내고,
      // 그 이벤트는 beforeSend 가 breadcrumb 으로 바꾼다. 여기서도 남기면 두 번 남는다.
      if (sendToSentry) await _leaveBreadcrumb(error, source);
      return;
    }

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
      await sentryCapturer(
        error,
        stackTrace,
        source,
        _toSentryLevel(effectiveSeverity),
      );
    } catch (sentryError, sentryStackTrace) {
      debugPrint(
          '[AppErrorReporter] Failed to report to Sentry\nError: $sentryError\n$sentryStackTrace');
    }
  }

  static Future<void> _captureWithSentry(
    Object error,
    StackTrace stackTrace,
    String source,
    SentryLevel level,
  ) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.level = level;
        scope.setTag('error_source', source);
      },
    );
  }

  static Future<void> _addSentryBreadcrumb(Breadcrumb breadcrumb) =>
      Sentry.addBreadcrumb(breadcrumb);

  static Future<void> _leaveBreadcrumb(Object error, String source) async {
    try {
      await breadcrumbAdder(
        Breadcrumb(
          category: 'expected_failure',
          type: 'error',
          level: SentryLevel.warning,
          message: '[$source] ${error.runtimeType}',
          data: {
            'source': source,
            'error': error.toString(),
          },
        ),
      );
    } catch (sentryError, sentryStackTrace) {
      debugPrint(
          '[AppErrorReporter] Failed to add Sentry breadcrumb\nError: $sentryError\n$sentryStackTrace');
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
  /// 네트워크 끊김과 시간 초과는 [isExpectedFailure] 가 먼저 걸러 여기까지 오지 않는다.
  static bool _isTransientNetworkError(Object error) {
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
