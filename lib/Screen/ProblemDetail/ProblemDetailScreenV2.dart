import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/HandWriteText.dart';
import 'package:ono/Model/ProblemRegisterModelV2.dart';
import 'package:ono/Provider/ProblemPracticeProvider.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/SnackBarDialog.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../GlobalModule/Util/FolderSelectionDialog.dart';
import '../../GlobalModule/Util/FolderNavigationButtons.dart';
import '../ProblemPractice/PracticeNavigationButtons.dart';
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
  final bool isPractice;

  const ProblemDetailScreenV2({
    required this.problemId,
    this.isPractice = false,
    super.key
  });

  @override
  _ProblemDetailScreenV2State createState() => _ProblemDetailScreenV2State();
}

class _ProblemDetailScreenV2State extends State<ProblemDetailScreenV2> {
  Future<ProblemModel?>? _problemModelFuture;
  final ProblemDetailScreenService _problemDetailService =
      ProblemDetailScreenService();

  @override
  void initState() {
    super.initState();

    _setProblemModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setProblemModel();
  }

  void _setProblemModel() {
    setState(() {
      if(widget.isPractice){
        _problemModelFuture = _problemDetailService.fetchProblemDetailsFromPractice(context, widget.problemId);
      } else{
        _problemModelFuture = _problemDetailService.fetchProblemDetailsFromFolder(context, widget.problemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: Colors.white,
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
                    child: StandardText(
                      text: '오답노트가 이동되었습니다!',
                      color: themeProvider.primaryColor,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildNavigationButtons(context, widget.isPractice),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeHandler themeProvider) {
    if(widget.isPractice){
      return AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: buildAppBarTitle(),
      );
    } else{
      return AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: buildAppBarTitle(),
        actions: _buildAppBarActions(),
      );
    }

  }

  Widget buildAppBarTitle(){
    final themeProvider = Provider.of<ThemeHandler>(context);

    return FutureBuilder<ProblemModel?>(
      future: _problemModelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const StandardText(text: '로딩 중...');
        } else if (snapshot.hasError) {
          return const StandardText(text: '에러 발생');
        } else if (snapshot.hasData && snapshot.data != null) {
          final reference = snapshot.data!.reference;
          return StandardText(
            text: (reference == null || reference.isEmpty) ? '제목 없음' : reference,
            fontSize: 20,
            color: themeProvider.primaryColor,
          );
        } else {
          return StandardText(
            text: '오답노트 상세',
            fontSize: 20,
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
            return IconButton(
              icon: Icon(Icons.more_vert, color: themeProvider.primaryColor),
              onPressed: () => _showActionDialog(snapshot.data!, themeProvider),
            );
          }
          return Container();
        },
      ),
    ];
  }

  void _showActionDialog(ProblemModel problemModel, ThemeHandler themeProvider) {

    FirebaseAnalytics.instance
        .logEvent(name: 'problem_detail_screen_action_dialog_button_click');

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0), // 패딩 추가
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), // 타이틀 아래 여백 추가
                  child: StandardText(
                    text: '오답노트 편집하기', // 타이틀 텍스트
                    fontSize: 20,
                    color: themeProvider.primaryColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.share, color: Colors.black),
                    title: const StandardText(
                      text: '오답노트 문제 공유하기',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onTap: () async {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'problem_share_button_click');
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProblemShareScreen(problem: problemModel),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.share, color: Colors.black),
                    title: const StandardText(
                      text: '오답노트 풀이 공유하기',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onTap: () async {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'answer_share_button_click');
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnswerShareScreen(problem: problemModel),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.edit, color: Colors.black),
                    title: const StandardText(
                      text: '오답노트 수정하기',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onTap: () {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'problem_edit_button_click');
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProblemRegisterScreenV2(
                            problemModel: problemModel,
                            isEditMode: true,
                            colorPickerResult: null,
                            coordinatePickerResult: null,
                          ),
                        ),
                      ).then((_) {
                        _setProblemModel();
                      });

                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.folder_open, color: Colors.black),
                    title: const StandardText(
                      text: '오답노트 위치 변경하기',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onTap: () async {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'problem_change_path_button_click');
                      Navigator.pop(context);

                      final foldersProvider = Provider.of<FoldersProvider>(context, listen: false);

                      final int? selectedFolderId = await showDialog<int?>(
                        context: context,
                        builder: (context) => const FolderSelectionDialog(),
                      );

                      if(selectedFolderId != null){
                        await foldersProvider.updateProblem(
                          ProblemRegisterModelV2(
                            problemId: problemModel.problemId,
                            folderId: selectedFolderId,
                          )
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const StandardText(
                      text: '현재 오답노트 삭제하기',
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    onTap: () {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'problem_delete_button_click');
                      Navigator.pop(context);
                      _showDeleteProblemDialog(problemModel.problemId, themeProvider);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteProblemDialog(int problemId, ThemeHandler themeProvider) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const StandardText(
              text: '오답노트 삭제', fontSize: 18, color: Colors.black),
          content: const StandardText(
              text: '정말로 이 오답노트를 삭제하시겠습니까?',
              fontSize: 16,
              color: Colors.black),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const StandardText(
                text: '취소',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                Navigator.pop(context);
                FirebaseAnalytics.instance.logEvent(name: 'problem_delete');

                bool isRemoved = await Provider.of<FoldersProvider>(context, listen: false).deleteProblem(problemId);
              },
              child: const StandardText(
                text: '삭제',
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ],
        );
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
  Widget _buildNavigationButtons(BuildContext context, bool isPractice) {
    // 기기의 높이 정보를 가져옴
    double screenHeight = MediaQuery.of(context).size.height;

    // 화면 높이에 따라 패딩 값을 동적으로 설정
    double topPadding = screenHeight * 0.01;
    double bottomPadding = screenHeight * 0.03;

    if(isPractice){
      return Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: PracticeNavigationButtons(
          context: context,
          practiceProvider: Provider.of<ProblemPracticeProvider>(context, listen: false),
          currentId: widget.problemId,
          onRefresh: _setProblemModel,
        ),
      );
    } else{
      return Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: FolderNavigationButtons(
          context: context,
          foldersProvider: Provider.of<FoldersProvider>(context, listen: false),
          currentId: widget.problemId,
          onRefresh: _setProblemModel,
        ),
      );
    }
  }
}