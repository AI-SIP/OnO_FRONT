import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../GlobalModule/Theme/ThemeHandler.dart';
import '../../../Model/ProblemModel.dart';
import '../ProblemDetailScreenWidget.dart';

class SimpleProblemDetailTemplate extends StatelessWidget {
  final ProblemModel problemModel;
  final ProblemDetailScreenWidget problemDetailScreenWidget = ProblemDetailScreenWidget();

  SimpleProblemDetailTemplate({required this.problemModel, Key? key}) : super(key: key);

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
                // 푼 날짜 위젯
                problemDetailScreenWidget.buildSolvedDate(problemModel.solvedAt, themeProvider),
                const SizedBox(height: 25.0),
                // 문제 출처 위젯
                problemDetailScreenWidget.buildProblemReference(problemModel.reference, themeProvider),
                const SizedBox(height: 30.0),
                // 문제 이미지 출력 위젯
                problemDetailScreenWidget.buildImageSection(
                  context,
                  problemModel.problemImageUrl,
                  '문제 이미지',
                  themeProvider.primaryColor,
                  themeProvider,
                ),
                const SizedBox(height: 30.0),
                // ExpansionTile 추가
                ExpansionTile(
                  title: ProblemDetailScreenWidget.buildCenteredTitle('해설 및 풀이 확인', themeProvider.primaryColor),
                  children: [
                    const SizedBox(height: 10.0),
                    // 메모 위젯
                    problemDetailScreenWidget.buildSectionWithMemo(problemModel.memo, themeProvider),
                    const SizedBox(height: 20.0),
                    // 해설 이미지 출력 위젯
                    problemDetailScreenWidget.buildImageSection(
                      context,
                      problemModel.answerImageUrl,
                      '해설 이미지',
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