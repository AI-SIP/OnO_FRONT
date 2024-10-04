import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Image/DisplayImage.dart';
import '../../GlobalModule/Image/ImagePickerHandler.dart';
import '../../GlobalModule/Theme/HandWriteText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Util/DatePickerHandler.dart';
import '../../GlobalModule/Util/FolderSelectionDialog.dart';

class ProblemRegisterScreenWidget {
  // 날짜 선택 위젯
  static Widget dateSelection({
    required BuildContext context,
    required DateTime selectedDate,
    required Function(DateTime) onDateChanged,
    required ThemeHandler themeProvider,
  }) {
    return Row(
      children: <Widget>[
        Icon(Icons.calendar_today, color: themeProvider.primaryColor),
        const SizedBox(width: 10),
        HandWriteText(
          text: '푼 날짜',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
        const Spacer(),
        TextButton(
          onPressed: () async {

            FirebaseAnalytics.instance.logEvent(
              name: 'problem_register_date_select',
            );

            final newDate = await showModalBottomSheet<DateTime>(
              context: context,
              builder: (BuildContext context) {
                return DatePickerHandler(
                  initialDate: selectedDate,
                  onDateSelected: (selectedDate) {
                    Navigator.pop(context, selectedDate);
                  },
                );
              },
            );

            if (newDate != null) {
              onDateChanged(newDate); // 선택된 날짜를 콜백으로 전달
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(color: themeProvider.primaryColor, width: 2.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: HandWriteText(
            text: '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
            fontSize: 18,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }

  static Widget folderSelection({
    required int? selectedFolderId,
    required Function() onFolderSelected,
    required ThemeHandler themeProvider,
  }) {
    final folderName = FolderSelectionDialog.getFolderNameByFolderId(selectedFolderId);

    return Row(
      children: [
        Icon(Icons.folder, color: themeProvider.primaryColor),
        const SizedBox(width: 10),
        HandWriteText(
          text: '저장 폴더',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
        const Spacer(),
        TextButton(
          onPressed: onFolderSelected,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(color: themeProvider.primaryColor, width: 2.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: HandWriteText(
            text: folderName ?? '폴더 선택',
            fontSize: 18,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }

  // 라벨과 함께 텍스트 필드를 표시하는 함수
  static Widget buildLabeledField({
    required String label,
    required Widget child,
    required ThemeHandler themeProvider,
    IconData? icon, // Icon customization option
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon ?? Icons.label, color: themeProvider.primaryColor), // Use provided icon or default to label
            const SizedBox(width: 10),
            HandWriteText(
              text: label,
              fontSize: 20,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  // 텍스트 필드 위젯
  static Widget textField({
    required TextEditingController controller,
    required String hintText,
    required ThemeHandler themeProvider,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'HandWrite',
        color: themeProvider.primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: themeProvider.primaryColor, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: themeProvider.primaryColor, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: themeProvider.primaryColor, width: 2.0),
        ),
        fillColor: themeProvider.primaryColor.withOpacity(0.1),
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'HandWrite',
          color: themeProvider.desaturateColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: maxLines,
    );
  }

  static Widget buildActionButtons({
    required ThemeHandler themeProvider,
    required VoidCallback onSubmit,
    required VoidCallback onCancel,
    required bool isEditMode,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        TextButton(
          onPressed: onCancel,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.3),
            foregroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // Adjust corner radius
            ),
          ),
          child: HandWriteText(
            text: isEditMode ? '수정 취소' : '등록 취소',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        TextButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // Adjust corner radius
            ),
          ),
          child: HandWriteText(
            text: isEditMode ? '수정 완료' : '등록 완료',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  static Widget buildImagePicker({
    required BuildContext context,
    XFile? image,
    String? existingImageUrl,
    required Function(XFile?) onImagePicked,
  }) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Container( // Flexible 대신 Container로 변경
      height: 200, // 고정된 높이 지정
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: themeProvider.primaryColor.withOpacity(0.1),
        border: Border.all(color: themeProvider.primaryColor, width: 2.0),
      ),
      child: Center(
        child: image == null
            ? existingImageUrl != null
            ? GestureDetector(
          onTap: () {
            ImagePickerHandler().showImagePicker(context, onImagePicked);
          },
          child: DisplayImage(imagePath: existingImageUrl),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.image,
                  color: themeProvider.desaturateColor, size: 50),
              onPressed: () {
                ImagePickerHandler().showImagePicker(context, onImagePicked);
              },
            ),
            HandWriteText(
              text: '아이콘을 눌러 이미지를 추가해주세요!',
              color: themeProvider.desaturateColor,
              fontSize: 16,
            ),
          ],
        )
            : GestureDetector(
          onTap: () {
            ImagePickerHandler().showImagePicker(context, onImagePicked);
          },
          child: Image.file(File(image.path)),
        ),
      ),
    );
  }
}