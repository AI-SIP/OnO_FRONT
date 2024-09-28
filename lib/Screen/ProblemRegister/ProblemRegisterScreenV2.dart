import 'package:flutter/material.dart';

import '../../Model/TemplateType.dart';
import 'Template/CleanTemplate.dart';
import 'Template/SimpleTemplate.dart';
import 'Template/SpecialTemplate.dart';

class ProblemRegisterScreenV2 extends StatefulWidget {
  final int problemId;
  final String problemImageUrl;
  final TemplateType templateType;
  final List<Map<String, int>?>? colors;


  const ProblemRegisterScreenV2({
    Key? key,
    required this.problemId,
    required this.problemImageUrl,
    required this.templateType,
    required this.colors,
  }) : super(key: key);

  @override
  _ProblemRegisterScreenV2State createState() => _ProblemRegisterScreenV2State();
}

class _ProblemRegisterScreenV2State extends State<ProblemRegisterScreenV2> {
  String? processImageUrl;
  String? analysisResult;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget templateWidget;

    switch (widget.templateType) {
      case TemplateType.simple:
        templateWidget = SimpleTemplate(
          problemId: widget.problemId,
          problemImageUrl: widget.problemImageUrl,
        );
        break;
      case TemplateType.clean:
        templateWidget = CleanTemplate(
          problemId: widget.problemId,
          problemImageUrl: widget.problemImageUrl,
          colors: widget.colors,
        );
        break;
      case TemplateType.special:
        templateWidget = SpecialTemplate(
          problemId: widget.problemId,
          problemImageUrl: widget.problemImageUrl,
          colors: widget.colors,
        );
        break;
    }

    return Scaffold(
      body: templateWidget,
    );
  }
}