import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ono/GlobalModule/Image/ColorPicker/ImageCoordinatePickerHandler.dart';
import 'package:ono/GlobalModule/Theme/LoadingDialog.dart';
import 'package:ono/GlobalModule/Theme/UnderlinedText.dart';
import 'package:provider/provider.dart';
import '../../GlobalModule/Image/ColorPicker/ImageColorPickerHandler.dart';
import '../../GlobalModule/Image/ImagePickerHandler.dart';
import '../../GlobalModule/Theme/HandWriteText.dart';
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
  int _selectedIndex = 2;

  final storage = const FlutterSecureStorage();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeSelectedIndex();
  }

  Future<void> _initializeSelectedIndex() async {
    _selectedIndex = await getTemplateMethod();
    setState(() {
      _pageController.jumpToPage(_selectedIndex);
    });
  }

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
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            _buildTopTabs(screenHeight, screenWidth, themeProvider),
            Expanded(child: _buildPageView(screenHeight, screenWidth, themeProvider)),
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
                height: 40,
                width: 80,
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
                    width: 30,
                    height: 30,
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
                  SizedBox(height: screenHeight * 0.08),
                  _buildTemplateImageAndTags(screenHeight, templateType, themeProvider),
                  const SizedBox(height: 40),
                  // 템플릿 설명은 유동적으로 길어질 수 있도록 처리
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: StandardText(
                      text: templateType.description,
                      fontSize: 16,
                      color: Colors.black,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildHashTags(templateType, themeProvider), // 해시태그 추가
                  const SizedBox(height: 20),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          templateType.templateDetailImage,
          height: screenHeight * 0.18,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        StandardText(
          text: templateType.displayName,
          fontSize: 25,
          color: Colors.black,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTag('필기 제거', templateType.hasEraseFeature, themeProvider),
            const SizedBox(width: 20),
            _buildTag('문제 분석', templateType.hasAnalysisFeature, themeProvider),
          ],
        ),
      ],
    );
    /*
    return SizedBox(
      height: screenHeight * 0.4, // 이미지와 태그가 차지하는 고정된 공간
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            templateType.templateDetailImage,
            height: screenHeight * 0.16,
            fit: BoxFit.contain,
          ),
          SizedBox(height: screenHeight * 0.02),
          StandardText(
            text: templateType.displayName,
            fontSize: 24,
            color: Colors.black,
          ),
          SizedBox(height: screenHeight * 0.02),
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

     */
  }

  Widget _buildHashTags(TemplateType templateType, ThemeHandler themeProvider) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      runSpacing: 8.0,
      children: templateType.hashTags.map((tag) {
        return UnderlinedText(
          text: tag,
          fontSize: 18,
          color: Colors.black,
        );
      }).toList(),
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
            icon: const Icon(Icons.arrow_back_ios, size: 24, color: Colors.black),
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
            icon: const Icon(Icons.arrow_forward_ios, size: 24, color: Colors.black),
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
        width: screenWidth * 0.7, // 가로 길이 화면의 80%
        child: ElevatedButton(
          onPressed: () {
            _onTemplateSelected(context, TemplateType.values[_selectedIndex]);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10), // 버튼 높이
          ),
          child: const StandardText(
            text: '오답노트 작성하러 가기',
            fontSize: 15,
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
        fontSize: 13,
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
    saveTemplateMethod(templateType);

    final imagePickerHandler = ImagePickerHandler();
    imagePickerHandler.showImagePicker(context, (pickedFile) async {
      if (pickedFile != null) {
        Map<String, dynamic>? colorPickerResult;
        List<List<double>>? coordinatePickerResult;

        if (templateType == TemplateType.clean || templateType == TemplateType.special) {
          final colorPickerHandler = ImageColorPickerHandler();
          final coordinatePickerHandler = ImageCoordinatePickerHandler();
          coordinatePickerResult = await coordinatePickerHandler.showCoordinatePicker(
              context,
              pickedFile.path
          );
          log(coordinatePickerResult.toString());

          /*
          colorPickerResult = await colorPickerHandler.showColorPicker(
            context,
            pickedFile.path,
          );

           */
        }

        if (templateType == TemplateType.simple || coordinatePickerResult != null) {
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
                'coordinatePickerResult' : coordinatePickerResult,
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

  Future<void> saveTemplateMethod(TemplateType templateType) async {
    await storage.write(key: 'templateMethod', value: templateType.index.toString());
  }

  Future<int> getTemplateMethod() async {
    String? templateIndex = await storage.read(key: 'templateMethod');

    if(templateIndex != null){
      return int.parse(templateIndex);
    }

    return TemplateType.special.index;
  }
}