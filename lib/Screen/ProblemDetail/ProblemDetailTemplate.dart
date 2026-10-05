import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Problem/ProblemRegisterModel.dart';
import '../../Module/Design/AppToast.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Text/UnderlinedText.dart';
import '../../Module/Theme/GridPainter.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../ProblemSolve/ProblemSolveEntry.dart';
import 'Widget/AnalysisSection.dart';
import 'Widget/ImageSection.dart';
import 'Widget/MemoEditSheet.dart';
import 'Widget/RepeatSectionV2.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/SelectionPop.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Util/AppAnalytics.dart';

/// 공책에서 연 상세의 이전, 다음. 다시 풀기 버튼 양옆에 화살표로 둔다.
/// 넘길 곳이 없는 쪽은 null 이라 흐리게 막는다.
class ProblemDetailNavigation {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// 공책에서 몇 번째인지. 다시 풀기 버튼 안에 작게 붙인다. 예) '2 / 20+'
  final String? positionLabel;

  const ProblemDetailNavigation({
    this.onPrevious,
    this.onNext,
    this.positionLabel,
  });
}

class ProblemDetailTemplate extends StatefulWidget {
  final ProblemModel problemModel;
  final bool isExpanded;
  final Function(bool) onExpansionChanged;

  /// 다시 풀기를 저장까지 마쳤을 때 어떤 방식으로 풀었는지 알려 준다.
  /// 복습 세트에서 다음 문제를 바로 풀지 물을 때 쓴다.
  final ValueChanged<ProblemSolveMode>? onSolved;

  /// 있으면 화면이 열리자마자 이 방식으로 다시 풀기를 시작한다. 복습 세트에서
  /// `다음 문제 바로 풀기` 를 골랐을 때 앞 문제와 같은 방식으로 이어 푼다.
  final ProblemSolveMode? autoStartMode;

  /// AI 분석을 다시 요청한다. 분석하지 않은 문제, 한도 초과, 실패일 때 버튼으로 보인다.
  final VoidCallback? onRequestAnalysis;

  /// 분석을 기다리다 확인을 멈췄는지. 그때는 [onRefreshAnalysis] 로 다시 확인하게 한다.
  final bool analysisTimedOut;
  final VoidCallback? onRefreshAnalysis;

  /// 있으면 다시 풀기 버튼과 같은 줄에 이전, 다음 화살표를 둔다. 전에는 그
  /// 아래에 이전, 다음 줄이 한 겹 더 쌓여서 문제 이미지를 볼 자리가 좁았다.
  final ProblemDetailNavigation? navigation;

  const ProblemDetailTemplate({
    required this.problemModel,
    required this.isExpanded,
    required this.onExpansionChanged,
    this.onSolved,
    this.autoStartMode,
    this.onRequestAnalysis,
    this.analysisTimedOut = false,
    this.onRefreshAnalysis,
    this.navigation,
    super.key,
  });

  @override
  State<ProblemDetailTemplate> createState() => _ProblemDetailTemplateState();
}

