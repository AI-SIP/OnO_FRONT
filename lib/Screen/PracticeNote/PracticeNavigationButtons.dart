import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Screen/PracticeNote/PracticeCompletionScreen.dart';
import 'package:ono/Screen/PracticeNote/ProblemReviewCompletionScreen.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';
import 'package:provider/provider.dart';

import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';

class PracticeNavigationButtons extends StatefulWidget {
  final BuildContext context;
  final ProblemPracticeProvider practiceProvider;
  final int currentProblemId;
  final VoidCallback onRefresh;

  const PracticeNavigationButtons({
    super.key,
    required this.context,
    required this.practiceProvider,
    required this.currentProblemId,
    required this.onRefresh,
  });

  @override
  _PracticeNavigationButtonsState createState() =>
      _PracticeNavigationButtonsState();
}

class _PracticeNavigationButtonsState extends State<PracticeNavigationButtons> {
  bool isReviewed = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress Text가 상단에 단독으로 표시되도록 설정
        buildProgressText(themeProvider),
        const SizedBox(height: 8), // 간격 추가
        // 아래에 버튼들이 나란히 배치
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildPreviousButton(themeProvider, screenHeight),
            buildSolveButton(themeProvider, screenHeight),
            buildNextOrCompleteButton(themeProvider, screenHeight),
          ],
        ),
      ],
    );
  }

  TextButton buildPreviousButton(
      ThemeHandler themeProvider, double screenHeight) {
    final int currentIndex = getCurrentProblemIndex();
    final int previousProblemId = getPreviousProblemId(currentIndex);

    return TextButton(
      onPressed: currentIndex > 0
          ? () => navigateToProblem(previousProblemId, isNext: false)
          : null,
      style:
          _buildButtonStyle(themeProvider, screenHeight, isCompletion: false),
      child: StandardText(
        text: '< 이전 문제',
        fontSize: 14,
        color: themeProvider.primaryColor,
      ),
    );
  }

  StandardText buildProgressText(ThemeHandler themeProvider) {
    final int currentIndex = getCurrentProblemIndex();
    final int totalProblems = widget.practiceProvider.currentProblems.length;

    return StandardText(
      text: '${currentIndex + 1} / $totalProblems',
      fontSize: 16,
      color: themeProvider.primaryColor,
    );
  }

  TextButton buildSolveButton(ThemeHandler themeProvider, double screenHeight) {
    return TextButton(
      onPressed: isReviewed ? null : () => problemSolveDialog(context),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: themeProvider.primaryColor,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      child: isReviewed
          ? Icon(
              Icons.check,
              color: themeProvider.primaryColor,
              size: 20,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app,
                  color: themeProvider.primaryColor,
                  size: 15,
                ),
                const SizedBox(width: 10),
                StandardText(
                  text: '문제 복습',
                  fontSize: 14,
                  color: themeProvider.primaryColor,
                ),
              ],
            ),
    );
  }

  TextButton buildNextOrCompleteButton(
      ThemeHandler themeProvider, double screenHeight) {
    final int currentIndex = getCurrentProblemIndex();
    final int nextProblemId = getNextProblemId(currentIndex);

    return TextButton(
      onPressed: nextProblemId != -1
          ? () => navigateToProblem(nextProblemId, isNext: true)
          : () => _showCompletionScreen(),
      style: _buildButtonStyle(themeProvider, screenHeight,
          isCompletion: nextProblemId == -1),
      child: StandardText(
        text: nextProblemId != -1 ? '다음 문제 >' : '복습 마치기',
        fontSize: 14,
        color: nextProblemId != -1 ? themeProvider.primaryColor : Colors.white,
      ),
    );
  }

  int getCurrentProblemIndex() {
    return widget.practiceProvider.currentProblems.indexWhere(
      (problem) => problem.problemId == widget.currentProblemId,
    );
  }

  int getPreviousProblemId(int currentIndex) {
    final currentProblems = widget.practiceProvider.currentProblems;
    return currentIndex > 0
        ? currentProblems[currentIndex - 1].problemId
        : currentProblems.first.problemId;
  }

  int getNextProblemId(int currentIndex) {
    final currentProblems = widget.practiceProvider.currentProblems;
    return currentIndex < currentProblems.length - 1
        ? currentProblems[currentIndex + 1].problemId
        : -1;
  }

  void navigateToProblem(int problemId, {required bool isNext}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProblemDetailScreen(
          problemId: problemId,
          isPractice: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final Offset begin =
              isNext ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: RotationTransition(
              alignment: Alignment.bottomRight,
              turns: Tween(begin: isNext ? 0.1 : -0.1, end: 0.0)
                  .animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showCompletionScreen() {
    final practiceId = widget.practiceProvider.currentPracticeNote!.practiceId;
    final totalProblems = widget.practiceProvider.currentProblems.length;
    final practiceRound = widget.practiceProvider.practices
            .firstWhere((practice) => practice.practiceId == practiceId)
            .practiceCount ??
        0;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PracticeCompletionScreen(
          practiceId: practiceId,
          totalProblems: totalProblems,
          practiceRound: practiceRound + 1,
        ),
      ),
    );
  }

  void problemSolveDialog(BuildContext context) async {
    FirebaseAnalytics.instance.logEvent(name: 'problem_repeat_button_click');

    // 전체 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProblemReviewCompletionScreen(
          problemId: widget.currentProblemId,
          onRefresh: widget.onRefresh,
        ),
      ),
    );

    // 복습 완료 시 isReviewed 상태 업데이트
    if (result == true) {
      setState(() {
        isReviewed = true;
      });
    }
  }

  ButtonStyle _buildButtonStyle(ThemeHandler themeProvider, double screenHeight,
      {required bool isCompletion}) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      backgroundColor: isCompletion ? themeProvider.primaryColor : Colors.white,
      side: BorderSide(color: themeProvider.primaryColor, width: 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
    );
  }
}
