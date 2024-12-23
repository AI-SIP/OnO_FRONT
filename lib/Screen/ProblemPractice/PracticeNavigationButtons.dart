import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';
import 'package:ono/Screen/ProblemPractice/PracticeCompletionScreen.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Image/ImagePickerHandler.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Provider/ProblemPracticeProvider.dart';

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
  final ImagePickerHandler _imagePickerHandler = ImagePickerHandler();
  XFile? selectedImage;

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
            buildReviewButton(themeProvider, screenHeight),
            buildNextOrCompleteButton(themeProvider, screenHeight),
          ],
        ),
      ],
    );
  }

  TextButton buildPreviousButton(ThemeHandler themeProvider, double screenHeight) {
    final int currentIndex = getCurrentProblemIndex();
    final int previousProblemId = getPreviousProblemId(currentIndex);

    return TextButton(
      onPressed: currentIndex > 0
          ? () => navigateToProblem(previousProblemId, isNext: false)
          : null,
      style: _buildButtonStyle(themeProvider, screenHeight, isCompletion: false),
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

  TextButton buildReviewButton(ThemeHandler themeProvider, double screenHeight) {
    return TextButton(
      onPressed: isReviewed
          ? null
          : () => showReviewDialog(context),
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
            text: '복습 인증',
            fontSize: 14,
            color: themeProvider.primaryColor,
          ),
        ],
      ),
    );
  }

  TextButton buildNextOrCompleteButton(ThemeHandler themeProvider, double screenHeight) {
    final int currentIndex = getCurrentProblemIndex();
    final int nextProblemId = getNextProblemId(currentIndex);

    return TextButton(
      onPressed: nextProblemId != -1
          ? () => navigateToProblem(nextProblemId, isNext: true)
          : () => _showCompletionScreen(),
      style: _buildButtonStyle(themeProvider, screenHeight, isCompletion: nextProblemId == -1),
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
    return currentIndex > 0 ? currentProblems[currentIndex - 1].problemId : currentProblems.first.problemId;
  }

  int getNextProblemId(int currentIndex) {
    final currentProblems = widget.practiceProvider.currentProblems;
    return currentIndex < currentProblems.length - 1 ? currentProblems[currentIndex + 1].problemId : -1;
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
    final totalProblems = widget.practiceProvider.currentProblems.length;
    final practiceRound = widget.practiceProvider.practices
        .firstWhere((practice) => practice.practiceId == practiceId)
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

  void showReviewDialog(BuildContext context) {
    FirebaseAnalytics.instance.logEvent(name: 'problem_repeat_button_click');

    final folderProvider = Provider.of<FoldersProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              contentPadding: const EdgeInsets.all(15),
              titlePadding: const EdgeInsets.only(left: 20, top: 20, right: 20),
              title: const StandardText(
                text: '복습을 완료했나요?',
                fontSize: 18,
                color: Colors.black,
              ),
              content: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(15),
                child: GestureDetector(
                  onTap: () {
                    _imagePickerHandler.showImagePicker(context, (pickedFile) async {
                      if (pickedFile != null) {
                        setState(() {
                          selectedImage = pickedFile;
                        });
                      }
                    });
                  },
                  child: Container(
                    width: double.maxFinite,
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: selectedImage == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 60,
                          color: themeProvider.primaryColor,
                        ),
                        const SizedBox(height: 8),
                        StandardText(
                          text: '풀이 이미지를 등록하세요',
                          color: themeProvider.primaryColor,
                        ),
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(selectedImage!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const StandardText(
                    text: '취소',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    setState(() {
                      isLoading = true;
                    });

                    await folderProvider.addRepeatCount(
                        widget.currentProblemId, selectedImage);

                    await widget.practiceProvider.moveToPractice(widget.practiceProvider.currentPracticeId);

                    FirebaseAnalytics.instance.logEvent(
                      name: 'problem_repeat',
                    );

                    setState(() {
                      isReviewed = true;
                      isLoading = false;
                    });

                    Navigator.of(context).pop();
                    widget.onRefresh();
                  },
                  child: isLoading
                      ? CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: themeProvider.primaryColor,
                  )
                      : StandardText(
                    text: '복습 인증',
                    fontSize: 14,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  ButtonStyle _buildButtonStyle(ThemeHandler themeProvider, double screenHeight, {required bool isCompletion}) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      backgroundColor: isCompletion ? themeProvider.primaryColor : Colors.white,
      side: BorderSide(color: themeProvider.primaryColor, width: 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
    );
  }
}