import 'dart:async';
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:ono/Module/Dialog/SnackBarDialog.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterScreen.dart';
import 'package:ono/Util/AppErrorReporter.dart';
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
  int _analysisPollingFailureCount = 0;
  static const int _maxAnalysisPollingFailures = 3;
  bool _isExpansionTileExpanded = false; // ExpansionTile 상태 관리
  bool _isProblemDeleted = false; // 문제 삭제 여부 플래그

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
    _analysisPollingFailureCount = 0;

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

      final problemsProvider =
          Provider.of<ProblemsProvider>(context, listen: false);

      try {
        log('🔍 Polling analysis status (attempt $_pollingCount)...');

        // 서버에서 최신 분석 상태 조회
        await problemsProvider.fetchProblemAnalysis(problemId);
        _analysisPollingFailureCount = 0;

        // 현재 문제 상태 확인
        final problem = await problemsProvider.getProblem(problemId);

        // 분석이 완료되거나 실패하거나 이미지가 없으면 폴링 중지
        if (problem.analysis?.status == ProblemAnalysisStatus.COMPLETED) {
          log('✅ Analysis completed - polling stopped');
          _stopAnalysisPolling();
          // UI 강제 업데이트
          if (mounted) {
            setState(() {
              _problemModelFuture = Future.value(problem);
            });
          }
          return;
        } else if (problem.analysis?.status == ProblemAnalysisStatus.FAILED) {
          log('❌ Analysis failed - polling stopped');
          _stopAnalysisPolling();
          // UI 강제 업데이트
          if (mounted) {
            setState(() {
              _problemModelFuture = Future.value(problem);
            });
          }
          return;
        } else if (problem.analysis?.status == ProblemAnalysisStatus.NO_IMAGE) {
          log('📷 No image detected during polling - polling stopped');
          _stopAnalysisPolling();
          // UI 강제 업데이트 (중요: NO_IMAGE 상태를 화면에 반영)
          if (mounted) {
            setState(() {
              _problemModelFuture = Future.value(problem);
            });
          }
          return;
        }

        // 여전히 진행 중이면 다음 폴링 예약
        _pollAnalysisStatus(problemId);
      } catch (e, stackTrace) {
        _analysisPollingFailureCount++;
        log('⚠️ Error during analysis polling: $e');
        await AppErrorReporter.report(
          e,
          stackTrace,
          source: 'problem_analysis_polling',
          severity: AppErrorSeverity.warning,
          sendToDiscord:
              _analysisPollingFailureCount >= _maxAnalysisPollingFailures,
        );
        if (_analysisPollingFailureCount >= _maxAnalysisPollingFailures) {
          log('⏱️ Analysis polling stopped after repeated failures');
          _stopAnalysisPolling();
          return;
        }

        _pollAnalysisStatus(problemId);
      }
    });
  }

  void _stopAnalysisPolling() {
    _analysisPollingTimer?.cancel();
    _analysisPollingTimer = null;
    _pollingCount = 0;
    _analysisPollingFailureCount = 0;
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
                    previous.analysis?.problemType !=
                        next.analysis?.problemType;
              },
              builder: (context, problemModel, child) {
                if (_isProblemDeleted) {
                  return Expanded(
                      child:
                          Container()); // Problem has been deleted, so show nothing or a message
                }
                if (problemModel == null) {
                  // 초기 로딩 시에만 Future로 가져오기
                  return FutureBuilder<ProblemModel>(
                    future:
                        Provider.of<ProblemsProvider>(context, listen: false)
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
          const SizedBox(height: 0),
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
            fontSize: 18,
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
      backgroundColor: Colors.transparent,
      context: context,
      isDismissible: false,
      builder: (context) {
        return TapRegion(
          onTapOutside: (_) {
            // Workaround for iPadOS 26.1 bug: https://github.com/flutter/flutter/issues/177992
            if (DateTime.now().difference(openTime) <
                const Duration(milliseconds: 500)) {
              return;
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 핸들바
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // 타이틀
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit_note,
                            color: themeProvider.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const StandardText(
                          text: '오답노트 편집하기',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 메뉴 아이템들
                    _buildActionItem(
                      icon: Icons.edit,
                      iconColor: themeProvider.primaryColor,
                      title: '오답노트 수정하기',
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
                    const SizedBox(height: 12),
                    _buildActionItem(
                      icon: Icons.playlist_add,
                      iconColor: themeProvider.primaryColor,
                      title: '복습 세트에 추가하기',
                      onTap: () {
                        FirebaseAnalytics.instance.logEvent(
                            name: 'problem_add_to_practice_set_button_click');
                        Navigator.pop(context);
                        _showPracticeSetSelectionSheet(
                            problemModel, themeProvider);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionItem(
                      icon: Icons.delete,
                      iconColor: Colors.red,
                      title: '현재 오답노트 삭제하기',
                      titleColor: Colors.red,
                      onTap: () {
                        FirebaseAnalytics.instance
                            .logEvent(name: 'problem_delete_button_click');
                        Navigator.pop(context);
                        _showDeleteProblemDialog(
                            problemModel.problemId, themeProvider);
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StandardText(
                text: title,
                fontSize: 16,
                color: titleColor ?? Colors.black87,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPracticeSetSelectionSheet(
      ProblemModel problemModel, ThemeHandler themeProvider) async {
    final practiceProvider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);

    LoadingDialog.show(context, '복습 세트 목록 불러오는 중...');

    try {
      await practiceProvider.fetchAllPracticeContents();
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      SnackBarDialog.showSnackBar(
        context: context,
        message: '복습 세트 목록을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (!mounted) return;
    LoadingDialog.hide(context);

    final selectedPracticeIds = <int>{};
    final openTime = DateTime.now();

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final practices = practiceProvider.practices;

            return TapRegion(
              onTapOutside: (_) {
                if (DateTime.now().difference(openTime) <
                    const Duration(milliseconds: 500)) {
                  return;
                }
                if (Navigator.canPop(sheetContext)) {
                  Navigator.pop(sheetContext);
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: themeProvider.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.playlist_add,
                              color: themeProvider.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: StandardText(
                              text: '복습 세트에 추가하기',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (practices.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.playlist_add_check,
                                size: 44,
                                color: Colors.grey[350],
                              ),
                              const SizedBox(height: 12),
                              const StandardText(
                                text: '아직 복습 세트가 없습니다.',
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: practices.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final practice = practices[index];
                              final alreadyAdded = practice.problemIdList
                                  .contains(problemModel.problemId);
                              final selected = selectedPracticeIds
                                  .contains(practice.practiceId);

                              return InkWell(
                                onTap: alreadyAdded
                                    ? null
                                    : () {
                                        setSheetState(() {
                                          if (selected) {
                                            selectedPracticeIds
                                                .remove(practice.practiceId);
                                          } else {
                                            selectedPracticeIds
                                                .add(practice.practiceId);
                                          }
                                        });
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: alreadyAdded
                                        ? Colors.grey[100]
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? themeProvider.primaryColor
                                          : Colors.grey[200]!,
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        alreadyAdded
                                            ? Icons.check_circle
                                            : selected
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                        color: alreadyAdded
                                            ? Colors.grey
                                            : selected
                                                ? themeProvider.primaryColor
                                                : Colors.grey[400],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            StandardText(
                                              text: practice.practiceTitle,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: alreadyAdded
                                                  ? Colors.grey
                                                  : Colors.black87,
                                            ),
                                            const SizedBox(height: 4),
                                            StandardText(
                                              text: alreadyAdded
                                                  ? '이미 추가된 문제입니다'
                                                  : '문제 ${practice.practiceSize}개',
                                              fontSize: 13,
                                              color: Colors.grey[600]!,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const StandardText(
                                text: '취소',
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextButton(
                              onPressed: selectedPracticeIds.isEmpty
                                  ? null
                                  : () {
                                      final targetPracticeIds =
                                          selectedPracticeIds.toList();
                                      Navigator.pop(sheetContext);
                                      _addProblemToPracticeSets(
                                        problemModel.problemId,
                                        targetPracticeIds,
                                        themeProvider,
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                backgroundColor: selectedPracticeIds.isEmpty
                                    ? Colors.grey[300]
                                    : themeProvider.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const StandardText(
                                text: '추가',
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addProblemToPracticeSets(
      int problemId, List<int> practiceIds, ThemeHandler themeProvider) async {
    final practiceProvider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);

    LoadingDialog.show(context, '복습 세트에 추가 중...');

    try {
      for (final practiceId in practiceIds) {
        final updateModel = PracticeNoteUpdateModel(
          practiceNoteId: practiceId,
          addProblemIdList: [problemId],
          removeProblemIdList: const [],
        );
        await practiceProvider.updatePractice(
          updateModel,
          refreshAfterUpdate: false,
          showErrorSnackBar: false,
        );
      }

      if (!mounted) return;
      LoadingDialog.hide(context);
      SnackBarDialog.showSnackBar(
        context: context,
        message: practiceIds.length == 1
            ? '복습 세트에 추가되었습니다.'
            : '${practiceIds.length}개의 복습 세트에 추가되었습니다.',
        backgroundColor: themeProvider.primaryColor,
      );
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      SnackBarDialog.showSnackBar(
        context: context,
        message: '복습 세트에 추가하지 못했습니다. 잠시 후 다시 시도해주세요.',
        backgroundColor: Colors.red,
      );
      log('복습 세트 문제 추가 실패: $e');
    }
  }

  Future<void> _showDeleteProblemDialog(
      int problemId, ThemeHandler themeProvider) async {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '오답노트 삭제',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 내용
                const StandardText(
                  text: '정말로 이 오답노트를 삭제하시겠습니까?',
                  fontSize: 15,
                  color: Colors.black87,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const StandardText(
                          text: '취소',
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          FirebaseAnalytics.instance
                              .logEvent(name: 'problem_delete');

                          // context가 유효할 때 Provider와 Navigator 가져오기
                          final problemsProvider =
                              Provider.of<ProblemsProvider>(context,
                                  listen: false);
                          final navigator = Navigator.of(context);

                          // 다이얼로그 닫기
                          Navigator.pop(dialogContext);

                          // 로딩 다이얼로그 표시
                          LoadingDialog.show(context, '오답노트 지우는 중...');

                          try {
                            // 삭제 작업 수행
                            await problemsProvider.deleteProblems([problemId]);
                            //await practiceProvider.fetchAllPracticeContents();

                            if (mounted) {
                              setState(() {
                                _isProblemDeleted = true; // Set the flag
                              });
                              // 로딩 다이얼로그 닫기
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
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const StandardText(
                          text: '삭제',
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final horizontalPadding = isWide ? 60.0 : 30.0;

    // 화면 높이에 따라 패딩 값을 동적으로 설정
    double topPadding = 0;
    double bottomPadding = screenHeight * 0.03;

    if (isPractice) {
      return Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: topPadding,
          bottom: bottomPadding,
        ),
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

    // 분석 객체가 없으면 폴링하지 않음
    if (problem.analysis == null) {
      log('⚠️ No analysis object - polling not needed');
      _stopAnalysisPolling();
      return problem;
    }

    // 분석 상태에 따라 폴링 결정
    final analysisStatus = problem.analysis!.status;

    if (analysisStatus == ProblemAnalysisStatus.NO_IMAGE) {
      // 이미지 없음 - 폴링 중지
      log('📷 No image for analysis - polling not needed');
      _stopAnalysisPolling();
    } else if (analysisStatus == ProblemAnalysisStatus.COMPLETED) {
      // 분석 완료 - 폴링 중지
      log('✅ Analysis already completed - no polling needed');
      _stopAnalysisPolling();
    } else if (analysisStatus == ProblemAnalysisStatus.FAILED) {
      // 분석 실패 - 폴링 중지
      log('❌ Analysis failed - polling not needed');
      _stopAnalysisPolling();
    } else if (analysisStatus == ProblemAnalysisStatus.PROCESSING ||
        analysisStatus == ProblemAnalysisStatus.NOT_STARTED) {
      // 분석 진행 중 또는 시작 전 - 폴링 시작
      log('📊 Analysis in progress (status: $analysisStatus) - starting polling');

      // 분석 결과 조회 (await 하지 않고 백그라운드에서 실행)
      problemsProvider.fetchProblemAnalysis(problemId);

      // Smart Polling 시작
      _startAnalysisPolling(problemId);
    }

    return problem;
  }
}
