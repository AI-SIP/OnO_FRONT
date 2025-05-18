import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

Future<void> sendDiscordAlert({
  required String message,
  StackTrace? stack,
  required String webhookUrl,
}) async {
  final embed = {
    'title': '🚨 Flutter 앱 에러 발생',
    'description': '```$message```',
    'fields': [
      if (stack != null)
        {
          'name': 'StackTrace',
          'value': '```$stack```',
          'inline': false,
        },
    ],
    'timestamp': DateTime.now().toIso8601String(),
  };
  final payload = {
    'embeds': [embed]
  };

  try {
    await http.post(
      Uri.parse(webhookUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  } catch (e) {
    log('Failed to send Discord webhook: $e');
  }
}
