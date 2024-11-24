import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Image/DisplayImage.dart';
import '../../GlobalModule/Image/ImagePickerHandler.dart';
import '../../GlobalModule/Theme/StandardText.dart';
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
        StandardText(
          text: '푼 날짜',
          fontSize: 16,
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
          child: StandardText(
            text: '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
            fontSize: 14,
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
        Icon(Icons.menu_book_outlined, color: themeProvider.primaryColor),
        const SizedBox(width: 10),
        StandardText(
          text: '공책 선택',
          fontSize: 16,
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
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/Icon/GreenNote.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 15,),
              StandardText(
                text: folderName ?? '책장',
                fontSize: 14,
                color: themeProvider.primaryColor,
              ),
              ],
            )
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
            StandardText(
              text: label,
              fontSize: 16,
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
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    return TextField(
      controller: controller,
      style: standardTextStyle.copyWith(
          color: themeProvider.primaryColor,
          fontSize: 16
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
        hintStyle: standardTextStyle.copyWith(
            color: themeProvider.desaturateColor,
            fontSize: 12,
        ),
      ),
      maxLines: maxLines,
    );
  }

  static Widget buildActionButtons({
    required BuildContext context,
    required ThemeHandler themeProvider,
    required VoidCallback onSubmit,
    required VoidCallback onCancel,
    required bool isEditMode,
  }) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenHeight * 0.01),
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // Adjust corner radius
            ),
          ),
          child: StandardText(
            text: isEditMode ? '수정 완료' : '문제 등록',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
    );
  }

  static Widget buildImagePicker({
    required BuildContext context,
    XFile? image,
    String? existingImageUrl,
    required Function(XFile?) onImagePicked,
  }) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.4, // 고정된 높이 지정
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: themeProvider.primaryColor.withOpacity(0.1),
        border: Border.all(color: themeProvider.primaryColor, width: 1.5),
      ),
      child: Padding( // Padding 추가
        padding: const EdgeInsets.all(10.0), // 이미지와 테두리 사이에 8px 패딩 적용
        child: Center(
          child: image == null
              ? existingImageUrl != null
              ? GestureDetector(
            onTap: () {
              ImagePickerHandler().showImagePicker(context, onImagePicked);
            },
            child: ClipRRect( // 이미지에 radius 적용
              //borderRadius: BorderRadius.circular(10), // radius 10 적용
              child: DisplayImage(imagePath: existingImageUrl),
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.image,
                  color: themeProvider.desaturateColor,
                  size: 50,
                ),
                onPressed: () {
                  ImagePickerHandler().showImagePicker(context, onImagePicked);
                },
              ),
              StandardText(
                text: '아이콘을 눌러 이미지를 추가해주세요!',
                color: themeProvider.desaturateColor,
                fontSize: 12,
              ),
            ],
          )
              : GestureDetector(
            onTap: () {
              ImagePickerHandler().showImagePicker(context, onImagePicked);
            },
            child: ClipRRect( // 이미지에 radius 적용
              borderRadius: BorderRadius.circular(10), // radius 10 적용
              child: Image.file(File(image.path)),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildImagePickerWithLabel({
    required String label,
    required XFile? image,
    required String? existingImageUrl,
    required ThemeHandler themeProvider,
    required BuildContext context,
    required Function(XFile? pickedFile) onImagePicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, color: themeProvider.primaryColor),
            const SizedBox(width: 10),
            StandardText(
              text: label,
              fontSize: 16,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          child: buildImagePicker(
            context: context,
            image: image,
            existingImageUrl: existingImageUrl,
            onImagePicked: onImagePicked,
          ),
        ),
      ],
    );
  }
}