import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../GlobalModule/Theme/ThemeHandler.dart';
import '../../../Model/ProblemModel.dart';
import '../ProblemDetailScreenWidget.dart';

class CleanProblemDetailTemplate extends StatelessWidget {
  final ProblemModel problemModel;
  final ProblemDetailScreenWidget problemDetailScreenWidget = ProblemDetailScreenWidget();

  CleanProblemDetailTemplate({required this.problemModel, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        problemDetailScreenWidget.buildBackground(themeProvider), // 격자무늬 배경 적용
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16.0),
                // 1. 푼 날짜 위젯
                problemDetailScreenWidget.buildSolvedDate(problemModel.solvedAt, themeProvider),
                const SizedBox(height: 25.0),
                // 2. 문제 출처 위젯
                problemDetailScreenWidget.buildProblemReference(problemModel.reference, themeProvider),
                const SizedBox(height: 30.0),
                // 3. processImage 위젯
                problemDetailScreenWidget.buildImageSection(
                  context,
                  problemModel.processImageUrl,
                  '문제 이미지',
                  themeProvider.primaryColor,
                  themeProvider,
                ),
                const SizedBox(height: 30.0),
                // ExpansionTile로 감싸서 정답 및 해설 확인 토글 적용
                ExpansionTile(
                  title: ProblemDetailScreenWidget.buildCenteredTitle('정답 및 해설 확인', themeProvider.primaryColor),
                  children: [
                    const SizedBox(height: 10.0),
                    // 4. 메모 위젯
                    problemDetailScreenWidget.buildSectionWithMemo(problemModel.memo, themeProvider),
                    const SizedBox(height: 20.0),
                    // 5. problemImage 위젯
                    problemDetailScreenWidget.buildImageSection(
                      context,
                      problemModel.problemImageUrl,
                      '원본 이미지',
                      themeProvider.primaryColor,
                      themeProvider,
                    ),
                    const SizedBox(height: 20.0),
                    // 6. answerImage 위젯
                    problemDetailScreenWidget.buildImageSection(
                      context,
                      problemModel.answerImageUrl,
                      '해설 이미지',
                      themeProvider.primaryColor,
                      themeProvider,
                    ),
                    const SizedBox(height: 20.0),
                    // 7. solveImage 위젯
                    problemDetailScreenWidget.buildImageSection(
                      context,
                      problemModel.solveImageUrl,
                      '풀이 이미지',
                      themeProvider.primaryColor,
                      themeProvider,
                    ),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}