import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Image/ColorPicker/ImageColorPickerHandler.dart';
import 'package:ono/GlobalModule/Theme/DecorateText.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../GlobalModule/Image/ImagePickerHandler.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Util/DatePickerHandler.dart';
import '../../GlobalModule/Util/FolderSelectionDialog.dart';
import '../../Model/ProblemRegisterModel.dart';
import '../../Provider/UserProvider.dart';

class ProblemRegisterScreenService {
  final ImagePickerHandler imagePickerHandler = ImagePickerHandler();
  final ImageColorPickerHandler imageColorPickerHandler = ImageColorPickerHandler();

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

  Future<Map<String, dynamic>?> showFolderSelectionModal(BuildContext context) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return FolderSelectionDialog(); // 폴더 선택 다이얼로그
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10), // 모서리를 둥글게 설정
                child: Image.asset(
                  'assets/Logo.png',  // 로고 이미지 경로
                  width: 100,  // 이미지 크기
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              const DecorateText(
                text: '필기를 제거하는 중...',
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

  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  Future<void> showImagePicker(BuildContext context,
      Function(XFile?, List<Map<String, int>?>?, String) onImagePicked, String imageType, bool isProcess) async {
    imagePickerHandler.showImagePicker(context, (pickedFile) async {
      if (pickedFile != null && imageType == 'problemImage' && isProcess) {
        // problemImage의 경우 색상 선택 화면을 표시
        log('image path: ${pickedFile!.path}');
        List<Map<String, int>?> selectedColors = await imageColorPickerHandler.showColorPicker(context, pickedFile.path);
        onImagePicked(pickedFile, selectedColors, imageType);
      } else {
        // 다른 이미지 유형의 경우, 선택한 파일만 반환
        onImagePicked(pickedFile, [], imageType); // 색상 목록을 빈 리스트로 반환
      }
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
    final authService = Provider.of<UserProvider>(context, listen: false);
    if (authService.isLoggedIn == LoginStatus.logout) {
      _showLoginRequiredDialog(context);
      return;
    }

    if (!validateForm(context, problemData.reference, problemData.problemImage)) {
      return;
    }

    showLoadingDialog(context);

    try {
      await Provider.of<FoldersProvider>(context, listen: false)
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
      await Provider.of<FoldersProvider>(context, listen: false)
          .updateProblem(problemData);
      hideLoadingDialog(context);
      onSuccess();
      showSuccessDialog(context);
    } catch (error, stackTrace) {
      hideLoadingDialog(context);
      showValidationMessage(context, '문제 업데이트에 실패했습니다.');
      log('error in update problem : $error');
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const DecorateText(text: '로그인 필요',),
        content:
            const DecorateText(text: '문제를 등록하려면 로그인 해주세요!', ),
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
