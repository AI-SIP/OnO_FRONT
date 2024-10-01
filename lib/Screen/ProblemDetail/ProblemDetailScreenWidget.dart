import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Image/DisplayImage.dart';
import '../../GlobalModule/Image/FullScreenImage.dart';
import '../../GlobalModule/Theme/GridPainter.dart';
import '../../GlobalModule/Theme/HandWriteText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Theme/UnderlinedText.dart';

class ProblemDetailScreenWidget{

  // 배경 구현 함수
  Widget buildBackground(ThemeHandler themeProvider) {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(gridColor: themeProvider.primaryColor),
    );
  }

  // 푼 날짜 위젯 구현 함수
  Widget buildSolvedDate(DateTime? solvedAt, ThemeHandler themeProvider) {
    final formattedDate =
    DateFormat('yyyy년 M월 d일').format(solvedAt!);
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
                text: reference ?? '출처 없음',
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

  // 이미지 띄워주는 위젯 구현 함수
  Widget buildImageSection(
      BuildContext context, String? imageUrl, String label, Color color, ThemeHandler themeProvider) {
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
              Icon(Icons.camera_alt, color: color),
              const SizedBox(width: 8.0),
              HandWriteText(text: label, fontSize: 20, color: color),
            ],
          ),
        ),
        const SizedBox(height: 20.0),
        Center(
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
              width: mediaQuery.size.width * 0.8, // 부모 크기 기준
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1), // 배경색 추가
                borderRadius: BorderRadius.circular(10), // 모서리 둥글게 설정
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
            fontSize: 24,
            color: color,
            fontWeight: FontWeight.bold, // 굵은 텍스트로 설정
          ),
        ],
      ),
    );
  }

  Widget buildNoDataScreen() {
    return const Center(
        child: HandWriteText(
          text: "문제 정보를 가져올 수 없습니다.",
          fontSize: 28,
        ));
  }
}