class _ProblemDetailTemplateState extends State<ProblemDetailTemplate>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  int _reviewRefreshSignal = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // indexIsChanging 은 탭을 눌렀을 때만 참이라, 그것만 보면 손으로 밀어
      // 넘겼을 때 탭 표시가 이전 자리에 머물러 있었다.
      if (_tabController.index == _currentTabIndex) return;
      AppHaptic.selection();
      AppAnalytics.logEvent('problem_detail_tab', {
        'tab': const ['problem', 'answer', 'history'][_tabController.index],
      });
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    final autoStartMode = widget.autoStartMode;
    if (autoStartMode != null) {
      // 화면이 다 그려진 뒤에 연다. 넘김 효과가 끝나기 전에 위로 덮이지 않게
      // 한 박자 기다린다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(AppMotion.page, () {
          if (mounted) _startSolve(mode: autoStartMode);
        });
      });
    }
  }

  /// 다시 풀기. [mode] 를 넘기면 방식 고르기를 건너뛴다.
  Future<void> _startSolve({ProblemSolveMode? mode}) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final problemImageUrls = (widget.problemModel.problemImageDataList ?? [])
        .map((image) => image.imageUrl)
        .toList();
    ProblemSolveMode? usedMode = mode;

    final result = await ProblemSolveEntry.open(
      context: context,
      problemId: widget.problemModel.problemId,
      problemImageUrls: problemImageUrls,
      onRefresh: () {},
      themeProvider: themeProvider,
      mode: mode,
      onModeSelected: (selected) => usedMode = selected,
    );

    if (result == true && mounted) {
      setState(() {
        _reviewRefreshSignal++;
      });
      if (usedMode != null) widget.onSolved?.call(usedMode!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Column(
      children: [
        // 노트 헤더 (손글씨 탭 바)
        _buildNoteHeader(themeProvider, isWide),

        // 탭 내용
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: CustomPaint(
              painter: GridPainter(
                  gridColor: themeProvider.primaryColor, isSpring: true),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _tabContent(0, _buildProblemTab(themeProvider, isWide)),
                  _tabContent(1, _buildSolutionTab(themeProvider, isWide)),
                  _tabContent(2, _buildReviewHistoryTab(themeProvider, isWide)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 탭 사이를 오갈 때 옆으로 밀리기만 하던 것에 옅어짐과 내려앉음을 더한다.
  ///
  /// `TabController.animation` 은 손으로 미는 중에도 값이 계속 바뀌므로,
  /// 탭을 누른 경우와 밀어 넘긴 경우가 같은 모양으로 움직인다.
  Widget _tabContent(int index, Widget child) {
    final animation = _tabController.animation;
    if (animation == null) return child;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        // 0 이면 이 탭이 화면 한가운데, 1 이면 완전히 옆으로 비켜난 상태다.
        final distance = (animation.value - index).abs().clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - distance,
          child: Transform.translate(
            offset: Offset(0, 12 * distance),
            child: Transform.scale(
              scale: 1 - 0.02 * distance,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteHeader(ThemeHandler themeProvider, bool isWide) {
    final horizontalPadding = isWide ? 60.0 : 30.0;
    final headerTopPadding = isWide ? 10.0 : 6.0;
    final headerBottomPadding = isWide ? 8.0 : 6.0;
    final tabContainerPadding = isWide ? 5.0 : 4.0;
    final tabHeight = isWide ? 46.0 : 40.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        headerTopPadding,
        horizontalPadding,
        headerBottomPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(tabContainerPadding),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: themeProvider.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: themeProvider.primaryColor.withOpacity(0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: themeProvider.primaryColor.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: [
            Tab(
              height: tabHeight,
              child: _buildHeaderTab(
                title: '문제',
                icon: Icons.help,
                isActive: _currentTabIndex == 0,
                isWide: isWide,
                themeProvider: themeProvider,
              ),
            ),
            Tab(
              height: tabHeight,
              child: _buildHeaderTab(
                title: '정답',
                icon: Icons.task_alt,
                isActive: _currentTabIndex == 1,
                isWide: isWide,
                themeProvider: themeProvider,
              ),
            ),
            Tab(
              height: tabHeight,
              child: _buildHeaderTab(
                title: '복습 기록',
                icon: Icons.history_edu,
                isActive: _currentTabIndex == 2,
                isWide: isWide,
                themeProvider: themeProvider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTab({
    required String title,
    required IconData icon,
    required bool isActive,
    required bool isWide,
    required ThemeHandler themeProvider,
  }) {
    final activeColor = themeProvider.primaryColor;
    final inactiveColor = Colors.grey[600]!;
    final iconSize = isWide ? 16.0 : 14.0;
    final textSize = isWide ? 15.0 : 14.0;
    final gap = isWide ? 6.0 : 6.0;

    return SelectionPop(
      selected: isActive,
      peak: 1.1,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: isActive ? 1.0 : 0.0),
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        builder: (context, t, _) {
          final color = Color.lerp(inactiveColor, activeColor, t)!;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: color),
              SizedBox(width: gap),
              StandardText(
                text: title,
                fontSize: MobileFontSize.reduced(context, textSize),
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProblemTab(ThemeHandler themeProvider, bool isWide) {
    final horizontalPadding = isWide ? 60.0 : 30.0;
    final problemImageCount =
        widget.problemModel.problemImageDataList?.length ?? 0;

    // 태블릿 가로에서는 이미지를 왼쪽에 크게 두고, 정보와 다시 풀기 버튼을
    // 오른쪽에 둔다. 전에는 넓은 화면에서도 한 줄로 세워서 옆이 비었다.
    final size = MediaQuery.sizeOf(context);
    if (size.width >= 900 && size.width > size.height) {
      final imageUrls = widget.problemModel.problemImageDataList
              ?.map((m) => m.imageUrl)
              .toList() ??
          [];
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: _buildSectionCard(
                  themeProvider,
                  title: '문제 이미지',
                  icon: Icons.image,
                  trailing: _buildCountChip(problemImageCount, themeProvider),
                  child: buildImageSection(
                    context,
                    imageUrls,
                    '문제 이미지',
                    themeProvider,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 360,
              child: Column(
                children: [
                  _buildProblemMetaCard(themeProvider),
                  const Spacer(),
                  _buildBottomReviewCta(themeProvider, isWide),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProblemMetaCard(themeProvider),
                const SizedBox(height: 30),

                // 문제 이미지
                _buildSectionCard(
                  themeProvider,
                  title: '문제 이미지',
                  icon: Icons.image,
                  trailing: _buildCountChip(problemImageCount, themeProvider),
                  child: buildImageSection(
                    context,
                    widget.problemModel.problemImageDataList
                            ?.map((m) => m.imageUrl)
                            .toList() ??
                        [],
                    '문제 이미지',
                    themeProvider,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        _buildBottomReviewCta(themeProvider, isWide),
      ],
    );
  }

  Widget _buildProblemMetaCard(ThemeHandler themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: themeProvider.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              StandardText(
                text: '푼 날짜',
                fontSize: MobileFontSize.reduced(context, 14),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 12),
              // 글자를 크게 키우면 날짜가 줄을 넘어서, 남는 폭에 맞춰 줄인다.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: UnderlinedText(
                      text: DateFormat('yyyy년 M월 d일')
                          .format(widget.problemModel.displaySolvedAt),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomReviewCta(ThemeHandler themeProvider, bool isWide) {
    final navigation = widget.navigation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      alignment: Alignment.center,
      // 넓은 화면에서 버튼이 화면 폭 전체로 늘어나지 않게 막는다.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Row(
          children: [
            if (navigation != null) ...[
              _NavigationArrow(
                tooltip: '이전 문제',
                icon: Icons.chevron_left,
                accent: themeProvider.primaryColor,
                onTap: navigation.onPrevious,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: SizedBox(
                height: 50,
                child: FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: _startSolve,
                  backgroundColor: themeProvider.primaryColor,
                  icon: const Icon(Icons.replay, color: Colors.white, size: 20),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StandardText(
                        text: '다시 풀기',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      if (navigation?.positionLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: StandardText(
                            text: navigation!.positionLabel!,
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  elevation: 0,
                ),
              ),
            ),
            if (navigation != null) ...[
              const SizedBox(width: 10),
              _NavigationArrow(
                tooltip: '다음 문제',
                icon: Icons.chevron_right,
                accent: themeProvider.primaryColor,
                onTap: navigation.onNext,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCountChip(int count, ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: StandardText(
        text: '$count장',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: themeProvider.primaryColor,
      ),
    );
  }

  Widget _buildAddMemoButton(ThemeHandler themeProvider) {
    return InkWell(
      onTap: () => _editMemo(themeProvider),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: themeProvider.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 18, color: themeProvider.primaryColor),
            const SizedBox(width: 6),
            StandardText(
              text: '메모 추가',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// 메모만 바로 쓰고 저장한다. 비운 채로 저장하면 메모를 지운다.
  Future<void> _editMemo(ThemeHandler themeProvider) async {
    final before = widget.problemModel.memo ?? '';
    final memo = await showMemoEditSheet(
      context,
      initialMemo: before,
      color: themeProvider.primaryColor,
    );
    if (memo == null || !mounted) return;
    try {
      await Provider.of<ProblemsProvider>(context, listen: false).updateProblem(
        ProblemRegisterModel(
          problemId: widget.problemModel.problemId,
          memo: ProblemRegisterModel.clampMemo(memo),
        ),
      );
      AppAnalytics.logEvent('problem_memo_save', {
        'source': 'detail',
        'had_memo': before.isNotEmpty,
      });
      AppToast.success(memo.isEmpty ? '메모를 지웠어요' : '메모를 저장했어요');
    } catch (_) {
      AppToast.error('메모를 저장하지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Widget _buildSectionCard(
    ThemeHandler themeProvider, {
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(
                  icon,
                  color: themeProvider.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              StandardText(
                text: title,
                fontSize: MobileFontSize.reduced(context, 14),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSolutionTab(ThemeHandler themeProvider, bool isWide) {
    final horizontalPadding = isWide ? 60.0 : 30.0;
    final answerImageCount =
        widget.problemModel.answerImageDataList?.length ?? 0;

    // 공통 패딩
    final contentPadding = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: 24.0,
    );

    // AI 분석 결과 위젯
    final aiAnalysisWidget = _buildSectionCard(
      themeProvider,
      title: 'AI 분석 결과',
      icon: Icons.auto_awesome,
      child: buildAnalysisSection(
        context,
        widget.problemModel.analysis,
        themeProvider.primaryColor,
        onRequestAnalysis: widget.onRequestAnalysis,
        timedOut: widget.analysisTimedOut,
        onRefreshAnalysis: widget.onRefreshAnalysis,
      ),
    );
    final hasTags = widget.problemModel.tags.isNotEmpty;
    final hasMemo = widget.problemModel.memo != null &&
        widget.problemModel.memo!.isNotEmpty;

    // 메모 및 해설 이미지 위젯
    final memoAndImageWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 해설 이미지
        _buildSectionCard(
          themeProvider,
          title: '해설 이미지',
          icon: Icons.image,
          trailing: _buildCountChip(answerImageCount, themeProvider),
          child: buildImageSection(
            context,
            widget.problemModel.answerImageDataList
                    ?.map((m) => m.imageUrl)
                    .toList() ??
                [],
            '해설 이미지',
            themeProvider,
          ),
        ),
        const SizedBox(height: 24),
        if (hasTags) ...[
          _buildSectionCard(
            themeProvider,
            title: '태그',
            icon: Icons.local_offer,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.problemModel.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(
                      color: themeProvider.primaryColor,
                      width: 1,
                    ),
                  ),
                  child: StandardText(
                    text: '#${tag.name}',
                    fontSize: 12,
                    color: themeProvider.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // 메모는 비어 있어도 칸을 둔다. 전에는 메모가 없으면 칸이 아예 없어서,
        // 복습하다 떠오른 것을 적으려면 수정 화면 전체로 가야 했다.
        _buildSectionCard(
          themeProvider,
          title: '메모',
          icon: Icons.edit,
          trailing: hasMemo
              ? IconButton(
                  tooltip: '메모 고치기',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.edit_outlined,
                      size: 18, color: themeProvider.primaryColor),
                  onPressed: () => _editMemo(themeProvider),
                )
              : null,
          child: hasMemo
              ? Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: UnderlinedText(
                    text: widget.problemModel.memo!,
                    fontSize: 18,
                  ),
                )
              : _buildAddMemoButton(themeProvider),
        ),
      ],
    );

    if (isWide) {
      // 태블릿 가로 (2열) 레이아웃
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: contentPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0), // 오른쪽 여백
                child: memoAndImageWidget,
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0), // 왼쪽 여백
                child: aiAnalysisWidget,
              ),
            ),
          ],
        ),
      );
    } else {
      // 휴대폰 또는 태블릿 세로 (1열) 레이아웃
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            memoAndImageWidget,
            const SizedBox(height: 24), // 두 섹션 사이 간격
            aiAnalysisWidget,
            const SizedBox(height: 24), // 마지막 섹션 하단 간격
          ],
        ),
      );
    }
  }

  Widget _buildReviewHistoryTab(ThemeHandler themeProvider, bool isWide) {
    return buildRepeatSectionV2(
      context,
      widget.problemModel,
      themeProvider.primaryColor,
      isWide,
      refreshSignal: _reviewRefreshSignal,
      onStartSolve: _startSolve,
    );
  }
}

/// 다시 풀기 버튼 양옆의 이전, 다음 화살표. 버튼과 높이를 맞춘다.
class _NavigationArrow extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _NavigationArrow({
    required this.tooltip,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? accent.withValues(alpha: 0.1) : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            width: 50,
            height: 50,
            child: Icon(
              icon,
              size: 26,
              color: enabled ? accent : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}
