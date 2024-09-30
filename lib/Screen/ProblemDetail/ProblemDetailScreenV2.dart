import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/HandWriteText.dart';
import 'package:ono/GlobalModule/Theme/StandardText.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/ProblemModel.dart';
import '../../Model/TemplateType.dart';
import '../../Provider/FoldersProvider.dart';
import 'Template/CleanProblemDetailTemplate.dart';
import 'Template/SimpleProblemDetailTemplate.dart';
import 'Template/SpecialProblemDetailTemplate.dart';

class ProblemDetailScreenV2 extends StatefulWidget {
  final int problemId;

  const ProblemDetailScreenV2({required this.problemId, super.key});

  @override
  _ProblemDetailScreenV2State createState() => _ProblemDetailScreenV2State();
}

class _ProblemDetailScreenV2State extends State<ProblemDetailScreenV2> {
  ProblemModel? _problemModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProblemDetail();
  }

  Future<void> _fetchProblemDetail() async {
    final foldersProvider = Provider.of<FoldersProvider>(context, listen: false);
    final problemDetail = await foldersProvider.getProblemDetails(widget.problemId);

    setState(() {
      _problemModel = problemDetail;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: _buildAppBar(themeProvider),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  AppBar _buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      title: StandardText(
        text: (_problemModel?.reference == null || _problemModel!.reference!.isEmpty)
            ? "제목 없음"
            : _problemModel!.reference!,
        color: themeProvider.primaryColor,
        fontSize: 20,
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: themeProvider.primaryColor),
    );
  }

  Widget _buildContent() {
    if (_problemModel == null) {
      return Center(
        child: HandWriteText(
          text: '문제를 불러올 수 없습니다.',
          color: ThemeHandler().primaryColor,
        ),
      );
    }

    switch (_problemModel!.templateType) {
      case TemplateType.simple:
        return SimpleProblemDetailTemplate(problemModel: _problemModel!);
      case TemplateType.clean:
        return CleanProblemDetailTemplate(problemModel: _problemModel!);
      case TemplateType.special:
        return SpecialProblemDetailTemplate(problemModel: _problemModel!);
      default:
        return Center(
          child: HandWriteText(
            text: '알 수 없는 템플릿 유형입니다.',
            color: ThemeHandler().primaryColor,
          ),
        );
    }
  }
}