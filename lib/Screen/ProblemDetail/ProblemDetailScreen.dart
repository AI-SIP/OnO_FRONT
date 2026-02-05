import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterScreen.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemAnalysisStatus.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ProblemsProvider.dart';
import '../PracticeNote/PracticeNavigationButtons.dart';
import 'ProblemDetailTemplate.dart';

class ProblemDetailScreen extends StatefulWidget {
  final int problemId;
  final bool isPractice;

  const ProblemDetailScreen(
      {required this.problemId, this.isPractice = false, super.key});

  @override
  _ProblemDetailScreenState createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  Future<ProblemModel?>? _problemModelFuture;

  @override
  void initState() {
    super.initState();
    _setProblemModel();
  }

  void _setProblemModel() {
    setState(() {
      _problemModelFuture = fetchProblemDetails(context, widget.problemId);
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
            child: Consumer<ProblemsProvider>(
              builder: (context, problemsProvider, child) {
                try {
                  final problem = problemsProvider.getProblem(widget.problemId);
                  return _buildContent(problem);
                } catch (e) {
                  return Center(
                    child: StandardText(
                      text: '오답노트를 찾을 수 없습니다.',
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
    if (widget.isPractice) {
      return AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: buildAppBarTitle(),
      );
    } else {
      return AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: buildAppBarTitle(),
        actions: _buildAppBarActions(),
      );
    }
  }

  Widget buildAppBarTitle() {
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
            text:
                (reference == null || reference.isEmpty) ? '제목 없음' : reference,
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

  void _showActionDialog(
      ProblemModel problemModel, ThemeHandler themeProvider) {
    FirebaseAnalytics.instance
        .logEvent(name: 'problem_detail_screen_action_dialog_button_click');

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 20.0, horizontal: 10.0), // 패딩 추가
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
                /*
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
                          builder: (context) =>
                              ProblemShareScreen(problem: problemModel),
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
                      text: '오답노트 해설 공유하기',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onTap: () async {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'answer_share_button_click');
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AnswerShareScreen(problem: problemModel),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),

                 */
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
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (context) => ProblemRegisterScreen(
                            problemModel: problemModel,
                            isEditMode: true,
                          ),
                        ),
                      )
                          .then((_) {
                        _setProblemModel();
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const StandardText(
                      text: '현재 오답노트 삭제하기',
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    onTap: () {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'problem_delete_button_click');
                      Navigator.pop(context);
                      _showDeleteProblemDialog(
                          problemModel.problemId, themeProvider);
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

  Future<void> _showDeleteProblemDialog(
      int problemId, ThemeHandler themeProvider) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const StandardText(
              text: '오답노트 삭제', fontSize: 18, color: Colors.black),
          content: const StandardText(
              text: '정말로 이 오답노트를 삭제하시겠습니까?', fontSize: 16, color: Colors.black),
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
                FirebaseAnalytics.instance.logEvent(name: 'problem_delete');

                // context가 유효할 때 Provider 가져오기
                ProblemsProvider problemsProvider =
                    Provider.of<ProblemsProvider>(context, listen: false);
                FoldersProvider foldersProvider =
                    Provider.of<FoldersProvider>(context, listen: false);
                ProblemPracticeProvider practiceProvider =
                    Provider.of<ProblemPracticeProvider>(context,
                        listen: false);

                ProblemModel problemModel =
                    problemsProvider.getProblem(problemId);

                int? parentFolderId = problemModel.folderId;

                // 다이얼로그 닫기
                Navigator.pop(context);
                // 상세 화면 닫기 (폴더 화면으로 이동)
                Navigator.pop(context);

                // 삭제 작업 수행
                await problemsProvider.deleteProblems([problemId]);

                // 폴더 및 복습 노트 갱신
                if (parentFolderId != null) {
                  await foldersProvider.refreshFolder(parentFolderId);
                }
                await practiceProvider.fetchAllPracticeContents();
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
    return ProblemDetailTemplate(problemModel: problemModel);
  }

  // 네비게이션 버튼 구성 함수
  Widget _buildNavigationButtons(BuildContext context, bool isPractice) {
    // 기기의 높이 정보를 가져옴
    double screenHeight = MediaQuery.of(context).size.height;

    // 화면 높이에 따라 패딩 값을 동적으로 설정
    double topPadding = screenHeight * 0.01;
    double bottomPadding = screenHeight * 0.03;

    if (isPractice) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: PracticeNavigationButtons(
          context: context,
          practiceProvider:
              Provider.of<ProblemPracticeProvider>(context, listen: false),
          currentProblemId: widget.problemId,
          onRefresh: _setProblemModel,
        ),
      );
    } else {
      /*
      return Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: FolderNavigationButtons(
          context: context,
          foldersProvider: Provider.of<FoldersProvider>(context, listen: false),
          currentId: widget.problemId,
          onRefresh: _setProblemModel,
        ),
      );
       */

      return const Padding(
        padding: EdgeInsets.only(top: 0, bottom: 0),
      );
    }
  }

  Future<ProblemModel?> fetchProblemDetails(
      BuildContext context, int? problemId) async {
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final problem = problemsProvider.getProblem(problemId!);

    log('Moved to problem: ${problem.problemId}');

    // 문제에 ProblemImage가 있으면 분석 결과 조회
    if (problem.problemImageDataList != null &&
        problem.problemImageDataList!.isNotEmpty) {
      // 분석 결과가 없거나, PROCESSING/NOT_STARTED 상태면 서버에서 조회
      if (problem.analysis == null ||
          problem.analysis!.status == ProblemAnalysisStatus.PROCESSING ||
          problem.analysis!.status == ProblemAnalysisStatus.NOT_STARTED) {
        log('fetch analysis result');

        // 분석 결과 조회 후 COMPLETED면 업데이트됨
        problemsProvider.fetchProblemAnalysis(problemId);
      }
    }

    return problem;
  }
}
