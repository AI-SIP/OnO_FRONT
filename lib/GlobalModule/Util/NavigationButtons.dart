import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Screen/ProblemDetailScreen.dart';
import '../Theme/DecorateText.dart';
import '../Theme/ThemeHandler.dart';

class NavigationButtons extends StatelessWidget {
  final BuildContext context;
  final ProblemsProvider provider;
  final int currentId;

  const NavigationButtons({
    super.key,
    required this.context,
    required this.provider,
    required this.currentId,
  });

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeHandler>(context);
    final problemIds = provider.getProblemIds();

    if (problemIds.isEmpty) {
      return Center(
          child: DecorateText(text: '문제가 없습니다.', fontSize: 20, color: themeProvider.primaryColor)
      );
    }

    int currentIndex = problemIds.indexOf(currentId);
    int previousProblemId =
        currentIndex > 0 ? problemIds[currentIndex - 1] : problemIds.last;
    int nextProblemId = currentIndex < problemIds.length - 1
        ? problemIds[currentIndex + 1]
        : problemIds.first;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () =>
              navigateToProblem(context, provider, previousProblemId),
            child: DecorateText(text: '이전 문제', fontSize: 20, color: themeProvider.primaryColor)
        ),
        ElevatedButton(
          onPressed: () => navigateToProblem(context, provider, nextProblemId),
            child: DecorateText(text: '다음 문제', fontSize: 20, color: themeProvider.primaryColor)
        ),
      ],
    );
  }

  void navigateToProblem(
      BuildContext context, ProblemsProvider provider, int newProblemId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => ProblemDetailScreen(problemId: newProblemId)),
    );
  }
}
