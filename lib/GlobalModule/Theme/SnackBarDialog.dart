import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/DecorateText.dart';

class SnackBarDialog {
  static void showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
  }) {
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: DecorateText(
            text: message,
            fontSize: 20,
            color: Colors.white,
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}