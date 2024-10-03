import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/StandardText.dart';
import 'package:ono/Model/ProblemModel.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/HandWriteText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/TemplateType.dart';
import '../../Provider/FoldersProvider.dart';
import 'Template/CleanProblemRegisterTemplate.dart';
import 'Template/SimpleProblemRegisterTemplate.dart';
import 'Template/SpecialProblemRegisterTemplate.dart';

class ProblemRegisterScreenV2 extends StatefulWidget {
  final ProblemModel problemModel;
  final bool isEditMode;
  final List<Map<String, int>?>? colors;


  const ProblemRegisterScreenV2({
    super.key,
    required this.problemModel,
    required this.isEditMode,
    required this.colors,
  });

  @override
  _ProblemRegisterScreenV2State createState() => _ProblemRegisterScreenV2State();
}

class _ProblemRegisterScreenV2State extends State<ProblemRegisterScreenV2> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget templateWidget;
    final themeProvider = Provider.of<ThemeHandler>(context);

    switch (widget.problemModel.templateType!) {
      case TemplateType.simple:
        templateWidget = SimpleProblemRegisterTemplate(
            problemModel: widget.problemModel,
        );
        break;
      case TemplateType.clean:
        templateWidget = CleanProblemRegisterTemplate(
          problemModel: widget.problemModel,
          colors: widget.colors,
        );
        break;
      case TemplateType.special:
        templateWidget = SpecialProblemRegisterTemplate(
          problemModel: widget.problemModel,
          colors: widget.colors,
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.primaryColor),
          onPressed: () {
            if (!widget.isEditMode) {
              _deleteProblem();
            }
            Navigator.pop(context);
          },
        ),
        title: HandWriteText(
          text: widget.isEditMode ? '오답노트 수정' : '오답노트 등록',
          color: themeProvider.primaryColor,
          fontSize: 24,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // 기존 ProblemRegisterScreen과 동일한 padding 적용
        child: templateWidget,
      ),
    );
  }

  Future<void> _deleteProblem() async {
    await Provider.of<FoldersProvider>(context, listen: false)
        .deleteProblem(widget.problemModel.problemId);
  }
}