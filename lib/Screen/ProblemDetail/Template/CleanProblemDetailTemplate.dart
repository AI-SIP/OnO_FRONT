import 'package:flutter/material.dart';

import '../../../Model/ProblemModel.dart';

class CleanProblemDetailTemplate extends StatelessWidget {
  final ProblemModel problemModel;

  const CleanProblemDetailTemplate({required this.problemModel, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Clean Template: ${problemModel.problemId}'),
      ),
    );
  }
}