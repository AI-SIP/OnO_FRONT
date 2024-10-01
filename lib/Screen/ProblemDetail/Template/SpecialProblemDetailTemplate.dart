import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../GlobalModule/Image/DisplayImage.dart';
import '../../../GlobalModule/Image/FullScreenImage.dart';
import '../../../GlobalModule/Theme/HandWriteText.dart';
import '../../../GlobalModule/Theme/ThemeHandler.dart';
import '../../../Model/ProblemModel.dart';
import '../ProblemDetailScreenWidget.dart';
class SpecialProblemDetailTemplate extends StatelessWidget {
  final ProblemModel problemModel;
  final ProblemDetailScreenWidget problemDetailScreenWidget = ProblemDetailScreenWidget();

  SpecialProblemDetailTemplate({required this.problemModel, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        problemDetailScreenWidget.buildBackground(themeProvider),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0),
            child: Container(
              constraints: BoxConstraints(maxWidth: screenWidth), // 화면의 너비를 명시적으로 지정하여 무한 너비 방지
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (screenWidth > 600)
                    _buildWideLayout(context, themeProvider)
                  else
                    _buildNarrowLayout(context, themeProvider),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 화면 너비가 600 이상일 때의 레이아웃
  Widget _buildWideLayout(BuildContext context, ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측 영역 (푼 날짜와 문제 출처)
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30.0),
                  problemDetailScreenWidget.buildSolvedDate(problemModel.solvedAt, themeProvider),
                  const SizedBox(height: 30.0),
                  problemDetailScreenWidget.buildProblemReference(problemModel.reference, themeProvider),
                ],
              ),
            ),
            const SizedBox(width: 30.0), // 좌우 간격을 위한 여백
            // 우측 영역 (문제 이미지)
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25.0),
                  problemDetailScreenWidget.buildImageSection(
                    context,
                    problemModel.processImageUrl,
                    '문제 이미지',
                    themeProvider.primaryColor,
                    themeProvider,
                  ),
                  const SizedBox(height: 30.0),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0), // 위 아래 간격을 위한 여백
        _buildAnalysisExpansionTile(themeProvider, context), // 정답 및 해설 확인을 중앙에 배치
      ],
    );
  }

  /// 화면 너비가 600 이하일 때의 레이아웃
  Widget _buildNarrowLayout(BuildContext context, ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        problemDetailScreenWidget.buildSolvedDate(problemModel.solvedAt, themeProvider),
        const SizedBox(height: 25.0),
        problemDetailScreenWidget.buildProblemReference(problemModel.reference, themeProvider),
        const SizedBox(height: 30.0),
        problemDetailScreenWidget.buildImageSection(
          context,
          problemModel.processImageUrl,
          '문제 이미지',
          themeProvider.primaryColor,
          themeProvider,
        ),
        const SizedBox(height: 30.0),
        _buildAnalysisExpansionTile(themeProvider, context),
      ],
    );
  }

  Widget _buildAnalysisExpansionTile(ThemeHandler themeProvider, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따라 그리드의 컬럼 개수와 높이 비율 설정
    int crossAxisCount = 1;
    double childAspectRatio = 1.0; // 기본 비율

    if (screenWidth > 1100) {
      crossAxisCount = 3; // 1100px 이상일 때 3개
      childAspectRatio = 0.8; // 이미지의 높이 비율 조정
    } else if (screenWidth > 600) {
      crossAxisCount = 2; // 600px 이상일 때 2개
      childAspectRatio = 0.9; // 이미지의 높이 비율 조정
    } else {
      childAspectRatio = 0.9; // 600px 이하일 때 높이 비율 조정
    }

    return ExpansionTile(
      title: Container(
        padding: const EdgeInsets.all(8.0),
        child: ProblemDetailScreenWidget.buildCenteredTitle('해설 및 풀이 확인', themeProvider.primaryColor),
      ),
      children: [
        const SizedBox(height: 10.0),
        problemDetailScreenWidget.buildSectionWithMemo(problemModel.memo, themeProvider),
        const SizedBox(height: 20.0),
        problemDetailScreenWidget.buildLatexView(context, problemModel.analysis, themeProvider),
        const SizedBox(height: 20.0),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // 부모의 스크롤에 의해 이동 가능하게 설정
              mainAxisSpacing: 20.0,
              crossAxisSpacing: 20.0,
              childAspectRatio: childAspectRatio,
              children: [
                _buildImageContainer(context, problemModel.problemImageUrl, '원본 이미지', crossAxisCount, themeProvider),
                _buildImageContainer(context, problemModel.answerImageUrl, '해설 이미지', crossAxisCount, themeProvider),
                _buildImageContainer(context, problemModel.solveImageUrl, '풀이 이미지', crossAxisCount, themeProvider),
              ],
            );
          },
        ),
      ],
    );
  }

// 이미지 컨테이너를 빌드하는 함수
  Widget _buildImageContainer(BuildContext context, String? imageUrl, String label, int crossAxisCount, ThemeHandler themeProvider) {
    final mediaQuery = MediaQuery.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.camera_alt, color: themeProvider.primaryColor),
              const SizedBox(width: 8.0),
              HandWriteText(text: label, fontSize: 20, color: themeProvider.primaryColor),
            ],
          ),
        ),
        const SizedBox(height: 10.0),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImage(imagePath: imageUrl),
                  ),
                );
              },
              child: Container(
                width: mediaQuery.size.width * 0.8 / crossAxisCount, // 기기 크기 및 그리드 수에 맞게 크기 조절
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AspectRatio(
                  aspectRatio: 0.8, // 원하는 비율로 이미지의 높이를 조정
                  child: DisplayImage(
                    imagePath: imageUrl,
                    fit: BoxFit.contain, // 이미지 전체를 보여주기 위한 설정
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}