import 'package:flutter/material.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Module/Image/ColorPicker/ImageColorPickerHandler.dart';
import 'package:ono/Module/Text/HandWriteText.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemRegisterModel.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Image/ImagePickerHandler.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/UserProvider.dart';

class ProblemRegisterScreenService {
  final ImagePickerHandler imagePickerHandler = ImagePickerHandler();
  final ImageColorPickerHandler imageColorPickerHandler =
      ImageColorPickerHandler();

  void showSuccessDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    SnackBarDialog.showSnackBar(
        context: context,
        message: "오답노트가 성공적으로 저장되었습니다.",
        backgroundColor: themeProvider.primaryColor);
  }

  void showValidationMessage(BuildContext context, String message) {
    SnackBarDialog.showSnackBar(
        context: context,
        message: "오답노트 작성 과정에서 오류가 발생했습니다.",
        backgroundColor: Colors.red);
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  Future<void> submitProblem(BuildContext context,
      ProblemRegisterModel problemData, VoidCallback onSuccess) async {
    final authService = Provider.of<UserProvider>(context, listen: false);
    if (authService.isLoggedIn == LoginStatus.logout) {
      _showLoginRequiredDialog(context);
      return;
    }

    try {
      await Provider.of<FoldersProvider>(context, listen: false)
          .submitProblem(problemData, context);
      onSuccess();
      showSuccessDialog(context);
    } catch (error) {
      hideLoadingDialog(context);
    }
  }

  Future<void> submitProblemV2(BuildContext context,
      ProblemRegisterModel problemData, VoidCallback onSuccess) async {
    final authService = Provider.of<UserProvider>(context, listen: false);
    if (authService.isLoggedIn == LoginStatus.logout) {
      _showLoginRequiredDialog(context);
      return;
    }

    try {
      await Provider.of<FoldersProvider>(context, listen: false)
          .submitProblem(problemData, context);
      onSuccess();
      showSuccessDialog(context);
    } catch (error) {
      hideLoadingDialog(context);
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const HandWriteText(
          text: '로그인 필요',
        ),
        content: const HandWriteText(
          text: '오답노트를 작성하려면 로그인 해주세요!',
        ),
        actions: <Widget>[
          TextButton(
            child: const HandWriteText(
              text: '확인',
              fontSize: 20,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // 다이얼로그 닫기
            },
          )
        ],
      ),
    );
  }
}
