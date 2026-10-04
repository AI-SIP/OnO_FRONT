import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:ono/Module/Dialog/SnackBarDialog.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterScreen.dart';
import 'package:ono/Util/AppAnalytics.dart';
import 'package:ono/Util/AppErrorReporter.dart';
import 'package:ono/Util/PendingDeletion.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemAnalysisStatus.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Dialog/LoadingDialog.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/ProblemsProvider.dart';
import '../PracticeNote/PracticeContinueSheet.dart';
import '../PracticeNote/PracticeNavigationButtons.dart';
import '../PracticeNote/PracticeTitleWriteScreen.dart';
import '../ProblemSolve/ProblemSolveEntry.dart';
import 'ProblemDetailTemplate.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Motion/TossDialog.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppToast.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/Skeleton.dart';

class ProblemDetailScreen extends StatefulWidget {
  final int problemId;
  final bool isPractice;

  /// 추천 복습에서 열었을 때 추천 목록의 문제 순서. 있으면 한 문제를 저장하고
  /// 돌아왔을 때 다음 추천 문제를 바로 풀지 묻는다.
  final List<int>? reviewQueue;

  /// 복습 세트에서 `다음 문제 바로 풀기` 로 넘어왔을 때, 앞 문제와 같은 방식으로
  /// 바로 다시 풀기를 시작한다.
  final ProblemSolveMode? autoStartMode;

  const ProblemDetailScreen({
    required this.problemId,
    this.isPractice = false,
    this.reviewQueue,
    this.autoStartMode,
    super.key,
  });

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

  /// 분석을 기다리다 확인을 멈췄는지. 계속 `분석하고 있어요` 로 남겨 두지 않고
  /// 다시 확인하기 버튼을 보인다.
  bool _analysisTimedOut = false;
  bool _isRequestingAnalysis = false;

