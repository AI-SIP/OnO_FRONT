import 'package:flutter/material.dart';

class ProblemRegisterScreen extends StatelessWidget {
  const ProblemRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          '오답노트 등록 화면',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
