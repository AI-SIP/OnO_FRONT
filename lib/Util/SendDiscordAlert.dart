import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DiscordAlertResult {
  final bool isSuccess;
  final int? statusCode;
  final Object? error;

  const DiscordAlertResult._({
    required this.isSuccess,
    this.statusCode,
    this.error,
  });

  const DiscordAlertResult.success({int? statusCode})
      : this._(isSuccess: true, statusCode: statusCode);

  const DiscordAlertResult.failure({int? statusCode, Object? error})
      : this._(isSuccess: false, statusCode: statusCode, error: error);
}

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 3)}...';
}

/// Discord 웹훅 전송 함수의 모양.
/// AppErrorReporter 가 테스트에서 가짜 전송기로 바꿔 끼울 수 있게 타입을 열어 둔다.
typedef DiscordAlertSender = Future<DiscordAlertResult> Function({
  required String message,
  StackTrace? stack,
  required String webhookUrl,
  int maxAttempts,
  http.Client? client,
});

Future<DiscordAlertResult> sendDiscordAlert({
  required String message,
  StackTrace? stack,
  required String webhookUrl,
  int maxAttempts = 2,
  http.Client? client,
}) async {
  // 직접 만든 클라이언트는 우리가 닫는다. 주입받은 것은 호출한 쪽이 관리한다.
  final httpClient = client ?? http.Client();
  final shouldClose = client == null;
  try {
    return await _sendDiscordAlert(
      message: message,
      stack: stack,
      webhookUrl: webhookUrl,
      maxAttempts: maxAttempts,
      client: httpClient,
    );
  } finally {
    if (shouldClose) httpClient.close();
  }
}

Future<DiscordAlertResult> _sendDiscordAlert({
  required String message,
  StackTrace? stack,
  required String webhookUrl,
  required int maxAttempts,
  required http.Client client,
}) async {
  // Discord embed 제한 대응
  final safeMessage = _truncate(message, 1500);
  final safeStack = stack == null ? null : _truncate(stack.toString(), 3500);

  final embed = {
    'title': '🚨 Flutter 앱 에러 발생',
    'description': '```$safeMessage```',
    'fields': [
      if (safeStack != null)
        {
          'name': 'StackTrace',
          'value': '```$safeStack```',
          'inline': false,
        },
    ],
    'timestamp': DateTime.now().toIso8601String(),
  };
  final payload = {
    'embeds': [embed]
  };

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final response = await client
          .post(
            Uri.parse(webhookUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return DiscordAlertResult.success(statusCode: response.statusCode);
      }

      debugPrint('Discord webhook failed: ${response.statusCode} ${response.body}');

      if (attempt < maxAttempts && response.statusCode == 429) {
        await Future.delayed(_retryDelay(response.headers['retry-after']));
        continue;
      }

      if (attempt < maxAttempts && response.statusCode >= 500) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      return DiscordAlertResult.failure(statusCode: response.statusCode);
    } catch (e) {
      debugPrint('Failed to send Discord webhook: $e');

      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      return DiscordAlertResult.failure(error: e);
    }
  }

  return const DiscordAlertResult.failure();
}

Duration _retryDelay(String? retryAfterHeader) {
  final retryAfterSeconds = int.tryParse(retryAfterHeader ?? '');
  if (retryAfterSeconds == null || retryAfterSeconds < 1) {
    return const Duration(seconds: 1);
  }

  return Duration(seconds: retryAfterSeconds);
}
