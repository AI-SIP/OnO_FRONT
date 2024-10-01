import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:provider/provider.dart';

import '../../../GlobalModule/Theme/ThemeHandler.dart';
import '../../../GlobalModule/Util/LatexTextHandler.dart';
import '../../../Model/ProblemModel.dart';
import '../ProblemDetailScreenWidget.dart';


class SpecialProblemDetailTemplate extends StatelessWidget {
  final ProblemModel problemModel;

  const SpecialProblemDetailTemplate({required this.problemModel, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          ProblemDetailScreenWidget().buildBackground(themeProvider),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 화면 너비에 따른 배치 결정
                  if (screenWidth > 600)
                    _buildWideLayout(context, themeProvider)
                  else
                    _buildNarrowLayout(context, themeProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 화면 너비가 600 이상일 때의 레이아웃
  Widget _buildWideLayout(BuildContext context, ThemeHandler themeProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 좌측 영역 (푼 날짜와 문제 출처)
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30.0),
              ProblemDetailScreenWidget().buildSolvedDate(problemModel.solvedAt, themeProvider),
              const SizedBox(height: 30.0),
              ProblemDetailScreenWidget().buildProblemReference(problemModel.reference, themeProvider),
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
              ProblemDetailScreenWidget().buildImageSection(
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
        _buildAnalysisExpansionTile(themeProvider, context),
      ],
    );
  }

  /// 화면 너비가 600 이하일 때의 레이아웃
  Widget _buildNarrowLayout(BuildContext context, ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        ProblemDetailScreenWidget().buildSolvedDate(problemModel.solvedAt, themeProvider),
        const SizedBox(height: 25.0),
        ProblemDetailScreenWidget().buildProblemReference(problemModel.reference, themeProvider),
        const SizedBox(height: 30.0),
        ProblemDetailScreenWidget().buildImageSection(
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



  /// 분석 결과를 포함한 ExpansionTile 구성
  Widget _buildAnalysisExpansionTile(ThemeHandler themeProvider, BuildContext context) {
    return ExpansionTile(
      title: ProblemDetailScreenWidget.buildCenteredTitle('정답 및 해설 확인', themeProvider.primaryColor),
      children: [
        const SizedBox(height: 10.0),
        ProblemDetailScreenWidget().buildSectionWithMemo(problemModel.memo, themeProvider),
        const SizedBox(height: 20.0),
        ProblemDetailScreenWidget().buildLatexView(context, problemModel.analysis, themeProvider),
        const SizedBox(height: 20.0),
        ProblemDetailScreenWidget().buildImageSection(
          context,
          problemModel.problemImageUrl,
          '문제 원본 이미지',
          themeProvider.primaryColor,
          themeProvider,
        ),
        const SizedBox(height: 20.0),
        ProblemDetailScreenWidget().buildImageSection(
          context,
          problemModel.answerImageUrl,
          '해설 이미지',
          themeProvider.primaryColor,
          themeProvider,
        ),
        const SizedBox(height: 20.0),
        ProblemDetailScreenWidget().buildImageSection(
          context,
          problemModel.solveImageUrl,
          '풀이 이미지',
          themeProvider.primaryColor,
          themeProvider,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}