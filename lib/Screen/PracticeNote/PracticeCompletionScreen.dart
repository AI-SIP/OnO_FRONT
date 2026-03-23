import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ono/Module/Dialog/SnackBarDialog.dart';
import 'package:provider/provider.dart';

import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';

class PracticeCompletionScreen extends StatelessWidget {
  final int practiceId;
  final int totalProblems;
  final int practiceRound;

  const PracticeCompletionScreen({
    super.key,
    required this.practiceId,
    required this.totalProblems,
    required this.practiceRound,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final practiceProvider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(themeProvider),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: buildCompletionContent(screenHeight),
          ),
          buildConfirmationButton(context, themeProvider, practiceProvider),
        ],
      ),
    );
  }

  AppBar buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      title: StandardText(
        text: '복습 완료',
        fontSize: 20,
        color: themeProvider.primaryColor,
      ),
      backgroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget buildCompletionContent(double screenHeight) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.2),
            Center(
              child: SvgPicture.asset(
                'assets/Icon/BigGreenFrog.svg',
                height: screenHeight * 0.2,
              ),
            ),
            SizedBox(height: screenHeight * 0.1),
            StandardText(
              text: '$practiceRound회차 복습을 완료했어요',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.01),
            StandardText(
              text: '총 $totalProblems문제를 풀었어요.',
              fontSize: 16,
              color: Colors.black54,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.2),
          ],
        ),
      ),
    );
  }

  Widget buildConfirmationButton(BuildContext context,
      ThemeHandler themeProvider, ProblemPracticeProvider practiceProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () async {
            await practiceProvider.addPracticeCount(practiceId);
            // 2번 pop: PracticeCompletionScreen -> PracticeDetailScreen -> PracticeThumbnailScreen
            // 두 번째 pop에서 true를 반환하여 썸네일 업데이트 신호 전달
            Navigator.of(context).pop(); // PracticeCompletionScreen 닫기
            Navigator.of(context)
                .pop(true); // PracticeDetailScreen 닫으면서 true 반환
            SnackBarDialog.showSnackBar(
              context: context,
              message: '복습을 완료했습니다!',
              backgroundColor: themeProvider.primaryColor,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const StandardText(
            text: "확인",
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
