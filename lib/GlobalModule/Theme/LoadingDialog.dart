import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'HandWriteText.dart';

class LoadingDialog {
  static void show(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SvgPicture.asset(
                  'assets/Logo/GreenFrog.svg',  // 로고 이미지 경로
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              HandWriteText(
                text: message,
                fontSize: 24,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}