import 'package:flutter/material.dart';
import '../Constants/ErrorMessages.dart';
import '../Module/Text/StandardText.dart';
import 'ErrorMessageMapper.dart';

class AppSnackBar {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static DateTime? _lastShownAt;
  static String? _lastMessage;

  static void showError(String message) {
    final messenger = messengerKey.currentState;
    if (messenger == null || message.trim().isEmpty) return;
    final safeMessage = ErrorMessageMapper.sanitizeRawMessage(
      message,
      fallback: ErrorMessages.unknown,
      allowRawMessage: true,
    );

    final now = DateTime.now();
    if (_lastMessage == safeMessage &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < const Duration(milliseconds: 800)) {
      return;
    }

    _lastMessage = safeMessage;
    _lastShownAt = now;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: StandardText(
          text: safeMessage,
          fontSize: 14,
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
