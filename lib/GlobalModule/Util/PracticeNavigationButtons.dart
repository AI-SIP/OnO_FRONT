import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/LoadingDialog.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreenV2.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/SnackBarDialog.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';

class PracticeNavigationScreen extends StatefulWidget {
  final List<int> problemIds; // 복습할 문제 ID 목록
  final int initialIndex;

  const PracticeNavigationScreen({
    super.key,
    required this.problemIds,
    this.initialIndex = 0,
  });

  @override
  _PracticeNavigationScreenState createState() => _PracticeNavigationScreenState();
}

class _PracticeNavigationScreenState extends State<PracticeNavigationScreen> {
  int currentIndex = 0;
  bool isReviewed = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void navigateToNextProblem() {
    setState(() {
      if (currentIndex < widget.problemIds.length - 1) {
        currentIndex++;
        isReviewed = false; // 다음 문제로 이동하면 초기화
      } else {
        _showCompletionScreen(); // 마지막 문제일 때 완료 화면으로 이동
      }
    });
  }

  void navigateToPreviousProblem() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        isReviewed = false; // 이전 문제로 이동 시 초기화
      });
    }
  }

  /*
  void markAsReviewed() async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final foldersProvider = Provider.of<FoldersProvider>(context, listen: false);

    LoadingDialog.show(context, '복습 중...');
    await foldersProvider.addRepeatCount(widget.problemIds[currentIndex]);
    setState(() {
      isReviewed = true;
    });

    LoadingDialog.hide(context);
    SnackBarDialog.showSnackBar(
      context: context,
      message: '복습이 완료되었습니다!',
      backgroundColor: themeProvider.primaryColor,
    );
  }

   */

  void _showCompletionScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ReviewCompletionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: AppBar(
        title: StandardText(
          text: '문제 복습 (${currentIndex + 1}/${widget.problemIds.length})',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ProblemDetailScreenV2(problemId: widget.problemIds[currentIndex]),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: navigateToPreviousProblem,
              style: _buildButtonStyle(themeProvider),
              child: const StandardText(text: '< 이전 문제'),
            ),
            /*
            TextButton(
              onPressed: isReviewed ? null : markAsReviewed,
              style: _buildButtonStyle(themeProvider),
              child: isReviewed
                  ? const Icon(Icons.check, color: Colors.green)
                  : const StandardText(text: '복습 완료'),
            ),

             */
            TextButton(
              onPressed: navigateToNextProblem,
              style: _buildButtonStyle(themeProvider),
              child: const StandardText(text: '다음 문제 >'),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buildButtonStyle(ThemeHandler themeProvider) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
      side: BorderSide(color: themeProvider.primaryColor, width: 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
    );
  }
}

class ReviewCompletionScreen extends StatelessWidget {
  const ReviewCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('복습 완료'),
        backgroundColor: themeProvider.primaryColor,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.done, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            StandardText(
              text: '모든 복습을 완료하였습니다!',
              fontSize: 20,
              color: themeProvider.primaryColor,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}