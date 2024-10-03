import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreenV2.dart';
import 'package:provider/provider.dart';
import '../Theme/HandWriteText.dart';
import '../Theme/ThemeHandler.dart';

class NavigationButtons extends StatefulWidget {
  final BuildContext context;
  final FoldersProvider foldersProvider;
  final int currentId;

  const NavigationButtons({
    super.key,
    required this.context,
    required this.foldersProvider,
    required this.currentId,
  });

  @override
  _NavigationButtonsState createState() => _NavigationButtonsState();
}

class _NavigationButtonsState extends State<NavigationButtons> {
  bool isReviewed = false; // 복습 완료 상태를 저장하는 변수

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final problemIds = widget.foldersProvider.getProblemIds();

    if (problemIds.isEmpty) {
      return const Center();
    }

    int currentIndex = problemIds.indexOf(widget.currentId);
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
            navigateToProblem(context, previousProblemId);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: HandWriteText(
              text: '< 이전 문제',
              fontSize: 16,
              color: themeProvider.primaryColor),
        ),

        // 복습 완료 버튼
        TextButton(
          onPressed: () async {
            if (!isReviewed) {
              await widget.foldersProvider.addRepeatCount(widget.currentId);
              setState(() {
                isReviewed = true; // 복습 완료 상태로 변경
              });
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: isReviewed
              ? Icon(Icons.check, color: themeProvider.primaryColor, size: 24) // 체크 표시
              : HandWriteText(
            text: '복습 완료',
            fontSize: 20,
            color: themeProvider.primaryColor,
          ),
        ),

        TextButton(
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'navigate_next_problem',
            );
            navigateToProblem(context, nextProblemId);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: HandWriteText(
              text: '다음 문제 >',
              fontSize: 16,
              color: themeProvider.primaryColor),
        ),
      ],
    );
  }

  void navigateToProblem(BuildContext context, int newProblemId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => ProblemDetailScreenV2(problemId: newProblemId)),
    );
  }

  void repeatComplete() async{
    Provider.of<FoldersProvider>(context, listen: false)
        .addRepeatCount(widget.currentId);
  }
}
