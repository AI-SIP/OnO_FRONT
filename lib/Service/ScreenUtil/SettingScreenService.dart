import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../GlobalModule/Theme/DecorateText.dart';
import '../../GlobalModule/Theme/ThemeDialog.dart';
import '../../Service/Auth/AuthService.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';

class SettingScreenService {
  void showConfirmationDialog(
      BuildContext context,
      String title,
      String message,
      VoidCallback onConfirm) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: DecorateText(
              text: title, fontSize: 24, color: themeProvider.primaryColor),
          content: DecorateText(
              text: message, fontSize: 20, color: themeProvider.primaryColor),
          actions: [
            _buildDialogButton(context, '취소', Colors.black, () {
              Navigator.of(context).pop();
            }),
            _buildDialogButton(context, '확인', Colors.red, () async {
              Navigator.of(context).pop();
              onConfirm();
            }),
          ],
        );
      },
    );
  }

  TextButton _buildDialogButton(
      BuildContext context, String text, Color color, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: DecorateText(
        text: text,
        fontSize: 20,
        color: color,
      ),
    );
  }

  void showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ThemeDialog();
      },
    );
  }

  void showSuccessDialog(BuildContext context, String message) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DecorateText(
          text: message,
          fontSize: 20,
          color: Colors.white,
        ),
        backgroundColor: themeProvider.primaryColor,
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await Provider.of<AuthService>(context, listen: false).signOut();
    showSuccessDialog(context, '로그아웃에 성공했습니다.');
  }

  Future<void> deleteAccount(BuildContext context) async {
    await Provider.of<AuthService>(context, listen: false).deleteAccount();
    // Uncomment if you want to show a success message after account deletion
    // showSuccessDialog(context, '회원 탈퇴에 성공했습니다.');
  }
}