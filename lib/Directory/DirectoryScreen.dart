import 'package:flutter/material.dart';

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          '디렉토리 화면',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
