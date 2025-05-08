import 'package:flutter/material.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterTemplate.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Text/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Provider/FoldersProvider.dart';

class ProblemRegisterScreen extends StatefulWidget {
  final ProblemModel problemModel;
  final bool isEditMode;
  final Map<String, dynamic>? colorPickerResult;
  final List<List<double>>? coordinatePickerResult;

  const ProblemRegisterScreen({
    super.key,
    required this.problemModel,
    required this.isEditMode,
    required this.colorPickerResult,
    required this.coordinatePickerResult,
  });

  @override
  _ProblemRegisterScreenState createState() =>
      _ProblemRegisterScreenState();
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
        colorPickerResult: widget.colorPickerResult,
        coordinatePickerResult: widget.coordinatePickerResult,
        isEditMode: widget.isEditMode,
        templateType: widget.problemModel.templateType!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.primaryColor),
          onPressed: () {
            if (!widget.isEditMode) {
              _deleteProblem();
            }
            Navigator.pop(context);
          },
        ),
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

  Future<void> _deleteProblem() async {
    await Provider.of<FoldersProvider>(context, listen: false)
        .deleteProblems([widget.problemModel.problemId]);
  }
}
