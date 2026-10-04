import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Provider/CosmeticProvider.dart';
import '../User/Widget/FrogCharacter.dart';
import '../../Model/PracticeNote/PracticeNoteDetailModel.dart';
import '../../Model/PracticeNote/PracticeNoteUpdateModel.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Problem/ProblemSolveModel.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Problem/ProblemThumbnailCard.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';
import '../../Service/Api/Problem/ProblemSolveService.dart';
import '../ProblemDetail/ProblemDetailScreen.dart';
import 'PracticeProblemSelectionScreen.dart';
import 'PracticeSetAnalysis.dart';
import 'PracticeSetAnalysisCard.dart';
import 'PracticeTitleWriteScreen.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppToast.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Util/AppAnalytics.dart';
import '../../Util/AppErrorReporter.dart';
import '../../Module/Dialog/ConfirmDialog.dart';

class PracticeDetailScreen extends StatefulWidget {
  final PracticeNoteDetailModel practice;

  /// 세트 분석에 쓸 복습 기록을 받는다. 테스트에서 바꿔 끼운다.
  final ProblemSolveService? problemSolveService;

  const PracticeDetailScreen({
    super.key,
    required this.practice,
    this.problemSolveService,
  });

  @override
  State<PracticeDetailScreen> createState() => _PracticeDetailScreenState();
}

class _PracticeDetailScreenState extends State<PracticeDetailScreen> {
  /// 세트 분석에 쓸 복습 기록을 한 번에 몇 문제씩 받는지.
  static const int _analysisBatchSize = 4;

  late final ProblemPracticeProvider _practiceProvider;
  late final ProblemSolveService _problemSolveService;

  bool _editing = false;
  final Set<int> _selectedIds = {};
  bool _removing = false;

  PracticeSetAnalysis? _analysis;

  /// 분석을 마지막으로 계산한(또는 계산 중인) 문제 목록의 모양. 문제를 빼고
  /// 넣거나 복습을 저장하면 모양이 바뀌어서 다시 계산한다.
  String? _analysisKey;

  @override
  void initState() {
    super.initState();
    _practiceProvider = context.read<ProblemPracticeProvider>();
    _problemSolveService = widget.problemSolveService ?? ProblemSolveService();
  }

  @override
  void dispose() {
    _practiceProvider.leavePractice(widget.practice.practiceId);
    super.dispose();
  }

