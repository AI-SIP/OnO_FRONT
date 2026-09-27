import 'package:flutter/material.dart';

import '../Motion/AppLoadingView.dart';
import '../Motion/TossDialog.dart';

class LoadingDialog {
  static bool _isShowing = false;

  static void show(BuildContext context, String message) {
    if (_isShowing || !context.mounted) {
      return;
    }

    _isShowing = true;
    showTossDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: AppLoadingCard(message: message),
        );
      },
    ).whenComplete(() => _isShowing = false);
  }

  static void hide(BuildContext context) {
    if (!_isShowing || !context.mounted) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    hideFromNavigator(navigator);
  }

  static void hideFromNavigator(NavigatorState navigator) {
    if (!_isShowing || !navigator.mounted) {
      return;
    }

    _isShowing = false;

    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
