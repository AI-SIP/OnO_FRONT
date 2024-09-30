import 'package:flutter/material.dart';

import '../../../Model/ProblemModel.dart';

class SpecialProblemDetailTemplate extends StatelessWidget {
  final ProblemModel problemModel;

  const SpecialProblemDetailTemplate({required this.problemModel, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Special Template: ${problemModel.problemId}'),
      ),
    );
  }
}