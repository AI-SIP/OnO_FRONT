import 'package:flutter/material.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterTemplate.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';

class ProblemRegisterScreen extends StatelessWidget {
  final ProblemModel? problemModel;
  final bool isEditMode;

  const ProblemRegisterScreen({
    super.key,
    required this.problemModel,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeHandler>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: isEditMode ? '오답노트 수정' : '오답노트 작성',
          color: theme.primaryColor,
          fontSize: 20,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ProblemRegisterTemplate(
          problemModel: problemModel,
          isEditMode: isEditMode,
        ),
      ),
    );
  }
}
