import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/HandWriteText.dart';
import 'package:ono/GlobalModule/Theme/StandardText.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/SnackBarDialog.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/ProblemModel.dart';
import '../../Model/TemplateType.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Service/ScreenUtil/ProblemDetailScreenService.dart';
import '../ProblemShare/AnswerShareScreen.dart';
import '../ProblemShare/ProblemShareScreen.dart';
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
  Future<ProblemModel?>? _problemModelFuture;
  final ProblemDetailScreenService _problemDetailService =
      ProblemDetailScreenService();

  static const String shareProblemValue = 'share_problem';
  static const String shareAnswerValue = 'share_answer';
  static const String editValue = 'edit';
  static const String deleteValue = 'delete';

  @override
  void initState() {
    super.initState();
    _problemModelFuture = _problemDetailService.fetchProblemDetails(context, widget.problemId);
  }

  Future<ProblemModel?> _fetchProblemDetail() async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    return await foldersProvider.getProblemDetails(widget.problemId);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: _buildAppBar(themeProvider),
      body: FutureBuilder<ProblemModel?>(
        future: _problemModelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: HandWriteText(
                text: '문제를 불러오는 중 오류가 발생했습니다.',
                color: themeProvider.primaryColor,
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            return _buildContent(snapshot.data!);
          } else {
            return Center(
              child: HandWriteText(
                text: '문제를 불러올 수 없습니다.',
                color: themeProvider.primaryColor,
              ),
            );
          }
        },
      ),
    );
  }

  AppBar _buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      title: buildAppBarTitle(),
      actions: _buildAppBarActions(),
    );
  }

  Widget buildAppBarTitle(){
    final themeProvider = Provider.of<ThemeHandler>(context);

    return FutureBuilder<ProblemModel?>(
      future: _problemModelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const HandWriteText(text: '로딩 중...');
        } else if (snapshot.hasError) {
          return const HandWriteText(text: '에러 발생');
        } else if (snapshot.hasData && snapshot.data != null) {
          final reference = snapshot.data!.reference;
          return HandWriteText(
            text: (reference == null || reference.isEmpty) ? '제목 없음' : reference,
            fontSize: 24,
            color: themeProvider.primaryColor,
          );
        } else {
          return HandWriteText(
            text: '문제 상세',
            fontSize: 24,
            color: themeProvider.primaryColor,
          );
        }
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return [
      FutureBuilder<ProblemModel?>(
        future: _problemModelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return PopupMenuButton<String>(
              onSelected: (String result) async {
                log('Popup menu selected: $result');
                final problemModel = snapshot.data;
                if (problemModel != null) {
                  if (result == shareProblemValue) {
                    FirebaseAnalytics.instance
                        .logEvent(name: 'problem_share_button_click');
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProblemShareScreen(problem: problemModel),
                      ),
                    );
                  } else if (result == shareAnswerValue) {
                    FirebaseAnalytics.instance
                        .logEvent(name: 'answer_share_button_click');
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AnswerShareScreen(problem: problemModel),
                      ),
                    );
                  } else if (result == editValue) {
                    FirebaseAnalytics.instance
                        .logEvent(name: 'problem_edit_button_click');

                  } else if (result == deleteValue) {
                    FirebaseAnalytics.instance
                        .logEvent(name: 'problem_delete_button_click');
                    _deleteProblemDialog(context, problemModel.problemId, themeProvider);
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: shareProblemValue,
                  child: HandWriteText(
                    text: '문제 공유하기',
                    fontSize: 18,
                    color: themeProvider.primaryColor,
                  ),
                ),
                PopupMenuItem<String>(
                  value: shareAnswerValue,
                  child: HandWriteText(
                    text: '정답 공유하기',
                    fontSize: 18,
                    color: themeProvider.primaryColor,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: editValue,
                  child: HandWriteText(
                    text: '문제 수정하기',
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: deleteValue,
                  child: HandWriteText(
                    text: '문제 삭제하기',
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              ],
            );
          }
          return Container();
        },
      ),
    ];
  }

  void _deleteProblemDialog(BuildContext context, int problemId, ThemeHandler themeProvider) {
    log('problemId : ${problemId}');
    log('problemId2 : ${problemId}');
    _problemDetailService.deleteProblem(
      context,
      problemId,
          () {
        FirebaseAnalytics.instance.logEvent(name: 'problem_delete');
        Navigator.of(context).pop(true);
        if (mounted) {
          SnackBarDialog.showSnackBar(
            context: context,
            message: '문제가 삭제되었습니다!',
            backgroundColor: themeProvider.primaryColor,
          );
        }
      },
          (errorMessage) {
        if (mounted) {
          SnackBarDialog.showSnackBar(
            context: context,
            message: errorMessage,
            backgroundColor: Colors.red,
          );
        }
      },
    );
  }

  Widget _buildContent(ProblemModel problemModel) {
    switch (problemModel.templateType) {
      case TemplateType.simple:
        return SimpleProblemDetailTemplate(problemModel: problemModel);
      case TemplateType.clean:
        return CleanProblemDetailTemplate(problemModel: problemModel);
      case TemplateType.special:
        return SpecialProblemDetailTemplate(problemModel: problemModel);
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
