import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Image/DisplayImage.dart';
import '../../Module/Image/FullScreenImage.dart';
import '../../Module/Text/HandWriteText.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Text/UnderlinedText.dart';
import '../../Module/Theme/GridPainter.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'Widget/ImageGallerySection.dart';

class ProblemDetailScreenWidget {
  // 배경 구현 함수
  Widget buildBackground(ThemeHandler themeProvider) {
    return CustomPaint(
      size: Size.infinite,
      painter:
          GridPainter(gridColor: themeProvider.primaryColor, isSpring: true),
    );
  }

  Widget buildCommonDetailView(BuildContext context, ProblemModel problemModel,
      ThemeHandler themeProvider) {
    double screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(screenHeight * 0.008), // 원하는 경우 여백 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.03),
            buildSolvedDate(problemModel.solvedAt, themeProvider),
            SizedBox(height: screenHeight * 0.03),
            buildProblemReference(problemModel.reference, themeProvider),
            SizedBox(
              height: screenHeight * 0.03,
            ),
            buildImageGallery(
              context: context,
              imageUrls: problemModel.problemImageDataList
                      ?.map((m) => m.imageUrl)
                      .toList() ??
                  [],
              label: '문제 이미지',
              color: themeProvider.primaryColor,
              themeProvider: themeProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildExpansionTile(BuildContext context, ProblemModel problemModel,
      ThemeHandler themeProvider) {
    final ScrollController tileScrollController = ScrollController();

    double screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      controller: tileScrollController,
      child: ExpansionTile(
        title: Container(
          padding: const EdgeInsets.all(8.0),
          child: buildCenteredTitle('정답 확인', Colors.black),
        ),
        children: [
          SizedBox(height: screenHeight * 0.01),
          buildSectionWithMemo(problemModel.memo, themeProvider),
          SizedBox(height: screenHeight * 0.02),
          SizedBox(height: screenHeight * 0.02),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            buildImageGallery(
              context: context,
              imageUrls: problemModel.answerImageDataList
                      ?.map((m) => m.imageUrl)
                      .toList() ??
                  [],
              label: '해설 이미지',
              color: themeProvider.primaryColor,
              themeProvider: themeProvider,
            ),
          ]),
          SizedBox(height: screenHeight * 0.03),
          buildRepeatSection(context, problemModel, themeProvider),
          SizedBox(height: screenHeight * 0.02),
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
  Widget buildProblemReference(String? reference, ThemeHandler themeProvider) {
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
                text: (reference != null && reference.isNotEmpty)
                    ? reference
                    : "작성한 출처가 없습니다!",
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

  // 한 줄에 아이콘과 텍스트가 동시에 오도록 하는 함수
  Widget buildIconTextRow(IconData icon, String label, Widget trailing,
      ThemeHandler themeProvider) {
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
          Icon(
            Icons.touch_app, // 복습 완료 전 터치 아이콘
            color: color,
            size: 16,
          ),
          const SizedBox(width: 10),
          StandardText(
            text: text,
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.bold, // 굵은 텍스트로 설정
          ),
        ],
      ),
    );
  }

  Widget buildImageGallery({
    required BuildContext context,
    required List<String> imageUrls,
    required String label,
    required Color color,
    required ThemeHandler themeProvider,
  }) {
    if (imageUrls.isEmpty) {
      return _buildEmptyImageSection(label, color, themeProvider);
    }

    return ImageGallerySection(
      imageUrls: imageUrls,
      label: label,
      color: color,
      themeProvider: themeProvider,
    );
  }

  Widget _buildEmptyImageSection(
      String label, Color color, ThemeHandler themeProvider) {
    // 기존에 아무 이미지 없을 때 보여주던 박스
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: StandardText(
          text: '이미지가 없습니다.',
          textAlign: TextAlign.center,
          color: themeProvider.primaryColor,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget buildRepeatSection(BuildContext context, ProblemModel problemModel,
      ThemeHandler themeProvider) {
    final mediaQuery = MediaQuery.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // '복습 기록' 제목과 복습 횟수 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book,
                    color: themeProvider.primaryColor), // 책 아이콘 추가
                const SizedBox(width: 8),
                HandWriteText(
                  text: '복습 기록',
                  fontSize: 20,
                  color: themeProvider.primaryColor,
                ),
              ],
            ),
            UnderlinedText(
              text: '복습 횟수: ${problemModel.solveImageDataList?.length ?? 0}',
              fontSize: 20,
              color: Colors.black,
            ),
          ],
        ),
        const SizedBox(height: 10.0),

        // 복습 날짜와 이미지 리스트
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: problemModel.solveImageDataList
                  ?.asMap()
                  .entries
                  .map((entry) {
                int index = entry.key;
                var solveImageModel = entry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 복습 날짜
                      UnderlinedText(
                        text:
                            '${index + 1}. 복습 날짜 : ${DateFormat('yyyy년 MM월 dd일').format(solveImageModel.createdAt)}',
                        fontSize: 18,
                        color: Colors.black,
                      ),

                      const SizedBox(height: 10.0),

                      GestureDetector(
                        onTap: () {
                          FirebaseAnalytics.instance
                              .logEvent(name: 'image_full_screen_solve_image');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImage(
                                imagePath: solveImageModel.imageUrl,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: mediaQuery.size.width,
                          height: mediaQuery.size.height * 0.5, // 고정된 높이로 변경
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DisplayImage(
                            imagePath: solveImageModel.imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10.0),
                    ],
                  ),
                );
              }).toList() ??
              [
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
}
