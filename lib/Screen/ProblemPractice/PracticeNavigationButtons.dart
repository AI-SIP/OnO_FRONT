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
    final problemIds = widget.practiceProvider.problemIds;
    double screenHeight = MediaQuery.of(context).size.height;

    if (problemIds.isEmpty) {
      return const Center();
    }

    int currentIndex = problemIds.indexOf(widget.currentId);
    int previousProblemId =
    currentIndex > 0 ? problemIds[currentIndex - 1] : problemIds.first;
    int nextProblemId =
    currentIndex < problemIds.length - 1 ? problemIds[currentIndex + 1] : -1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: currentIndex > 0
              ? () => navigateToProblem(context, previousProblemId, isNext: false)
              : null,
          style: _buildButtonStyle(themeProvider, screenHeight, isCompletion: falsedes),
          child: StandardText(
            text: '< 이전 문제',
            fontSize: screenHeight * 0.012,
            color: themeProvider.primaryColor,
          ),
        ),
        StandardText(
          text: '${currentIndex + 1} / ${problemIds.length}',
          fontSize: 16,
          color: themeProvider.primaryColor,
        ),
        TextButton(
          onPressed: nextProblemId != -1
              ? () => navigateToProblem(context, nextProblemId, isNext: true)
              : _showCompletionScreen,
          style: _buildButtonStyle(themeProvider, screenHeight, isCompletion: nextProblemId == -1),
          child: StandardText(
            text: nextProblemId != -1 ? '다음 문제 >' : '복습 마치기',
            fontSize: screenHeight * 0.012,
            color: nextProblemId != -1 ? themeProvider.primaryColor : Colors.white,
          ),
        ),
      ],
    );
  }

  void navigateToProblem(BuildContext context, int newProblemId,
      {required bool isNext}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProblemDetailScreenV2(
              problemId: newProblemId,
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PracticeCompletionScreen()),
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