  /// 화면에 띄울 세트. 이름이나 문제를 바꾸면 Provider 쪽이 새것이다.
  PracticeNoteDetailModel get _practice {
    final current = _practiceProvider.currentPracticeNote;
    return current != null && current.practiceId == widget.practice.practiceId
        ? current
        : widget.practice;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final practiceProvider = Provider.of<ProblemPracticeProvider>(context);
    _scheduleAnalysis(practiceProvider.currentProblems);

    return PopScope(
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _editing) _exitEditing();
      },
      child: Scaffold(
        appBar: _buildAppBar(context, themeProvider),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildProblemList(
                      context, practiceProvider, themeProvider),
                ),
                if (_editing)
                  _buildRemoveBar(context, themeProvider)
                else if (practiceProvider.currentProblems.isNotEmpty)
                  _buildNextButton(context, themeProvider, practiceProvider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 세트 분석 ====================

  void _scheduleAnalysis(List<ProblemModel> problems) {
    final key = problems
        .map((p) => '${p.problemId}:${p.solveCount}:${p.lastSolvedAt}')
        .join(',');
    if (key == _analysisKey) return;
    _analysisKey = key;

    final problemIds = problems.map((p) => p.problemId).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAnalysis(key, problemIds);
    });
  }

  Future<void> _loadAnalysis(String key, List<int> problemIds) async {
    final solvesByProblem = <int, List<ProblemSolveModel>>{};

    for (var start = 0;
        start < problemIds.length;
        start += _analysisBatchSize) {
      final batch = problemIds.skip(start).take(_analysisBatchSize);
      await Future.wait(batch.map((problemId) async {
        try {
          solvesByProblem[problemId] =
              await _problemSolveService.getProblemSolvesByProblemId(
            problemId,
            showErrorSnackBar: false,
          );
        } catch (e, stackTrace) {
          // 받은 문제만으로 계산하고 카드에 일부 실패를 적는다.
          await AppErrorReporter.report(
            e,
            stackTrace,
            source: 'practice_set_analysis_load',
            severity: AppErrorSeverity.warning,
          );
        }
      }));
      if (!mounted || key != _analysisKey) return;
    }

    if (!mounted || key != _analysisKey) return;
    setState(() {
      _analysis = PracticeSetAnalysis.from(problemIds, solvesByProblem);
    });
  }

  // ==================== 앱바와 ⋮ 메뉴 ====================

  AppBar _buildAppBar(BuildContext context, ThemeHandler themeProvider) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: StandardText(
        text: _practice.practiceTitle,
        fontSize: 18,
        color: themeProvider.primaryColor,
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0), // 우측에 여백 추가
          child: Row(
            children: [
              IconButton(
                tooltip: '더 보기',
                icon: Icon(
                  Icons.more_vert,
                  color: themeProvider.primaryColor,
                ),
                onPressed: () => _showBottomSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    final openTime = DateTime.now();
    showModalBottomSheet(
      sheetAnimationStyle: AppMotion.sheetStyle,
      backgroundColor: Colors.transparent,
      context: context,
      isDismissible: false,
      builder: (sheetContext) {
        return TapRegion(
          onTapOutside: (_) {
            // Workaround for iPadOS 26.1 bug: https://github.com/flutter/flutter/issues/177992
            if (DateTime.now().difference(openTime) <
                const Duration(milliseconds: 500)) {
              return;
            }
            if (Navigator.canPop(sheetContext)) {
              Navigator.pop(sheetContext);
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
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title with icon
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
                          text: '복습 세트 관리',
                          fontSize: MobileFontSize.reduced(context, 18),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Menu items
                    _buildActionItem(
                      context: context,
                      icon: Icons.tune,
                      iconColor: themeProvider.primaryColor,
                      title: '세트 설정',
                      subtitle: '제목과 복습 알림을 바꿔요.',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openSettings(context);
                      },
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 12),
                    _buildActionItem(
                      context: context,
                      icon: Icons.delete_forever,
                      iconColor: Colors.red,
                      title: '복습 세트 삭제하기',
                      titleColor: Colors.red,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showDeletePracticeDialog(context);
                      },
                      themeProvider: themeProvider,
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

  /// 제목과 알림만 바꾼다. 문제는 세트 상세에서 바로 넣고 뺀다.
  void _openSettings(BuildContext context) {
    final practice = _practice;
    Navigator.push(
      context,
      TossPageRoute(
        builder: (context) => PracticeTitleWriteScreen(
          practiceNoteUpdateModel: PracticeNoteUpdateModel(
            practiceNoteId: practice.practiceId,
            practiceTitle: practice.practiceTitle,
            addProblemIdList: const [],
            removeProblemIdList: const [],
          ),
          practiceNoteDetailModel: practice,
          closeOnlySelf: true,
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
    required ThemeHandler themeProvider,
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
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StandardText(
                    text: title,
                    fontSize: MobileFontSize.reduced(context, 16),
                    color: titleColor ?? Colors.black87,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    StandardText(
                      text: subtitle,
                      fontSize: MobileFontSize.reduced(context, 13),
                      color: Colors.grey[600]!,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ==================== 문제 목록 ====================

  Widget _buildProblemList(BuildContext context,
      ProblemPracticeProvider provider, ThemeHandler themeProvider) {
    final problems = provider.currentProblems;

    if (problems.isEmpty) {
      return _buildEmptyProblemState(context, themeProvider);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: problems.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: PracticeSetAnalysisCard(
              analysis: _analysis,
              practiceCount: _practice.practiceCount,
              lastSolvedAt: _practice.lastSolvedAt,
              accentColor: themeProvider.primaryColor,
            ),
          );
        }
        if (index == 1) {
          return _buildListHeader(context, problems.length, themeProvider);
        }
        return _buildProblemItem(problems[index - 2], themeProvider);
      },
    );
  }

  Widget _buildListHeader(
      BuildContext context, int count, ThemeHandler themeProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: StandardText(
              text: '문제 $count개',
              fontSize: MobileFontSize.reduced(context, 15),
              color: AppColors.textPrimary,
            ),
          ),
          if (_editing)
            _buildHeaderButton(
              context,
              label: '완료',
              color: themeProvider.primaryColor,
              onPressed: _exitEditing,
            )
          else ...[
            _buildHeaderButton(
              context,
              label: '편집',
              color: Colors.grey[700]!,
              onPressed: () => _enterEditing(),
            ),
            _buildHeaderButton(
              context,
              label: '+ 추가',
              color: themeProvider.primaryColor,
              onPressed: () => _openAddMode(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: StandardText(
        text: label,
        fontSize: MobileFontSize.reduced(context, 14),
        color: color,
      ),
    );
  }

  Widget _buildProblemItem(ProblemModel problem, ThemeHandler themeProvider) {
    final imageUrl = problem.problemImageDataList != null &&
            problem.problemImageDataList!.isNotEmpty
        ? problem.problemImageDataList!.first.imageUrl
        : null;
    final title =
        problem.reference?.isNotEmpty == true ? problem.reference! : '제목 없음';
    final result = _analysis?.resultOf(problem.problemId);
    final selected = _selectedIds.contains(problem.problemId);

    final card = ProblemThumbnailCard(
      title: title,
      imageUrl: imageUrl,
      tags: problem.tags,
      solveCount: problem.solveCount,
      lastSolvedAt: problem.lastSolvedAt,
      themeProvider: themeProvider,
      trailing: result == null ? null : _buildResultBadge(result),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: PressableScale(
        haptic: _editing ? HapticLevel.selection : HapticLevel.none,
        onTap: () => _editing
            ? _toggleSelected(problem.problemId)
            : _openProblem(context, problem.problemId),
        onLongPress: _editing ? null : () => _enterEditing(problem.problemId),
        child: _editing
            ? Row(
                children: [
                  Semantics(
                    checked: selected,
                    child: Icon(
                      selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: selected
                          ? themeProvider.primaryColor
                          : Colors.grey[400],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: card),
                ],
              )
            : card,
      ),
    );
  }

  /// 세트 문제 카드 오른쪽에 최근 결과를 적는다. 받기 전에는 원래 막대를 둔다.
  Widget _buildResultBadge(PracticeProblemResult result) {
    return Container(
      constraints: const BoxConstraints(minWidth: 52),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PracticeResultStyle.color(result).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: StandardText(
        text: PracticeResultStyle.label(result),
        fontSize: 12,
        color: PracticeResultStyle.textColor(result),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 세트 상세에서 문제를 열면 일반 오답노트 상세로 연다. 회차가 아니다.
  Future<void> _openProblem(BuildContext context, int problemId) async {
    _practiceProvider.endSession();
    await Navigator.push(
      context,
      TossPageRoute(
        builder: (context) => ProblemDetailScreen(problemId: problemId),
      ),
    );
  }

  Future<void> _openAddMode(BuildContext context) async {
    await Navigator.push(
      context,
      TossPageRoute(
        builder: (context) => PracticeProblemSelectionScreen(
          practiceModel: _practice,
          addMode: true,
        ),
      ),
    );
  }

  // ==================== 편집과 빼기 ====================

  void _enterEditing([int? problemId]) {
    setState(() {
      _editing = true;
      _selectedIds.clear();
      if (problemId != null) _selectedIds.add(problemId);
    });
  }

  void _exitEditing() {
    setState(() {
      _editing = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(int problemId) {
    setState(() {
      if (!_selectedIds.remove(problemId)) _selectedIds.add(problemId);
    });
  }

  Widget _buildRemoveBar(BuildContext context, ThemeHandler themeProvider) {
    final count = _selectedIds.length;
    final enabled = count > 0 && !_removing;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              elevation: 0,
            ),
            onPressed: enabled ? _removeSelected : null,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: StandardText(
                text: count == 0 ? '뺄 문제를 골라 주세요' : '$count개 선택 · 세트에서 빼기',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: enabled ? Colors.white : Colors.grey[600]!,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 묻지 않고 바로 뺀다. 잘못 뺐으면 `+ 추가` 로 다시 넣는다.
  Future<void> _removeSelected() async {
    final practiceId = widget.practice.practiceId;
    // 화면 순서대로 들고 있어야 되돌릴 때 같은 순서로 다시 넣는다.
    final problemIds = _practiceProvider.currentProblems
        .map((problem) => problem.problemId)
        .where(_selectedIds.contains)
        .toList();
    setState(() => _removing = true);

    try {
      await _practiceProvider.removeProblems(practiceId, problemIds);
      AppAnalytics.logEvent('practice_set_remove_problem', {
        'count': problemIds.length,
        'source': 'detail',
      });
      if (!mounted) return;
      setState(() {
        _removing = false;
        _editing = false;
        _selectedIds.clear();
      });
      AppToast.success('${problemIds.length}문제를 세트에서 뺐어요.');
    } catch (e, stackTrace) {
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: 'practice_set_remove_problem',
        severity: AppErrorSeverity.warning,
      );
      if (!mounted) return;
      setState(() => _removing = false);
      AppToast.error('문제를 빼지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Widget _buildEmptyProblemState(
      BuildContext context, ThemeHandler themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 빈 자리를 지키는 것도 내가 꾸민 개구리다. 배경 파츠는 뺀다.
            FrogLayerStack(
              layers: context.watch<CosmeticProvider>().layersWithoutBackdrop,
              size: 110,
            ),
            const SizedBox(height: 16),
            const StandardText(
              text: '복습 세트가 비어있어요.\n오답노트를 추가해 편리한 복습을 해보세요!',
              fontSize: 16,
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 190,
              child: ElevatedButton(
                onPressed: () => _openAddMode(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                child: const StandardText(
                  text: '오답노트 추가하기',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 복습하기 ====================

  Widget _buildNextButton(BuildContext context, ThemeHandler themeProvider,
      ProblemPracticeProvider practiceProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            elevation: 0,
          ),
          onPressed: () => _showPracticeStartModeSheet(
              context, themeProvider, practiceProvider),
          child: const StandardText(
            text: '복습하기',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _onNextButtonPressed(
      BuildContext context, ProblemPracticeProvider practiceProvider,
      {required bool shuffle, bool wrongOnly = false}) {
    if (practiceProvider.currentProblems.isEmpty) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '복습 세트가 비어있어요!',
        backgroundColor: Colors.red,
      );
      return;
    }

    practiceProvider.startSession(
      shuffle: shuffle,
      onlyProblemIds: wrongOnly ? _analysis?.wrongProblemIds.toSet() : null,
    );
    final problems = practiceProvider.sessionProblems;
    if (problems.isEmpty) {
      practiceProvider.endSession();
      return;
    }

    AppAnalytics.logEvent('practice_start', {
      'shuffle': shuffle,
      'wrong_only': wrongOnly,
      'problem_count': problems.length,
    });

    Navigator.push(
      context,
      TossPageRoute(
        builder: (context) => ProblemDetailScreen(
          problemId: problems.first.problemId,
          isPractice: true,
        ),
      ),
    );
  }

  void _showPracticeStartModeSheet(BuildContext context,
      ThemeHandler themeProvider, ProblemPracticeProvider practiceProvider) {
    if (practiceProvider.currentProblems.isEmpty) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '복습 세트가 비어있어요!',
        backgroundColor: Colors.red,
      );
      return;
    }

    // 지난 선택을 기억하지 않는다. 열 때마다 꺼진 채로 시작한다.
    var wrongOnly = false;
    final openTime = DateTime.now();
    showModalBottomSheet(
      sheetAnimationStyle: AppMotion.sheetStyle,
      backgroundColor: Colors.transparent,
      context: context,
      isDismissible: false,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final wrongCount = _analysis?.wrongProblemIds.length ?? 0;
            final total = practiceProvider.currentProblems.length;
            final count = wrongOnly ? wrongCount : total;

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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24.0, horizontal: 20.0),
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
                                Icons.play_arrow,
                                color: themeProvider.primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            StandardText(
                              // 문제를 열면 '다시 풀기 방식 선택' 이 한 번 더 떠서,
                              // 이름이 같으면 같은 걸 두 번 묻는 것처럼 보였다.
                              // 여기서는 순서만 고른다.
                              text: '푸는 순서 고르기',
                              fontSize: MobileFontSize.reduced(context, 18),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildWrongOnlySwitch(
                          context,
                          themeProvider,
                          value: wrongOnly,
                          wrongCount: wrongCount,
                          onChanged: (value) =>
                              setSheetState(() => wrongOnly = value),
                        ),
                        const SizedBox(height: 12),
                        _buildActionItem(
                          context: context,
                          icon: Icons.format_list_numbered,
                          iconColor: themeProvider.primaryColor,
                          title: '담은 순서대로 풀기',
                          subtitle: '세트에 담은 순서대로 $count문제를 풀어요.',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _onNextButtonPressed(
                              context,
                              practiceProvider,
                              shuffle: false,
                              wrongOnly: wrongOnly,
                            );
                          },
                          themeProvider: themeProvider,
                        ),
                        const SizedBox(height: 12),
                        _buildActionItem(
                          context: context,
                          icon: Icons.shuffle,
                          iconColor: themeProvider.primaryColor,
                          title: '섞어서 풀기',
                          subtitle: '순서를 섞어서 $count문제를 풀어요.',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _onNextButtonPressed(
                              context,
                              practiceProvider,
                              shuffle: true,
                              wrongOnly: wrongOnly,
                            );
                          },
                          themeProvider: themeProvider,
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
      },
    );
  }

  /// 켠 채로 순서나 셔플을 고르면 최근에 틀린 문제들만 푼다. 틀린 문제가
  /// 없거나 분석을 아직 받는 중이면 막는다.
  Widget _buildWrongOnlySwitch(
    BuildContext context,
    ThemeHandler themeProvider, {
    required bool value,
    required int wrongCount,
    required ValueChanged<bool> onChanged,
  }) {
    final enabled = wrongCount > 0;
    final accent = themeProvider.primaryColor;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        decoration: BoxDecoration(
          color: value ? accent.withValues(alpha: 0.06) : Colors.grey[50],
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: value ? accent.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StandardText(
                    text: '틀린 문제만',
                    fontSize: MobileFontSize.reduced(context, 16),
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 4),
                  StandardText(
                    text: '총 $wrongCount문제',
                    fontSize: MobileFontSize.reduced(context, 13),
                    color: Colors.grey[600]!,
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              activeTrackColor: accent,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeletePracticeDialog(BuildContext context) async {
    // 화면을 닫고 나면 context 가 죽어서 Provider 를 못 찾는다. 미리 잡아 둔다.
    final provider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: '이 복습 세트를 삭제할까요?',
      message: '세트만 지워지고 담긴 오답노트는 그대로 남아요.',
      confirmLabel: '삭제하기',
      destructive: true,
    );
    if (!confirmed) return;
    if (navigator.canPop()) navigator.pop();

    try {
      await provider.deletePractices([widget.practice.practiceId]);
      AppAnalytics.logEvent('practice_set_deleted', {
        'count': 1,
        'source': 'detail',
      });
      AppToast.success('복습 세트를 삭제했어요.');
    } catch (e) {
      debugPrint('복습 세트 삭제 실패: $e');
      AppToast.error('복습 세트를 삭제하지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }
}
