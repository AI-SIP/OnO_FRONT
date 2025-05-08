import 'package:flutter/material.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterTemplate.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Text/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Provider/FoldersProvider.dart';
import 'ProblemRegisterTemplateV2.dart';

class ProblemRegisterScreenV2 extends StatefulWidget {
  final ProblemModel? problemModel;
  final bool isEditMode;

  const ProblemRegisterScreenV2({
    super.key,
    required this.problemModel,
    required this.isEditMode,
  });

  @override
  _ProblemRegisterScreenStateV2 createState() =>
      _ProblemRegisterScreenStateV2();
}

class _ProblemRegisterScreenStateV2 extends State<ProblemRegisterScreenV2> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget templateWidget;
    final themeProvider = Provider.of<ThemeHandler>(context);

    templateWidget = ProblemRegisterTemplateV2(
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
