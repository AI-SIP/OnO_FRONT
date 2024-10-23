import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ono/GlobalModule/Theme/LoadingDialog.dart';
import 'package:provider/provider.dart';
import '../../GlobalModule/Image/ColorPicker/ImageColorPickerHandler.dart';
import '../../GlobalModule/Image/ImagePickerHandler.dart';
import '../../GlobalModule/Theme/SnackBarDialog.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/LoginStatus.dart';
import '../../Model/ProblemModel.dart';
import '../../Model/TemplateType.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/UserProvider.dart';

class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: StandardText(
          text: '오답노트 템플릿 선택',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.015),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              children: TemplateType.values.map((templateType) {
                return Column(
                  children: [
                    _buildTemplateItem(
                      context: context,
                      templateType: templateType,
                      themeProvider: themeProvider,
                    ),
                    const Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateItem({
    required BuildContext context,
    required TemplateType templateType,
    required ThemeHandler themeProvider,
  }) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
          title: StandardText(
            text: templateType.displayName,
            fontSize: 18,
            color: themeProvider.primaryColor,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.005),
              ...templateType.description.map((desc) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: _getHighlightedDescription(desc, themeProvider),
              );
            }).toList(),
            ],
          ),
          onTap: () {
            final authService =
            Provider.of<UserProvider>(context, listen: false);

            if (authService.isLoggedIn != LoginStatus.login) {
              // 로그인하지 않은 경우
              SnackBarDialog.showSnackBar(
                  context: context,
                  message: "로그인 후에 오답노트를 작성할 수 있습니다!",
                  backgroundColor: Colors.red);
            } else {
              FirebaseAnalytics.instance
                  .logEvent(name: 'template_selection_${templateType.name}');

              final imagePickerHandler = ImagePickerHandler();
              imagePickerHandler.showImagePicker(context, (pickedFile) async {
                if (pickedFile != null) {
                  Map<String, dynamic>? colorPickerResult;

                  // TemplateType이 clean이나 special인 경우 색상 선택 화면 표시
                  if (templateType == TemplateType.clean ||
                      templateType == TemplateType.special) {
                    final colorPickerHandler = ImageColorPickerHandler();
                    colorPickerResult = await colorPickerHandler.showColorPicker(
                        context, pickedFile.path);
                  }

                  if(colorPickerResult != null){
                    LoadingDialog.show(context, '템플릿 불러오는 중...');

                    final result = await Provider.of<FoldersProvider>(context,
                        listen: false)
                        .uploadProblemImage(pickedFile);

                    // `result`에 받은 값을 사용하여 화면 이동
                    if (result != null) {
                      final problemId = result['problemId'];
                      final problemImageUrl = result['problemImageUrl'];

                      final problemModel = ProblemModel(
                        problemId: problemId,
                        problemImageUrl: problemImageUrl,
                        templateType: templateType,
                      );

                      LoadingDialog.hide(context);

                      Navigator.pushNamed(
                        context,
                        '/problemRegister',
                        arguments: {
                          'problemModel': problemModel,
                          'isEditMode': false,
                          'colorPickerResult': colorPickerResult,
                        },
                      );
                    } else {
                      SnackBarDialog.showSnackBar(
                          context: context,
                          message: "문제 이미지 업로드에 실패했습니다. 다시 시도해주세요.",
                          backgroundColor: Colors.red);
                    }
                  }
                }
              });
            }
          },
        ),
        Positioned(
          right: 15,
          top: 15,
          child: Container(
            width: 50, // 고정된 너비
            height: 50, // 고정된 높이
            alignment: Alignment.center, // 아이콘이 중앙에 오도록 설정
            child: _getTemplateIcon(templateType), // 템플릿에 맞는 아이콘 추가
          ),
        ),
      ],
    );
  }

  // 템플릿 타입에 따른 아이콘 설정 (SVG 파일로 교체)
  Widget _getTemplateIcon(TemplateType templateType) {
    switch (templateType) {
      case TemplateType.simple:
        return SvgPicture.asset(
          'assets/Icon/Pencil.svg',
          width: 50, // 적당한 크기로 설정
          height: 50,
        );
      case TemplateType.clean:
        return SvgPicture.asset(
          'assets/Icon/Eraser.svg',
          width: 50,
          height: 50,
        );
      case TemplateType.special:
        return SvgPicture.asset(
          'assets/Icon/Glass.svg',
          width: 50,
          height: 50,
        );
    }
  }

  Widget _getHighlightedDescription(String desc, ThemeHandler themeProvider) {
    List<TextSpan> spans = [];

    // **로 감싸진 텍스트 부분을 찾아서 강조
    final regex = RegExp(r'\*\*(.*?)\*\*');
    final matches = regex.allMatches(desc);
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    int lastMatchEnd = 0;

    for (final match in matches) {
      // 강조되지 않은 부분 추가
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: desc.substring(lastMatchEnd, match.start),
          style: standardTextStyle.copyWith(
            color: themeProvider.primaryColor,
            fontSize: 14,
          ),
        ));
      }

      // 강조된 부분 추가
      spans.add(TextSpan(
        text: match.group(1), // **로 감싸진 텍스트
        style: standardTextStyle.copyWith(
            color: themeProvider.primaryColor, fontSize: 16),
      ));

      lastMatchEnd = match.end;
    }

    // 마지막 남은 텍스트 추가
    if (lastMatchEnd < desc.length) {
      spans.add(TextSpan(
        text: desc.substring(lastMatchEnd),
        style: standardTextStyle.copyWith(
            color: Colors.black, fontSize: 14),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}