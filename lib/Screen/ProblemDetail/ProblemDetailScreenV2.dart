import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/HandWriteText.dart';
import 'package:ono/Screen/ProblemManagement/DirectoryScreen.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/SnackBarDialog.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Util/NavigationButtons.dart';
import '../../Model/ProblemModel.dart';
import '../../Model/TemplateType.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Service/ScreenUtil/ProblemDetailScreenService.dart';
import '../ProblemRegister/ProblemRegisterScreenV2.dart';
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: _buildAppBar(themeProvider),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<ProblemModel?>(
              future: _problemModelFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: themeProvider.primaryColor,),);
                } else if (snapshot.hasError) {
                  return Center(
                    child: HandWriteText(
                      text: '오답 노트를 불러오는 중 오류가 발생했습니다.',
                      color: themeProvider.primaryColor,
                    ),
                  );
                } else if (snapshot.hasData && snapshot.data != null) {
                  return _buildContent(snapshot.data!);
                } else {
                  return Center(
                    child: HandWriteText(
                      text: '오답노트를 불러올 수 없습니다.',
                      color: themeProvider.primaryColor,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10,),
          _buildNavigationButtons(context), // 항상 하단에 고정된 네비게이션 바
        ],
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
            fontSize: 26,
            color: themeProvider.primaryColor,
          );
        } else {
          return HandWriteText(
            text: '오답노트 상세',
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProblemRegisterScreenV2(
                          problemModel: problemModel,
                          isEditMode: true,
                          colors: null,
                        ),
                      ),
                    ).then((_) {
                      MaterialPageRoute(
                        builder: (context) => const DirectoryScreen(),
                      );
                    });
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
                  child: StandardText(
                    text: '오답노트 문제 공유하기',
                    fontSize: 14,
                    color: themeProvider.primaryColor,
                  ),
                ),
                PopupMenuItem<String>(
                  value: shareAnswerValue,
                  child: StandardText(
                    text: '오답노트 풀이 공유하기',
                    fontSize: 14,
                    color: themeProvider.primaryColor,
                  ),
                ),
                PopupMenuItem<String>(
                  value: editValue,
                  child: StandardText(
                    text: '오답노트 수정하기',
                    fontSize: 14,
                    color: themeProvider.primaryColor,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: deleteValue,
                  child: StandardText(
                    text: '오답노트 삭제하기',
                    fontSize: 14,
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
    _problemDetailService.deleteProblem(
      context,
      problemId,
          () {
        FirebaseAnalytics.instance.logEvent(name: 'problem_delete');
        Navigator.of(context).pop(true);
        if (mounted) {
          SnackBarDialog.showSnackBar(
            context: context,
            message: '오답노트가 삭제되었습니다!',
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

  // 네비게이션 버튼 구성 함수
  Widget _buildNavigationButtons(BuildContext context) {
    // 기기의 높이 정보를 가져옴
    double screenHeight = MediaQuery.of(context).size.height;

    // 화면 높이에 따라 패딩 값을 동적으로 설정
    double topPadding = screenHeight >= 1000 ? 25.0 : 15.0;
    double bottomPadding = screenHeight >= 1000 ? 30.0 : 25.0;
    double topBottomPadding = screenHeight >= 1000
        ? 25.0
        : 25.0; // 아이패드 13인치(높이 1024 이상) 기준으로 35, 그 외는 20

    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: NavigationButtons(
        context: context,
        foldersProvider: Provider.of<FoldersProvider>(context, listen: false),
        currentId: widget.problemId,
      ),
    );
  }
}