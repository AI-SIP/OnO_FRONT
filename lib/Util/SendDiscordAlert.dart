import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 3)}...';
}

Future<void> sendDiscordAlert({
  required String message,
  StackTrace? stack,
  required String webhookUrl,
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

  try {
    final response = await http.post(
      Uri.parse(webhookUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      log('Discord webhook failed: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    log('Failed to send Discord webhook: $e');
  }
}
