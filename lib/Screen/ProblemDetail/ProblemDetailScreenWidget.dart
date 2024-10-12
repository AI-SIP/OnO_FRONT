import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:intl/intl.dart';
import 'package:ono/Model/TemplateType.dart';

import '../../GlobalModule/Image/DisplayImage.dart';
import '../../GlobalModule/Image/FullScreenImage.dart';
import '../../GlobalModule/Theme/GridPainter.dart';
import '../../GlobalModule/Theme/HandWriteText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Theme/UnderlinedText.dart';
import '../../GlobalModule/Util/LatexTextHandler.dart';
import '../../Model/ProblemModel.dart';

class ProblemDetailScreenWidget{

  // 배경 구현 함수
  Widget buildBackground(ThemeHandler themeProvider) {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(gridColor: themeProvider.primaryColor, isSpring: true),
    );
  }

  Widget buildCommonDetailView(
      BuildContext context, ProblemModel problemModel, ThemeHandler themeProvider, TemplateType templateType) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageUrl = (templateType == TemplateType.simple) ? problemModel.problemImageUrl : problemModel.processImageUrl;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0), // 원하는 경우 여백 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30.0),
            buildSolvedDate(problemModel.solvedAt, themeProvider),
            const SizedBox(height: 30.0),
            buildProblemReference(problemModel.reference, themeProvider),
            const SizedBox(height: 30.0),
            buildImageSection(context, imageUrl, (templateType == TemplateType.simple) ? '문제 이미지' : '보정 이미지', themeProvider.primaryColor, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget buildAnalysisExpansionTile(
      BuildContext context, ProblemModel problemModel, ThemeHandler themeProvider, TemplateType templateType) {
    final ScrollController latexScrollController = ScrollController();
    final ScrollController tileScrollController = ScrollController();

    return SingleChildScrollView(
      controller: tileScrollController,
      child: ExpansionTile(
        title: Container(
          padding: const EdgeInsets.all(8.0),
          child: buildCenteredTitle('정답 확인', themeProvider.primaryColor),
        ),
        children: [
          const SizedBox(height: 10.0),
          buildSectionWithMemo(problemModel.memo, themeProvider),
          const SizedBox(height: 20.0),
          if (templateType == TemplateType.special)
            buildLatexView(context, problemModel.analysis, latexScrollController, themeProvider),
          const SizedBox(height: 20.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: (templateType == TemplateType.simple)
                ? [_buildImageContainer(context, problemModel.answerImageUrl, '정답 이미지', themeProvider)]
                : [
              _buildImageContainer(context, problemModel.problemImageUrl, '원본 이미지', themeProvider),
              const SizedBox(height: 20.0),
              _buildImageContainer(context, problemModel.answerImageUrl, '정답 이미지', themeProvider),
              const SizedBox(height: 20.0),
              _buildImageContainer(context, problemModel.solveImageUrl, '풀이 이미지', themeProvider),
            ],
          ),
          const SizedBox(height: 20.0),
          buildRepeatSection(problemModel, themeProvider),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  // 푼 날짜 위젯 구현 함수
  Widget buildSolvedDate(DateTime? solvedAt, ThemeHandler themeProvider) {
    final formattedDate = DateFormat('yyyy년 M월 d일').format(solvedAt!);
    return buildIconTextRow(
      Icons.calendar_today,
      '푼 날짜',
      UnderlinedText(text: formattedDate, fontSize: 18),
      themeProvider,
    );
  }

  // 문제 출처 위젯 구현 함수
  Widget buildProblemReference(
      String? reference, ThemeHandler themeProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 레이블을 위로 정렬
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: themeProvider.primaryColor),
                  const SizedBox(width: 8),
                  HandWriteText(
                    text: '문제 출처',
                    fontSize: 20,
                    color: themeProvider.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              UnderlinedText(
                text: (reference != null && reference.isNotEmpty) ? reference : "작성한 출처가 없습니다!",
                fontSize: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 메모 위젯 구현 함수
  Widget buildSectionWithMemo(String? memo, ThemeHandler themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
        children: [
          buildIconTextRow(Icons.edit, '한 줄 메모', Container(), themeProvider),
          const SizedBox(height: 8.0),
          UnderlinedText(
            text: (memo?.isNotEmpty == true && memo != null)
                ? memo
                : '작성한 메모가 없습니다!',
          ),
        ],
      ),
    );
  }

  // Latex 형태의 텍스트를 출력해주는 함수
  Widget buildLatexView(BuildContext context, String? analysis, ScrollController scrollController, ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: themeProvider.primaryColor),
            const SizedBox(width: 10),
            HandWriteText(text: '문제 분석', fontSize: 20, color: themeProvider.primaryColor),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 70, // 제한된 너비 설정
            maxHeight: MediaQuery.of(context).size.height / 3, // 필요에 따라 최대 높이 설정
          ),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true, // 스크롤바 항상 보이도록 설정
            thickness: 6.0, // 스크롤바 두께
            radius: const Radius.circular(10), // 스크롤바 모서리 반경
            scrollbarOrientation: ScrollbarOrientation.right, // 스크롤바 위치
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.vertical,
              child: TeXView(
                fonts: const [
                  TeXViewFont(
                    fontFamily: 'HandWrite',
                    src: 'assets/fonts/HandWrite.ttf',
                  ),
                ],
                child: LatexTextHandler.renderLatex(analysis ?? ""),
                renderingEngine: const TeXViewRenderingEngine.mathjax(),
                style: const TeXViewStyle(
                  elevation: 0,
                  borderRadius: TeXViewBorderRadius.all(10),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 한 줄에 아이콘과 텍스트가 동시에 오도록 하는 함수
  Widget buildIconTextRow(IconData icon, String label, Widget trailing, ThemeHandler themeProvider) {
    return Row(
      children: [
        Icon(icon, color: themeProvider.primaryColor),
        const SizedBox(width: 8),
        HandWriteText(
            text: label, fontSize: 20, color: themeProvider.primaryColor),
        const Spacer(),
        trailing,
      ],
    );
  }

  //
  static Widget buildCenteredTitle(String text, Color color) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 8.0),
          UnderlinedText(
            text: text,
            fontSize: 26,
            color: color,
            fontWeight: FontWeight.bold, // 굵은 텍스트로 설정
          ),
        ],
      ),
    );
  }

  // 이미지 섹션 빌드 함수
  Widget buildImageSection(BuildContext context, String? imageUrl, String label, Color color, ThemeHandler themeProvider) {
    final mediaQuery = MediaQuery.of(context);
    double aspectRatio = 1.0;

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
              Icon(Icons.camera_alt, color: color),
              const SizedBox(width: 8.0),
              HandWriteText(text: label, fontSize: 20, color: color),
            ],
          ),
        ),
        const SizedBox(height: 10.0),
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImage(imagePath: imageUrl)));
            },
            child: Container(
              width: mediaQuery.size.width,
              height: mediaQuery.size.height * 0.5,
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: DisplayImage(imagePath: imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContainer(BuildContext context, String? imageUrl, String label, ThemeHandler themeProvider) {
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
        Center(
          child: GestureDetector(
            onTap: () {
              FirebaseAnalytics.instance.logEvent(name: 'image_full_screen_$label');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImage(imagePath: imageUrl),
                ),
              );
            },
            child: Container(
              height: mediaQuery.size.height * 0.5, // 고정된 높이로 변경
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DisplayImage(
                imagePath: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildRepeatSection(ProblemModel problemModel, ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // '복습 기록' 제목과 복습 횟수 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: themeProvider.primaryColor), // 책 아이콘 추가
                const SizedBox(width: 8),
                HandWriteText(
                  text: '복습 기록',
                  fontSize: 20,
                  color: themeProvider.primaryColor,
                ),
              ],
            ),
            UnderlinedText(
              text: '복습 횟수: ${problemModel.repeats?.length ?? 0}',
              fontSize: 20,
              color: Colors.black,
            ),
          ],
        ),
        const SizedBox(height: 10.0),

        // 복습 날짜 리스트
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: problemModel.repeats?.map((repeat) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: HandWriteText(
                text: DateFormat('yyyy년 MM월 dd일').format(repeat.createdAt),
                fontSize: 18,
                color: Colors.black,
              ),
            );
          }).toList() ?? [
            const HandWriteText(
              text: '복습 기록이 없습니다.',
              fontSize: 18,
              color: Colors.black,
            )
          ],
        ),
      ],
    );
  }

  Widget buildNoDataScreen() {
    return const Center(
        child: HandWriteText(
          text: "오답노트 정보를 가져올 수 없습니다.",
          fontSize: 28,
        ));
  }
}