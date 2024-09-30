import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:provider/provider.dart';
import '../../Screen/ProblemDetail/ProblemDetailScreen.dart';
import '../Theme/HandWriteText.dart';
import '../Theme/ThemeHandler.dart';

class NavigationButtons extends StatelessWidget {
  final BuildContext context;
  final FoldersProvider provider;
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
      return const Center();
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
        TextButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(
                name: 'navigate_previous_problem',
              );
              navigateToProblem(context, provider, previousProblemId);
            },
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
              backgroundColor:
                  themeProvider.primaryColor.withOpacity(0.1), // 배경색을 은은하게 설정
              side: BorderSide(
                color: themeProvider.primaryColor,
                width: 2.0, // 테두리 두께
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0), // 둥글기 조정
              ),
            ),
            child: HandWriteText(
                text: '이전 문제',
                fontSize: 20,
                color: themeProvider.primaryColor)),
        TextButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(
                name: 'navigate_next_problem',
              );
              navigateToProblem(context, provider, nextProblemId);
            },
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
              backgroundColor:
                  themeProvider.primaryColor.withOpacity(0.1), // 배경색을 은은하게 설정
              side: BorderSide(
                color: themeProvider.primaryColor,
                width: 2.0, // 테두리 두께
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0), // 둥글기 조정
              ),
            ),
            child: HandWriteText(
                text: '다음 문제',
                fontSize: 20,
                color: themeProvider.primaryColor)),
      ],
    );
  }

  void navigateToProblem(
      BuildContext context, FoldersProvider provider, int newProblemId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => ProblemDetailScreen(problemId: newProblemId)),
    );
  }
}
