import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'ProblemRegisterTemplate.dart';

class ProblemRegisterScreen extends StatefulWidget {
  final ProblemModel? problemModel;
  final bool isEditMode;

  const ProblemRegisterScreen({
    super.key,
    required this.problemModel,
    required this.isEditMode,
  });

  @override
  _ProblemRegisterScreenState createState() => _ProblemRegisterScreenState();
}

class _ProblemRegisterScreenState extends State<ProblemRegisterScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget templateWidget;
    final themeProvider = Provider.of<ThemeHandler>(context);

    templateWidget = ProblemRegisterTemplate(
      problemModel: widget.problemModel,
      isEditMode: widget.isEditMode,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: widget.isEditMode ? '오답노트 수정' : '오답노트 작성',
          color: themeProvider.primaryColor,
          fontSize: 20,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
            20.0), // 기존 ProblemRegisterScreen과 동일한 padding 적용
        child: templateWidget,
      ),
    );
  }
}
