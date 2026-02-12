import 'dart:async';
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterScreen.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemAnalysisStatus.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Dialog/LoadingDialog.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
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
  Timer? _analysisPollingTimer;
  int _pollingCount = 0;
  bool _isExpansionTileExpanded = false; // ExpansionTile 상태 관리

  @override
  void initState() {
    super.initState();
    _setProblemModel();
  }

  @override
  void dispose() {
    _stopAnalysisPolling();
    super.dispose();
  }

  void _onExpansionChanged(bool expanded) {
    setState(() {
      _isExpansionTileExpanded = expanded;
    });
  }

  void _setProblemModel() {
    setState(() {
      _problemModelFuture = fetchProblemDetails(context, widget.problemId);
    });
  }

  void _startAnalysisPolling(int problemId) {
    // 기존 타이머가 있으면 취소
    _stopAnalysisPolling();
    _pollingCount = 0;

    log('🔄 Started analysis polling for problem $problemId');

    _pollAnalysisStatus(problemId);
  }

  void _pollAnalysisStatus(int problemId) {
    if (!mounted) return;

    _pollingCount++;

    // Smart Polling 간격 설정
    Duration nextInterval;
    if (_pollingCount <= 3) {
      // 처음 9초: 3초마다 (빠른 응답)
      nextInterval = const Duration(seconds: 3);
    } else if (_pollingCount <= 9) {
      // 9-45초: 5초마다
      nextInterval = const Duration(seconds: 5);
    } else if (_pollingCount <= 15) {
      // 45-105초: 10초마다
      nextInterval = const Duration(seconds: 10);
    } else {
      // 105초(1분 45초) 이상: 폴링 중지
      log('⏱️ Analysis polling timeout - stopped after ${_pollingCount} attempts');
      _stopAnalysisPolling();
      return;
    }

    _analysisPollingTimer = Timer(nextInterval, () async {
      if (!mounted) {
        _stopAnalysisPolling();
        return;
      }

      final problemsProvider = Provider.of<ProblemsProvider>(context, listen: false);

      try {
        log('🔍 Polling analysis status (attempt $_pollingCount)...');

        // 서버에서 최신 분석 상태 조회
        await problemsProvider.fetchProblemAnalysis(problemId);

        // 현재 문제 상태 확인
        final problem = await problemsProvider.getProblem(problemId);

        // 분석이 완료되거나 실패하면 폴링 중지
        if (problem.analysis?.status == ProblemAnalysisStatus.COMPLETED) {
          log('✅ Analysis completed - polling stopped');
          _stopAnalysisPolling();
          return;
        } else if (problem.analysis?.status == ProblemAnalysisStatus.FAILED) {
          log('❌ Analysis failed - polling stopped');
          _stopAnalysisPolling();
          return;
        }

        // 여전히 진행 중이면 다음 폴링 예약
        _pollAnalysisStatus(problemId);
      } catch (e) {
        log('⚠️ Error during analysis polling: $e');
        // 에러 발생해도 계속 시도
        _pollAnalysisStatus(problemId);
      }
    });
  }

  void _stopAnalysisPolling() {
    _analysisPollingTimer?.cancel();
    _analysisPollingTimer = null;
    _pollingCount = 0;
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
            child: Selector<ProblemsProvider, ProblemModel?>(
              selector: (context, provider) {
                try {
                  // 동기적으로 캐시된 문제 데이터만 반환
                  return provider.problems.firstWhere(
                    (p) => p.problemId == widget.problemId,
                  );
                } catch (e) {
                  return null;
                }
              },
              shouldRebuild: (previous, next) {
                // 문제 객체가 실제로 변경되었을 때만 rebuild
                if (previous == null && next == null) return false;
                if (previous == null || next == null) return true;

                // 분석 상태가 변경되었을 때만 rebuild
                return previous.analysis?.status != next.analysis?.status ||
                    previous.analysis?.subject != next.analysis?.subject ||
                    previous.analysis?.problemType != next.analysis?.problemType;
              },
              builder: (context, problemModel, child) {
                if (problemModel == null) {
                  // 초기 로딩 시에만 Future로 가져오기
                  return FutureBuilder<ProblemModel>(
                    future: Provider.of<ProblemsProvider>(context, listen: false)
                        .getProblem(widget.problemId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: StandardText(
                            text: '오답노트를 찾을 수 없습니다.',
                            color: themeProvider.primaryColor,
                          ),
                        );
                      } else if (snapshot.hasData) {
                        return _buildContent(snapshot.data!);
                      } else {
                        return Center(
                          child: StandardText(
                            text: '오답노트를 찾을 수 없습니다.',
                            color: themeProvider.primaryColor,
                          ),
                        );
                      }
                    },
                  );
                }

                // 이미 로드된 경우 바로 렌더링
                return _buildContent(problemModel);
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

    final openTime = DateTime.now();
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isDismissible: false,
      builder: (context) {
        return TapRegion(
          onTapOutside: (_) {
            // Workaround for iPadOS 26.1 bug: https://github.com/flutter/flutter/issues/177992
            if (DateTime.now().difference(openTime) < const Duration(milliseconds: 500)) {
              return;
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: SingleChildScrollView(
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
        ),
        );
      },
    );
  }

  Future<void> _showDeleteProblemDialog(
      int problemId, ThemeHandler themeProvider) async {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const StandardText(
              text: '오답노트 삭제', fontSize: 18, color: Colors.black),
          content: const StandardText(
              text: '정말로 이 오답노트를 삭제하시겠습니까?', fontSize: 16, color: Colors.black),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
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

                // context가 유효할 때 Provider와 Navigator 가져오기
                final problemsProvider =
                    Provider.of<ProblemsProvider>(context, listen: false);
                final practiceProvider = Provider.of<ProblemPracticeProvider>(
                    context,
                    listen: false);
                final navigator = Navigator.of(context);

                // 다이얼로그 닫기
                Navigator.pop(dialogContext);

                // 로딩 다이얼로그 표시
                LoadingDialog.show(context, '오답노트 지우는 중...');

                try {
                  // 삭제 작업 수행
                  await problemsProvider.deleteProblems([problemId]);
                  await practiceProvider.fetchAllPracticeContents();

                  // 로딩 다이얼로그 닫기
                  if (mounted) {
                    LoadingDialog.hide(context);
                  }

                  // 상세 화면 닫고 DirectoryScreen에 삭제 완료 알림 (true 반환)
                  if (mounted) {
                    navigator.pop(true);
                  }
                } catch (e) {
                  // 에러 발생 시 로딩 다이얼로그 닫기
                  if (mounted) {
                    LoadingDialog.hide(context);
                  }
                  log('문제 삭제 실패: $e');
                }
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
    return ProblemDetailTemplate(
      key: ValueKey(problemModel.problemId), // 같은 문제면 위젯 재사용
      problemModel: problemModel,
      isExpanded: _isExpansionTileExpanded,
      onExpansionChanged: _onExpansionChanged,
    );
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
    final problem = await problemsProvider.getProblem(problemId!);

    log('Moved to problem: ${problem.problemId}');

    // 문제에 ProblemImage가 있으면 분석 결과 조회
    if (problem.problemImageDataList != null &&
        problem.problemImageDataList!.isNotEmpty) {
      // 분석 결과가 없거나, PROCESSING/NOT_STARTED 상태면 서버에서 조회
      if (problem.analysis == null ||
          problem.analysis!.status == ProblemAnalysisStatus.PROCESSING ||
          problem.analysis!.status == ProblemAnalysisStatus.NOT_STARTED) {
        log('📊 Analysis is not completed - starting polling');

        // 분석 결과 조회 (await 하지 않고 백그라운드에서 실행)
        problemsProvider.fetchProblemAnalysis(problemId);

        // Smart Polling 시작
        _startAnalysisPolling(problemId);
      } else if (problem.analysis!.status == ProblemAnalysisStatus.COMPLETED) {
        log('✅ Analysis already completed - no polling needed');
        _stopAnalysisPolling();
      } else if (problem.analysis!.status == ProblemAnalysisStatus.NO_IMAGE) {
        log('📷 No image for analysis - polling not needed');
        _stopAnalysisPolling();
      }
    }

    return problem;
  }
}