  @override
  void initState() {
    super.initState();
    AppAnalytics.logScreenView('ProblemDetailScreen');
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
    if (_analysisTimedOut && mounted) {
      setState(() => _analysisTimedOut = false);
    }

    debugPrint('🔄 Started analysis polling for problem $problemId');

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
      debugPrint(
          '⏱️ Analysis polling timeout - stopped after ${_pollingCount} attempts');
      _stopAnalysisPolling();
      if (mounted) setState(() => _analysisTimedOut = true);
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
        debugPrint('🔍 Polling analysis status (attempt $_pollingCount)...');

        // 서버에서 최신 분석 상태 조회
        await problemsProvider.fetchProblemAnalysis(problemId);
        _analysisPollingFailureCount = 0;

        // 현재 문제 상태 확인
        final problem = await problemsProvider.getProblem(problemId);

        // 분석이 완료되거나 실패하거나 이미지가 없으면 폴링 중지
        final status = problem.analysis?.status;
        if (status == ProblemAnalysisStatus.COMPLETED ||
            status == ProblemAnalysisStatus.FAILED ||
            status == ProblemAnalysisStatus.NO_IMAGE ||
            status == ProblemAnalysisStatus.RATE_LIMIT_EXCEEDED) {
          // 등록하면 AI 분석이 뒤에서 돈다. 얼마나 성공하는지 본다.
          AppAnalytics.logEvent('problem_analysis_result', {
            'result': status!.name.toLowerCase(),
            'poll_count': _pollingCount,
          });
        }
        if (problem.analysis?.status == ProblemAnalysisStatus.COMPLETED) {
          debugPrint('✅ Analysis completed - polling stopped');
          _stopAnalysisPolling();
          // UI 강제 업데이트
          if (mounted) {
            setState(() {
              _problemModelFuture = Future.value(problem);
            });
          }
          return;
        } else if (problem.analysis?.status == ProblemAnalysisStatus.FAILED) {
          debugPrint('❌ Analysis failed - polling stopped');
          _stopAnalysisPolling();
          // UI 강제 업데이트
          if (mounted) {
            setState(() {
              _problemModelFuture = Future.value(problem);
            });
          }
          return;
        } else if (status == ProblemAnalysisStatus.RATE_LIMIT_EXCEEDED ||
            status == ProblemAnalysisStatus.NOT_STARTED) {
          // 한도를 넘겼거나 분석이 시작되지 않았다. 기다려도 바뀌지 않는다.
          _stopAnalysisPolling();
          if (mounted) {
            setState(() {
              _problemModelFuture = Future.value(problem);
            });
          }
          return;
        } else if (problem.analysis?.status == ProblemAnalysisStatus.NO_IMAGE) {
          debugPrint('📷 No image detected during polling - polling stopped');
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
        debugPrint('⚠️ Error during analysis polling: $e');
        await AppErrorReporter.report(
          e,
          stackTrace,
          source: 'problem_analysis_polling',
          severity: AppErrorSeverity.warning,
          sendToDiscord:
              _analysisPollingFailureCount >= _maxAnalysisPollingFailures,
        );
        if (_analysisPollingFailureCount >= _maxAnalysisPollingFailures) {
          debugPrint('⏱️ Analysis polling stopped after repeated failures');
          _stopAnalysisPolling();
          return;
        }

        _pollAnalysisStatus(problemId);
      }
    });
  }

  /// 이 문제만 AI 분석을 다시 요청한다.
  Future<void> _requestAnalysis(int problemId) async {
    if (_isRequestingAnalysis) return;
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final before = (await problemsProvider.getProblem(problemId))
        .analysis
        ?.status
        ?.name
        .toLowerCase();
    if (!mounted) return;
    setState(() => _isRequestingAnalysis = true);
    try {
      await problemsProvider.requestProblemAnalysis(problemId);
      AppAnalytics.logEvent('problem_analysis_request', {
        'source': before ?? 'unknown',
      });
    } catch (e, stackTrace) {
      // 요청 실패 안내는 HttpService 가 띄운다.
      unawaited(AppErrorReporter.report(
        e,
        stackTrace,
        source: 'problem_analysis_request',
        severity: AppErrorSeverity.warning,
      ));
    } finally {
      if (mounted) setState(() => _isRequestingAnalysis = false);
    }
    if (!mounted) return;

    final problem = await problemsProvider.getProblem(problemId);
    if (!mounted) return;
    setState(() {
      _problemModelFuture = Future.value(problem);
    });
    if (problem.analysis?.status == ProblemAnalysisStatus.PROCESSING) {
      _startAnalysisPolling(problemId);
    }
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

                // 분석 상태나 메모가 바뀌었을 때만 rebuild. 메모는 해설 탭에서
                // 바로 고칠 수 있다.
                return previous.memo != next.memo ||
                    previous.analysis?.status != next.analysis?.status ||
                    previous.analysis?.subject != next.analysis?.subject ||
                    previous.analysis?.problemType !=
                        next.analysis?.problemType;
              },
              builder: (context, problemModel, child) {
                // 이 builder 는 이미 Expanded 안에 있다. 여기서 Expanded 를 또
                // 두르면 ParentDataWidget 오류가 난다.
                if (_isProblemDeleted) return const SizedBox.shrink();
                if (problemModel == null) {
                  // 초기 로딩 시에만 Future로 가져오기
                  return FutureBuilder<ProblemModel>(
                    future:
                        Provider.of<ProblemsProvider>(context, listen: false)
                            .getProblem(widget.problemId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SkeletonList(
                          itemCount: 3,
                          itemHeight: 160,
                          spacing: 16,
                          padding: EdgeInsets.all(16),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: StandardText(
                            text: '오답노트를 찾을 수 없습니다.',
                            color: themeProvider.primaryColor,
                          ),
                        );
                      } else if (snapshot.hasData) {
                        // 화면이 열릴 때 주는 모션은 데이터가 오기 전에 끝난다.
                        // 정작 내용이 뜨는 순간에는 아무 움직임이 없어서,
                        // 여기서 한 번 더 자리를 잡으며 나타나게 한다.
                        return AppearTransition(
                          child: _buildContent(snapshot.data!),
                        );
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
                return AppearTransition(child: _buildContent(problemModel));
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
        .logEvent(name: 'problem_detail_action_dialog_click');

    final openTime = DateTime.now();
    showModalBottomSheet(
      sheetAnimationStyle: AppMotion.sheetStyle,
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
                            borderRadius:
                                BorderRadius.circular(AppRadius.small),
                          ),
                          child: Icon(
                            Icons.edit_note,
                            color: themeProvider.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        StandardText(
                          text: '오답노트 편집하기',
                          fontSize: MobileFontSize.reduced(context, 20),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
                          TossPageRoute(
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
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
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
                fontSize: MobileFontSize.reduced(context, 16),
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

    // 이미 담긴 세트도 체크된 채로 보여 주고, 체크를 풀면 그 세트에서 뺀다.
    final initialPracticeIds = practiceProvider.practices
        .where((practice) =>
            practice.problemIdList.contains(problemModel.problemId))
        .map((practice) => practice.practiceId)
        .toSet();
    final checkedPracticeIds = {...initialPracticeIds};
    final openTime = DateTime.now();

    showModalBottomSheet(
      sheetAnimationStyle: AppMotion.sheetStyle,
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final practices = practiceProvider.practices;
            final changed =
                checkedPracticeIds.length != initialPracticeIds.length ||
                    !checkedPracticeIds.containsAll(initialPracticeIds);

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
                    bottom: MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).padding.bottom +
                        20,
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.small),
                            ),
                            child: Icon(
                              Icons.playlist_add,
                              color: themeProvider.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StandardText(
                              text: '복습 세트에 담기',
                              fontSize: MobileFontSize.reduced(context, 20),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: practices.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == practices.length) {
                              return _buildNewPracticeSetItem(
                                themeProvider,
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _openNewPracticeSet(problemModel.problemId);
                                },
                              );
                            }

                            final practice = practices[index];
                            final alreadyAdded = initialPracticeIds
                                .contains(practice.practiceId);
                            final checked = checkedPracticeIds
                                .contains(practice.practiceId);

                            return PressableScale(
                              haptic: HapticLevel.selection,
                              onTap: () {
                                setSheetState(() {
                                  if (!checkedPracticeIds
                                      .remove(practice.practiceId)) {
                                    checkedPracticeIds.add(practice.practiceId);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: checked
                                      ? themeProvider.primaryColor
                                          .withValues(alpha: 0.08)
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.medium),
                                  border: Border.all(
                                    color: checked
                                        ? themeProvider.primaryColor
                                        : Colors.grey.shade200,
                                    width: checked ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      checked
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: checked
                                          ? themeProvider.primaryColor
                                          : Colors.grey.shade400,
                                      size: 24,
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
                                            color: AppColors.textPrimary,
                                          ),
                                          const SizedBox(height: 4),
                                          StandardText(
                                            text:
                                                '문제 ${practice.practiceSize}개',
                                            fontSize: 13,
                                            color: Colors.grey[600]!,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (alreadyAdded)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.medium),
                                        ),
                                        child: StandardText(
                                          text: '담김',
                                          fontSize: 12,
                                          color: Colors.grey[700]!,
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
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.medium),
                                ),
                              ),
                              child: StandardText(
                                text: '취소',
                                fontSize: MobileFontSize.reduced(context, 15),
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextButton(
                              onPressed: !changed
                                  ? null
                                  : () {
                                      final addIds = checkedPracticeIds
                                          .difference(initialPracticeIds)
                                          .toList();
                                      final removeIds = initialPracticeIds
                                          .difference(checkedPracticeIds)
                                          .toList();
                                      Navigator.pop(sheetContext);
                                      _applyPracticeSetChanges(
                                        problemModel.problemId,
                                        addPracticeIds: addIds,
                                        removePracticeIds: removeIds,
                                        themeProvider: themeProvider,
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                backgroundColor: !changed
                                    ? Colors.grey[300]
                                    : themeProvider.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.medium),
                                ),
                              ),
                              child: const StandardText(
                                text: '완료',
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

  Widget _buildNewPracticeSetItem(ThemeHandler themeProvider,
      {required VoidCallback onTap}) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: themeProvider.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.add, color: themeProvider.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: StandardText(
                text: '새 복습 세트 만들기',
                fontSize: 16,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 이 문제를 넣은 채로 세트 만들기(제목과 알림) 화면을 연다.
  void _openNewPracticeSet(int problemId) {
    Navigator.push(
      context,
      TossPageRoute(
        builder: (context) => PracticeTitleWriteScreen(
          practiceRegisterModel: PracticeNoteRegisterModel(
            practiceId: null,
            practiceTitle: '',
            registerProblemIdList: [problemId],
          ),
          closeOnlySelf: true,
        ),
      ),
    );
  }

  Future<void> _applyPracticeSetChanges(
    int problemId, {
    required List<int> addPracticeIds,
    required List<int> removePracticeIds,
    required ThemeHandler themeProvider,
  }) async {
    final practiceProvider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);

    LoadingDialog.show(context, '복습 세트에 반영 중...');

    try {
      for (final practiceId in addPracticeIds) {
        await practiceProvider.addProblems(practiceId, [problemId]);
      }
      for (final practiceId in removePracticeIds) {
        await practiceProvider.removeProblems(practiceId, [problemId]);
      }

      if (addPracticeIds.isNotEmpty) {
        AppAnalytics.logEvent('practice_set_add_problem', {
          'set_count': addPracticeIds.length,
          'source': 'problem_sheet',
        });
      }
      if (removePracticeIds.isNotEmpty) {
        AppAnalytics.logEvent('practice_set_remove_problem', {
          'count': removePracticeIds.length,
          'source': 'problem_sheet',
        });
      }
      if (!mounted) return;
      LoadingDialog.hide(context);
      SnackBarDialog.showSnackBar(
        context: context,
        message: removePracticeIds.isEmpty
            ? '복습 세트에 담았어요.'
            : addPracticeIds.isEmpty
                ? '복습 세트에서 뺐어요.'
                : '복습 세트를 바꿨어요.',
        backgroundColor: themeProvider.primaryColor,
      );
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      SnackBarDialog.showSnackBar(
        context: context,
        message: '복습 세트에 반영하지 못했습니다. 잠시 후 다시 시도해주세요.',
        backgroundColor: Colors.red,
      );
      debugPrint('복습 세트 반영 실패: $e');
    }
  }

  Future<void> _showDeleteProblemDialog(
      int problemId, ThemeHandler themeProvider) async {
    return showTossDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
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
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StandardText(
                      text: '오답노트 삭제',
                      fontSize: MobileFontSize.reduced(context, 18),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 내용
                StandardText(
                  text: '정말로 이 오답노트를 삭제하시겠습니까?',
                  fontSize: MobileFontSize.reduced(context, 15),
                  color: AppColors.textPrimary,
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
                            borderRadius:
                                BorderRadius.circular(AppRadius.small),
                          ),
                        ),
                        child: StandardText(
                          text: '취소',
                          fontSize: MobileFontSize.reduced(context, 15),
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          // context가 유효할 때 Provider와 Navigator 가져오기
                          final problemsProvider =
                              Provider.of<ProblemsProvider>(context,
                                  listen: false);
                          final navigator = Navigator.of(context);

                          // 다이얼로그 닫기
                          Navigator.pop(dialogContext);

                          // 상세를 바로 닫고 잠깐 되돌리기를 보인 뒤에 지운다.
                          // 전에는 바로 지워서 잘못 지운 오답노트를 되살릴 수
                          // 없었다. 목록은 지우기를 기다리는 문제를 걸러 그린다.
                          if (mounted) {
                            setState(() => _isProblemDeleted = true);
                            navigator.pop(true);
                          }
                          try {
                            final deleted =
                                await PendingDeletion.instance.schedule(
                              problemIds: [problemId],
                              message: '오답노트를 지웠어요',
                              commit: () =>
                                  problemsProvider.deleteProblems([problemId]),
                            );
                            if (deleted) {
                              // 예전에는 삭제를 요청하기 전에 남겨서 실패도 셌다.
                              AppAnalytics.logEvent('problem_delete', {
                                'count': 1,
                                'source': 'detail',
                              });
                            }
                          } catch (e) {
                            debugPrint('문제 삭제 실패: $e');
                            AppToast.error('오답노트를 삭제하지 못했어요. 잠시 후 다시 시도해주세요.');
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.small),
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
      onSolved: widget.isPractice
          ? _onPracticeProblemSolved
          : widget.reviewQueue != null
              ? _onReviewQueueProblemSolved
              : null,
      autoStartMode: widget.autoStartMode,
      onRequestAnalysis: _isRequestingAnalysis
          ? null
          : () => _requestAnalysis(problemModel.problemId),
      analysisTimedOut: _analysisTimedOut,
      onRefreshAnalysis: () {
        Provider.of<ProblemsProvider>(context, listen: false)
            .fetchProblemAnalysis(problemModel.problemId);
        _startAnalysisPolling(problemModel.problemId);
      },
    );
  }

  /// 추천 복습에서 연 문제를 저장하고 돌아오면 다음 추천 문제를 바로 풀지 묻는다.
  ///
  /// 복습 세트와 같은 시트를 쓴다. 다음 문제는 연 순간의 추천 목록 순서를 따른다.
  Future<void> _onReviewQueueProblemSolved(ProblemSolveMode mode) async {
    final queue = widget.reviewQueue!;
    final index = queue.indexOf(widget.problemId);
    if (index < 0) return;
    final nextId = index + 1 < queue.length ? queue[index + 1] : null;
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    ProblemModel? next;
    if (nextId != null) {
      try {
        next = await problemsProvider.getProblem(nextId);
      } catch (_) {
        // 다음 문제를 못 받으면 제목 없이 묻는다.
        next = ProblemModel(problemId: nextId);
      }
      if (!mounted) return;
    }

    final choice = await showPracticeContinueSheet(
      context,
      solvedPosition: index + 1,
      total: queue.length,
      next: next,
      mode: mode,
      accentColor: themeProvider.primaryColor,
      finishQuestion: '추천 복습 목록으로 돌아갈까요?',
      finishLabel: '목록으로 돌아가기',
      finishDescription: '남은 추천 문제를 확인해요.',
    );
    AppAnalytics.logEvent('review_due_continue_choice', {
      'choice': choice.analyticsName,
      'mode': mode == ProblemSolveMode.inApp ? 'canvas' : 'offline',
      'count': queue.length,
    });
    if (!mounted) return;

    switch (choice) {
      case PracticeContinueChoice.solveNext:
        _openReviewQueueProblem(nextId!, autoStartMode: mode);
      case PracticeContinueChoice.viewNext:
        _openReviewQueueProblem(nextId!);
      case PracticeContinueChoice.finish:
        Navigator.of(context).pop();
      case PracticeContinueChoice.stop:
        break;
    }
  }

  void _openReviewQueueProblem(int problemId,
      {ProblemSolveMode? autoStartMode}) {
    Navigator.of(context).pushReplacement(
      TossPageRoute(
        builder: (_) => ProblemDetailScreen(
          problemId: problemId,
          reviewQueue: widget.reviewQueue,
          autoStartMode: autoStartMode,
        ),
      ),
    );
  }

  /// 복습 세트에서 한 문제를 저장하고 돌아오면 다음 문제를 바로 풀지 묻는다.
  Future<void> _onPracticeProblemSolved(ProblemSolveMode mode) async {
    final practiceProvider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    final problems = practiceProvider.sessionProblems;
    final index =
        problems.indexWhere((problem) => problem.problemId == widget.problemId);
    if (index < 0) return;
    final next = index + 1 < problems.length ? problems[index + 1] : null;
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    final choice = await showPracticeContinueSheet(
      context,
      solvedPosition: index + 1,
      total: problems.length,
      next: next,
      mode: mode,
      accentColor: themeProvider.primaryColor,
    );
    AppAnalytics.logEvent('practice_continue_choice', {
      'choice': choice.analyticsName,
      'mode': mode == ProblemSolveMode.inApp ? 'canvas' : 'offline',
      'count': problems.length,
    });
    if (!mounted) return;

    switch (choice) {
      case PracticeContinueChoice.solveNext:
        openPracticeProblem(context, next!.problemId,
            isNext: true, autoStartMode: mode);
      case PracticeContinueChoice.viewNext:
        openPracticeProblem(context, next!.problemId, isNext: true);
      case PracticeContinueChoice.finish:
        openPracticeCompletion(context, practiceProvider);
      case PracticeContinueChoice.stop:
        break;
    }
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

    debugPrint('Moved to problem: ${problem.problemId}');

    // 분석 객체가 없으면 폴링하지 않음
    if (problem.analysis == null) {
      debugPrint('⚠️ No analysis object - polling not needed');
      _stopAnalysisPolling();
      return problem;
    }

    // 분석 상태에 따라 폴링 결정
    final analysisStatus = problem.analysis!.status;

    if (analysisStatus == ProblemAnalysisStatus.NO_IMAGE) {
      // 이미지 없음 - 폴링 중지
      debugPrint('📷 No image for analysis - polling not needed');
      _stopAnalysisPolling();
    } else if (analysisStatus == ProblemAnalysisStatus.COMPLETED) {
      // 분석 완료 - 폴링 중지
      debugPrint('✅ Analysis already completed - no polling needed');
      _stopAnalysisPolling();
    } else if (analysisStatus == ProblemAnalysisStatus.FAILED) {
      // 분석 실패 - 폴링 중지
      debugPrint('❌ Analysis failed - polling not needed');
      _stopAnalysisPolling();
    } else if (analysisStatus == ProblemAnalysisStatus.NOT_STARTED ||
        analysisStatus == ProblemAnalysisStatus.RATE_LIMIT_EXCEEDED) {
      // 분석을 요청하지 않았거나 한도를 넘겼다. 기다려도 바뀌지 않아서 확인하지
      // 않고, 화면에서 분석하기 버튼을 보인다.
      _stopAnalysisPolling();
    } else if (analysisStatus == ProblemAnalysisStatus.PROCESSING) {
      // 분석 진행 중 - 폴링 시작
      debugPrint(
          '📊 Analysis in progress (status: $analysisStatus) - starting polling');

      // 분석 결과 조회 (await 하지 않고 백그라운드에서 실행)
      problemsProvider.fetchProblemAnalysis(problemId);

      // Smart Polling 시작
      _startAnalysisPolling(problemId);
    }

    return problem;
  }
}
