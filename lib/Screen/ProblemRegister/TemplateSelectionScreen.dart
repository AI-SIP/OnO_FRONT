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


class TemplateSelectionScreen extends StatefulWidget {
  const TemplateSelectionScreen({super.key});

  @override
  _TemplateSelectionScreenState createState() => _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  int _selectedIndex = 0;

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTopTabs(screenHeight, screenWidth, themeProvider),
            const SizedBox(height: 20),
            Expanded(child: _buildPageView(screenHeight, screenWidth, themeProvider)),
            SizedBox(height: screenHeight * 0.01),  // '문제 등록하러 가기' 버튼과 콘텐츠 사이 여백을 줄임
            _buildSubmitButton(screenHeight, screenWidth, themeProvider),
          ],
        ),
      ),
    );
  }

  // 상단 탭 빌드 함수
  Widget _buildTopTabs(double screenHeight, double screenWidth, ThemeHandler themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(TemplateType.values.length, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                height: screenHeight * 0.05,
                width: screenWidth * 0.2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: _selectedIndex == index
                        ? themeProvider.primaryColor
                        : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    TemplateType.values[index].templateDetailImage,
                    width: screenHeight * 0.035,
                    height: screenHeight * 0.035,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // 페이지 뷰 빌드 함수
  Widget _buildPageView(double screenHeight, double screenWidth, ThemeHandler themeProvider) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: TemplateType.values.length,
          onPageChanged: (index) {
            setState(() => _selectedIndex = index);
          },
          itemBuilder: (context, index) {
            final templateType = TemplateType.values[index];
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTemplateImageAndTags(screenHeight, templateType, themeProvider),
                  SizedBox(height: screenHeight * 0.01),
                  // 템플릿 설명은 유동적으로 길어질 수 있도록 처리
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.15),
                    child: StandardText(
                      text: templateType.description,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                ],
              ),
            );
          },
        ),
        _buildNavigationButtons(screenHeight),
      ],
    );
  }

  // 템플릿 이미지와 태그 빌드 함수
  Widget _buildTemplateImageAndTags(double screenHeight, TemplateType templateType, ThemeHandler themeProvider) {
    return SizedBox(
      height: screenHeight * 0.45, // 이미지와 태그가 차지하는 고정된 공간
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            templateType.templateDetailImage,
            height: screenHeight * 0.2,
            fit: BoxFit.contain,
          ),
          SizedBox(height: screenHeight * 0.03),
          StandardText(
            text: templateType.displayName,
            fontSize: 24,
            color: themeProvider.primaryColor,
          ),
          SizedBox(height: screenHeight * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTag('필기 제거', templateType.hasEraseFeature, themeProvider),
              const SizedBox(width: 20),
              _buildTag('문제 분석', templateType.hasAnalysisFeature, themeProvider),
            ],
          ),
        ],
      ),
    );
  }

  // 좌우 네비게이션 버튼 빌드 함수
  Widget _buildNavigationButtons(double screenHeight) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: screenHeight * 0.3,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 24, color: Colors.grey),
            onPressed: () {
              if (_selectedIndex == 0) {
                _pageController.jumpToPage(TemplateType.values.length - 1);
              } else {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
        Positioned(
          right: 0,
          top: screenHeight * 0.3,
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 24, color: Colors.grey),
            onPressed: () {
              if (_selectedIndex == TemplateType.values.length - 1) {
                _pageController.jumpToPage(0);
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // 문제 등록 버튼 빌드 함수
  Widget _buildSubmitButton(double screenHeight, double screenWidth, ThemeHandler themeProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01), // 여백 줄임
      child: SizedBox(
        width: screenWidth * 0.8, // 가로 길이 화면의 80%
        child: ElevatedButton(
          onPressed: () {
            _onTemplateSelected(context, TemplateType.values[_selectedIndex]);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015), // 버튼 높이
          ),
          child: const StandardText(
            text: '문제 등록하러 가기',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // 태그 빌드 함수
  Widget _buildTag(String text, bool isActive, ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isActive ? themeProvider.primaryColor : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: StandardText(
        text: text,
        fontSize: 14,
        color: isActive ? themeProvider.primaryColor : Colors.grey,
      ),
    );
  }

  void _onTemplateSelected(BuildContext context, TemplateType templateType) {
    final authService = Provider.of<UserProvider>(context, listen: false);

    if (authService.isLoggedIn != LoginStatus.login) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: "로그인 후에 오답노트를 작성할 수 있습니다!",
        backgroundColor: Colors.red,
      );
      return;
    }

    FirebaseAnalytics.instance.logEvent(name: 'template_selection_${templateType.name}');

    final imagePickerHandler = ImagePickerHandler();
    imagePickerHandler.showImagePicker(context, (pickedFile) async {
      if (pickedFile != null) {
        Map<String, dynamic>? colorPickerResult;

        if (templateType == TemplateType.clean || templateType == TemplateType.special) {
          final colorPickerHandler = ImageColorPickerHandler();
          colorPickerResult = await colorPickerHandler.showColorPicker(
            context,
            pickedFile.path,
          );
        }

        if (templateType == TemplateType.simple || colorPickerResult != null) {
          LoadingDialog.show(context, '템플릿 불러오는 중...');
          final result = await Provider.of<FoldersProvider>(context, listen: false)
              .uploadProblemImage(pickedFile);

          if (result != null) {
            final problemModel = ProblemModel(
              problemId: result['problemId'],
              problemImageUrl: result['problemImageUrl'],
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
              backgroundColor: Colors.red,
            );
          }
        }
      }
    });
  }
}