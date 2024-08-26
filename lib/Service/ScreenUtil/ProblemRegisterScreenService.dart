import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/DecorateText.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../GlobalModule/Image/ImagePickerHandler.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Util/DatePickerHandler.dart';
import '../../Model/ProblemRegisterModel.dart';
import '../../Provider/ProblemsProvider.dart';
import '../Auth/AuthService.dart';

class ProblemRegisterScreenService {
  final ImagePickerHandler imagePickerHandler = ImagePickerHandler();

  Future<void> showCustomDatePicker(BuildContext context, DateTime selectedDate,
      ValueSetter<DateTime> onDateSelected) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return DatePickerHandler(
          initialDate: selectedDate,
          onDateSelected: onDateSelected,
        );
      },
    );
  }

  void showSuccessDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const DecorateText(
          text: '문제가 성공적으로 저장되었습니다.',
          fontSize: 20,
          color: Colors.white,
        ),
        backgroundColor: themeProvider.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showValidationMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DecorateText(
          text: message,
          fontSize: 20,
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  Future<void> showImagePicker(BuildContext context,
      Function(XFile?, String) onImagePicked, String imageType) async {
    imagePickerHandler.showImagePicker(context, (pickedFile) {
      onImagePicked(pickedFile, imageType);
    });
  }

  bool validateForm(BuildContext context,
      String? reference, XFile? problemImage) {
    if(reference == null) {
      showValidationMessage(context, '출처는 필수 항목입니다.');
      return false;
    }
    if (problemImage == null) {
      showValidationMessage(context, '문제 이미지는 필수 항목입니다.');
      return false;
    }
    return true;
  }

  Future<void> submitProblem(
      BuildContext context,
      ProblemRegisterModel problemData,
      VoidCallback onSuccess) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isLoggedIn == LoginStatus.logout) {
      _showLoginRequiredDialog(context);
      return;
    }

    if (!validateForm(context, problemData.reference, problemData.problemImage)) {
      return;
    }

    showLoadingDialog(context);

    try {
      await Provider.of<ProblemsProvider>(context, listen: false)
          .submitProblem(problemData, context);
      hideLoadingDialog(context);
      onSuccess();
      showSuccessDialog(context);
    } catch (error) {
      hideLoadingDialog(context);
    }
  }

  Future<void> updateProblem(
      BuildContext context,
      ProblemRegisterModel problemData,
      VoidCallback onSuccess) async {
    showLoadingDialog(context);

    try {
      await Provider.of<ProblemsProvider>(context, listen: false)
          .updateProblem(problemData);
      hideLoadingDialog(context);
      onSuccess();
      showSuccessDialog(context);
    } catch (error) {
      hideLoadingDialog(context);
      showValidationMessage(context, '문제 업데이트에 실패했습니다.');
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그인 필요', style: TextStyle(fontSize: 24)),
        content:
            const Text('문제를 등록하려면 로그인 해주세요!', style: TextStyle(fontSize: 20)),
        actions: <Widget>[
          TextButton(
            child: const DecorateText(
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
