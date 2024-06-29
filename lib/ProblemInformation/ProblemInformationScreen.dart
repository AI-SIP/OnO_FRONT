import 'package:flutter/material.dart';

class ProblemInformationScreen extends StatelessWidget {
  const ProblemInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          '오답노트 복습 화면',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
