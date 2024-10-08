import 'package:flutter/material.dart';

import 'StandardText.dart';

class SnackBarDialog {
  static void showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
  }) {
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: StandardText(
            text: message,
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