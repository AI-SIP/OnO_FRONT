// ReviewCompletionScreen.dart

import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/StandardText.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/ThemeHandler.dart';

class PracticeCompletionScreen extends StatelessWidget {
  const PracticeCompletionScreen({super.key});

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