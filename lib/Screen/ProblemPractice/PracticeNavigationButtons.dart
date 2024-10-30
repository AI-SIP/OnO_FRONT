import 'package:flutter/material.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreenV2.dart';
import 'package:ono/Screen/ProblemPractice/PracticeCompletionScreen.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Provider/ProblemPracticeProvider.dart';

class PracticeNavigationButtons extends StatefulWidget {
  final BuildContext context;
  final ProblemPracticeProvider practiceProvider;
  final int currentId;
  final VoidCallback onRefresh;

  const PracticeNavigationButtons({
    super.key,
    required this.context,
    required this.practiceProvider,
    required this.currentId,
    required this.onRefresh,
  });

  @override
  _PracticeNavigationButtonsState createState() =>
      _PracticeNavigationButtonsState();
}

class _PracticeNavigationButtonsState extends State<PracticeNavigationButtons> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildPreviousButton(themeProvider, screenHeight),
        buildProgressText(themeProvider),
        buildNextOrCompleteButton(themeProvider, screenHeight),
      ],
    );
  }

  TextButton buildPreviousButton(ThemeHandler themeProvider, double screenHeight) {
    final int currentIndex = getCurrentIndex();
    final int previousProblemId = getPreviousProblemId(currentIndex);

    return TextButton(
      onPressed: currentIndex > 0
          ? () => navigateToProblem(previousProblemId, isNext: false)
          : null,
      style: _buildButtonStyle(themeProvider, screenHeight, isCompletion: false),
      child: StandardText(
        text: '< 이전 문제',
        fontSize: screenHeight * 0.012,
        color: themeProvider.primaryColor,
      ),
    );
  }

  StandardText buildProgressText(ThemeHandler themeProvider) {
    final int currentIndex = getCurrentIndex();
    final int totalProblems = widget.practiceProvider.problemIds.length;

    return StandardText(
      text: '${currentIndex + 1} / $totalProblems',
      fontSize: 16,
      color: themeProvider.primaryColor,
    );
  }

  TextButton buildNextOrCompleteButton(ThemeHandler themeProvider, double screenHeight) {
    final int currentIndex = getCurrentIndex();
    final int nextProblemId = getNextProblemId(currentIndex);

    return TextButton(
      onPressed: nextProblemId != -1
          ? () => navigateToProblem(nextProblemId, isNext: true)
          : () => _showCompletionScreen(),
      style: _buildButtonStyle(themeProvider, screenHeight, isCompletion: nextProblemId == -1),
      child: StandardText(
        text: nextProblemId != -1 ? '다음 문제 >' : '복습 마치기',
        fontSize: screenHeight * 0.012,
        color: nextProblemId != -1 ? themeProvider.primaryColor : Colors.white,
      ),
    );
  }

  int getCurrentIndex() {
    return widget.practiceProvider.problemIds.indexOf(widget.currentId);
  }

  int getPreviousProblemId(int currentIndex) {
    final problemIds = widget.practiceProvider.problemIds;
    return currentIndex > 0 ? problemIds[currentIndex - 1] : problemIds.first;
  }

  int getNextProblemId(int currentIndex) {
    final problemIds = widget.practiceProvider.problemIds;
    return currentIndex < problemIds.length - 1 ? problemIds[currentIndex + 1] : -1;
  }

  void navigateToProblem(int problemId, {required bool isNext}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProblemDetailScreenV2(
              problemId: problemId,
              isPractice: true,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final Offset begin = isNext ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: RotationTransition(
              alignment: Alignment.bottomRight,
              turns: Tween(begin: isNext ? 0.1 : -0.1, end: 0.0).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showCompletionScreen() {
    final practiceId = widget.practiceProvider.currentPracticeId;
    final totalProblems = widget.practiceProvider.problemIds.length;
    final practiceRound = widget.practiceProvider.practiceThumbnails
        ?.firstWhere((thumbnail) => thumbnail.practiceId == practiceId)
        .practiceCount ?? 0;

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

  ButtonStyle _buildButtonStyle(ThemeHandler themeProvider, double screenHeight, {required bool isCompletion}) {
    return ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.02, vertical: screenHeight * 0.008),
      backgroundColor: isCompletion ? themeProvider.primaryColor : Colors.white,
      side: BorderSide(color: themeProvider.primaryColor, width: 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
    );
  }
}