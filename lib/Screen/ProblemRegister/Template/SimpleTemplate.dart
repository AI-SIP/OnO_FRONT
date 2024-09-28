import 'package:flutter/material.dart';

class SimpleTemplate extends StatelessWidget {
  final int problemId;
  final String problemImageUrl;

  const SimpleTemplate({required this.problemId, required this.problemImageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple Template 등록')),
      body: SingleChildScrollView( // Enabling scrolling
        child: Column(
          children: [
            Image.network(problemImageUrl),
          ],
        ),
      ),
    );
  }
}