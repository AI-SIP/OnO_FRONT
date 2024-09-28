import 'package:flutter/material.dart';
import 'package:ono/Model/ProblemModel.dart';

class SimpleTemplate extends StatefulWidget {
  final ProblemModel problemModel;

  const SimpleTemplate({required this.problemModel, Key? key}) : super(key: key);

  @override
  _SimpleTemplate createState() => _SimpleTemplate();
}

class _SimpleTemplate extends State<SimpleTemplate> {
  late ProblemModel problemModel;

  @override
  void initState() {
    super.initState();
    problemModel = widget.problemModel; // initState에서 problemModel 할당
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(problemModel.problemImageUrl!),
          ],
        ),
      ),
    );
  }
}