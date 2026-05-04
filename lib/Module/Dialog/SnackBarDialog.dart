import 'package:flutter/material.dart';

import '../../Constants/ErrorMessages.dart';
import '../Text/StandardText.dart';
import '../../Util/ErrorMessageMapper.dart';

class SnackBarDialog {
  static void showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
  }) {
    final safeMessage = ErrorMessageMapper.sanitizeRawMessage(
      message,
      fallback: ErrorMessages.unknown,
      allowRawMessage: true,
    );
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: StandardText(
            text: safeMessage,
            fontSize: 14,
            color: Colors.white,
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
