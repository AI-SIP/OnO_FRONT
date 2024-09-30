import 'package:flutter/material.dart';

import '../../../Model/ProblemModel.dart';

class SimpleProblemDetailTemplate extends StatelessWidget {
  final ProblemModel problemModel;

  const SimpleProblemDetailTemplate({required this.problemModel, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Simple Template: ${problemModel.problemId}'),
      ),
    );
  }
}