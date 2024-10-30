import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/StandardText.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreenV2.dart';
import 'package:ono/Screen/ProblemPractice/PracticeCompletionScreen.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/ThemeHandler.dart';

class PracticeNavigationScreen extends StatefulWidget {
  final List<int> problemIds;

  const PracticeNavigationScreen({super.key, required this.problemIds});

  @override
  _PracticeNavigationScreenState createState() => _PracticeNavigationScreenState();
}

class _PracticeNavigationScreenState extends State<PracticeNavigationScreen> {
  int currentIndex = 0;

  void navigateToNextProblem() {
    setState(() {
      if (currentIndex < widget.problemIds.length - 1) {
        currentIndex++;
      } else {
        // 마지막 문제 이후 완료 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PracticeCompletionScreen()),
        );
      }
    });
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
        centerTitle: true,
      ),
      body: ProblemDetailScreenV2(problemId: widget.problemIds[currentIndex]),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: navigateToNextProblem,
              child: const Text('다음 문제'),
            ),
          ],
        ),
      ),
    );
  }
}