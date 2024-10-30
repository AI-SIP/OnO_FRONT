import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/GlobalModule/Theme/LoadingDialog.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemPracticeProvider.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreenV2.dart';
import 'package:provider/provider.dart';
import '../Image/ImagePickerHandler.dart';
import '../Theme/SnackBarDialog.dart';
import '../Theme/StandardText.dart';
import '../Theme/ThemeHandler.dart';

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
  _PracticeNavigationButtonsState createState() => _PracticeNavigationButtonsState();
}

class _PracticeNavigationButtonsState extends State<PracticeNavigationButtons> {
  bool isReviewed = false;
  XFile? selectedImage;

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
            navigateToProblem(context, previousProblemId, isNext: false);
          },
          style: ElevatedButton.styleFrom(
            padding:
            EdgeInsets.symmetric(horizontal: screenHeight * 0.02, vertical: screenHeight * 0.008),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: StandardText(
              text: '< 이전 문제', fontSize: screenHeight * 0.012, color: themeProvider.primaryColor),
        ),

        TextButton(
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'navigate_next_problem',
            );
            navigateToProblem(context, nextProblemId, isNext: true);
          },
          style: ElevatedButton.styleFrom(
            padding:
            EdgeInsets.symmetric(horizontal: screenHeight * 0.02, vertical: screenHeight * 0.008),
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: StandardText(
              text: '다음 문제 >', fontSize: screenHeight * 0.012, color: themeProvider.primaryColor),
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
            ProblemDetailScreenV2(problemId: newProblemId, isPractice: true,),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 다음 문제인지 이전 문제인지에 따라 시작 위치와 애니메이션 설정
          final Offset begin =
          !isNext ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          // 회전 애니메이션 설정
          return SlideTransition(
            position: offsetAnimation,
            child: RotationTransition(
              alignment: Alignment.bottomRight, // 오른쪽 아래를 기준으로 회전
              turns: Tween(begin: !isNext ? -0.1 : 0.1, end: 0.0)
                  .animate(animation), // 시계 방향으로 회전
              child: child,
            ),
          );
        },
      ),
    );
  }
}
