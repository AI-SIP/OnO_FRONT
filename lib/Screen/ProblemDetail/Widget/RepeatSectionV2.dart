import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ono/Module/Text/StandardLightText.dart';
import 'package:ono/Module/Text/UnderlinedText.dart';
import 'package:provider/provider.dart';

import '../../../Model/Problem/AnswerStatus.dart';
import '../../../Model/Problem/ImprovementType.dart';
import '../../../Model/Problem/ProblemModel.dart';
import '../../../Model/Problem/ProblemSolveModel.dart';
import '../../../Model/Problem/ProblemSolveUpdateDto.dart';
import '../../../Module/Design/AppToast.dart';
import '../../../Provider/ProblemsProvider.dart';
import '../../../Provider/ReviewDueProvider.dart';
import '../../../Module/Emoji/OnoEmojiImage.dart';
import '../../../Module/Dialog/LoadingDialog.dart';
import '../../../Module/Image/DisplayImage.dart';
import '../../../Module/Image/FullScreenImage.dart';
import '../../../Module/Text/mobile_font_size.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ClayIcon.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Service/Api/Problem/ProblemSolveService.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/AppearTransition.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Motion/TossPageRoute.dart';
import '../../../Module/Motion/TossDialog.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Model/Problem/ProblemSolveTrend.dart';
import '../../../Util/AppAnalytics.dart';
import 'ReviewStatusStyle.dart';
import 'ReviewTrendPanel.dart';
import '../../../Util/PendingDeletion.dart';
import '../../../Module/Image/ImageCompareScreen.dart';

class RepeatSectionV2 extends StatefulWidget {
  final ProblemModel problem;
  final Color iconColor;
  final bool isWide;
  final int refreshSignal;

  /// 테스트에서 가짜 응답을 넣을 때만 넘긴다. 없으면 실제 서비스를 쓴다.
  final ProblemSolveService? service;

  /// 기록이 없을 때 바로 다시 풀게 한다. 없으면 버튼을 그리지 않는다.
  final VoidCallback? onStartSolve;

  const RepeatSectionV2({
    super.key,
    required this.problem,
    required this.iconColor,
    required this.isWide,
    this.refreshSignal = 0,
    this.service,
    this.onStartSolve,
  });

  @override
  State<RepeatSectionV2> createState() => _RepeatSectionV2State();
}

class _RepeatSectionV2State extends State<RepeatSectionV2>
    with AutomaticKeepAliveClientMixin {
  late final problemSolveService = widget.service ?? ProblemSolveService();
  late Future<List<ProblemSolveModel>> _problemSolvesFuture;
  final Map<int, bool> _expandedStates = {}; // 각 카드의 펼침 상태 관리
  int? _selectedSolveId; // 태블릿 상세 패널에 표시할 항목

  // 폰에서 추이 판의 동그라미를 눌렀을 때 그 카드까지 스크롤하려고 둔다.
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _cardKeys = {};
  int? _tappedRound;

  // build 마다 다시 정렬하지 않도록 같은 목록이면 계산해 둔 것을 쓴다.
  List<ProblemSolveModel>? _trendSource;
  ProblemSolveTrend? _trend;

  @override
  void initState() {
    super.initState();
    _problemSolvesFuture = problemSolveService
        .getProblemSolvesByProblemId(widget.problem.problemId);
    PendingDeletion.instance.addListener(_onPendingDeletionChanged);
  }

  void _onPendingDeletionChanged() {
    if (mounted) setState(() {});
  }

  @override
  bool get wantKeepAlive => true; // 탭 전환 시에도 상태 유지

  @override
  void didUpdateWidget(covariant RepeatSectionV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      refresh();
    }
  }

  @override
  void dispose() {
    PendingDeletion.instance.removeListener(_onPendingDeletionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  ProblemSolveTrend _trendOf(List<ProblemSolveModel> problemSolves) {
    if (_trend == null || !identical(_trendSource, problemSolves)) {
      _trendSource = problemSolves;
      _trend = ProblemSolveTrend.from(problemSolves);
    }
    return _trend!;
  }

  Future<void> _goToRound(
      List<ProblemSolveModel> oldestFirst, int round) async {
    final solve = oldestFirst[round - 1];
    setState(() {
      _tappedRound = round;
      _selectedSolveId = solve.problemSolveId;
      if (!widget.isWide) _expandedStates[solve.problemSolveId] = true;
    });
    AppAnalytics.logEvent('review_trend_round_tap', {
      'round': round,
      'count': oldestFirst.length,
    });
    if (widget.isWide) return;

    // ListView.builder 는 화면 밖 카드를 아직 만들지 않았을 수 있다. 카드가
    // 만들어질 때까지 조금씩 내려간 뒤 그 카드가 보이게 맞춘다. 동그라미는
    // 목록 맨 위 추이 카드에 있어서 찾는 회차 카드는 항상 아래쪽에 있다.
    // 카드가 다 펼쳐진 뒤에 맞춰야 한다. 펼쳐지는 중에는 목록 길이가 짧아서
    // 마지막 카드 쪽은 끝까지 내려가지 못한다.
    await Future<void>.delayed(AppMotion.normal);
    if (!mounted) return;
    for (var i = 0; i < 30 && mounted; i++) {
      final cardContext = _cardKeys[solve.problemSolveId]?.currentContext;
      if (cardContext != null) {
        if (!cardContext.mounted) return;
        await Scrollable.ensureVisible(
          cardContext,
          duration: AppMotion.page,
          curve: AppMotion.emphasized,
          alignment: 0.05,
        );
        return;
      }
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent) return;
      _scrollController.jumpTo(min(
        position.pixels + position.viewportDimension * 0.8,
        position.maxScrollExtent,
      ));
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  void _toggleExpanded(int solveId, bool newValue) {
    setState(() {
      _expandedStates[solveId] = newValue;
    });
  }

  // 복습 기록 새로고침
  void refresh() {
    setState(() {
      _problemSolvesFuture = problemSolveService
          .getProblemSolvesByProblemId(widget.problem.problemId);
    });
  }

  // 복습 기록 새로고침 (비동기 - 완료될 때까지 대기)
  Future<void> refreshAsync() async {
    // 지우기는 되돌리기를 기다린 뒤에 끝나서, 그 사이 화면이 닫혔을 수 있다.
    if (!mounted) return;
    final newFuture = problemSolveService
        .getProblemSolvesByProblemId(widget.problem.problemId);

    setState(() {
      _problemSolvesFuture = newFuture;
    });

    // 새로운 데이터 로딩 완료까지 대기
    await newFuture;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수

    return FutureBuilder<List<ProblemSolveModel>>(
      future: _problemSolvesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StandardText(
                    text: '복습 기록을 불러오지 못했어요',
                    fontSize: 16,
                    color: Colors.grey[600]!,
                  ),
                  const SizedBox(height: 14),
                  // 전에는 문구만 있어서 화면을 나갔다 들어와야 했다.
                  OutlinedButton(
                    onPressed: refresh,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.iconColor,
                      side: BorderSide(
                          color: widget.iconColor.withValues(alpha: 0.5)),
                      minimumSize: const Size(0, 44),
                    ),
                    child: StandardText(
                      text: '다시 시도',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.iconColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 지우고 되돌리기를 기다리는 기록은 빼고 그린다. 숨길 것이 없으면
        // 받은 목록을 그대로 써서 추이 계산을 다시 하지 않는다.
        final fetched = snapshot.data ?? [];
        final pending = PendingDeletion.instance;
        final problemSolves =
            fetched.any((s) => pending.isSolveHidden(s.problemSolveId))
                ? fetched
                    .where((s) => !pending.isSolveHidden(s.problemSolveId))
                    .toList()
                : fetched;

        if (problemSolves.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ClayIcon(
                            'assets/Icon/PencilDetail.png',
                            width: 100,
                            height: 100,
                          ),
                          const SizedBox(height: 16),
                          StandardText(
                            text: '아직 복습 기록이 없습니다.',
                            fontSize: MobileFontSize.reduced(context, 16),
                            color: Colors.black,
                          ),
                          const SizedBox(height: 8),
                          StandardText(
                            text: '문제를 복습하고 기록을 남겨보세요!',
                            fontSize: MobileFontSize.reduced(context, 14),
                            color: Colors.black,
                          ),
                          // 다시 풀기 버튼은 문제 탭에만 있어서 여기서는 할 일이
                          // 없었다.
                          if (widget.onStartSolve != null) ...[
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: widget.onStartSolve,
                              icon: const Icon(Icons.replay,
                                  color: Colors.white, size: 18),
                              label: const StandardText(
                                text: '다시 풀기',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.iconColor,
                                elevation: 0,
                                minimumSize: const Size(0, 44),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 22),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.large),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // 회차 번호는 가장 오래된 기록이 1회차다. 추이 카드와 번호가 어긋나지
        // 않도록 서버 순서 대신 추이가 정렬한 순서에서 번호를 매기고, 카드
        // 목록은 최근 복습이 위로 오게 뒤집어 보여 준다.
        final trend = _trendOf(problemSolves);
        final oldestFirst = trend.solves;
        if (_selectedSolveId == null ||
            !oldestFirst.any((s) => s.problemSolveId == _selectedSolveId)) {
          _selectedSolveId = oldestFirst.last.problemSolveId;
        }

        if (widget.isWide) {
          return _buildTabletMasterDetail(context, oldestFirst, trend);
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: 30.0,
            vertical: 20.0,
          ),
          itemCount: oldestFirst.length + 1,
          itemBuilder: (context, itemIndex) {
            if (itemIndex == 0) {
              return AppearTransition(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ReviewTrendPanel(
                    trend: trend,
                    accentColor: widget.iconColor,
                    isWide: false,
                    selectedRound: _tappedRound,
                    onRoundTap: (round) => _goToRound(oldestFirst, round),
                  ),
                ),
              );
            }
            // 최근 복습이 맨 위다.
            final index = oldestFirst.length - itemIndex;
            final solve = oldestFirst[index];
            final displayIndex = index + 1;
            // 기록이 한꺼번에 툭 나타나는 대신 위에서부터 차례로 들어온다.
            // 아래쪽까지 지연을 매기면 마지막 카드가 한참 뒤에 뜨므로
            // 여섯 번째부터는 같은 시점에 들어오게 묶는다.
            return AppearTransition(
              key: _cardKeys.putIfAbsent(solve.problemSolveId, GlobalKey.new),
              delay: AppMotion.stagger * (itemIndex < 6 ? itemIndex : 6),
              child: _ProblemSolveCard(
                solve: solve,
                index: displayIndex,
                iconColor: widget.iconColor,
                // 처음에는 가장 최근 회차만 펼쳐 둔다. 전에는 모두 접혀 있어서
                // 하나씩 눌러 열어야 했다.
                isExpanded: _expandedStates[solve.problemSolveId] ??
                    (index == oldestFirst.length - 1),
                onToggle: (value) =>
                    _toggleExpanded(solve.problemSolveId, value),
                onRefreshAsync: refreshAsync,
                service: problemSolveService,
                problem: widget.problem,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabletMasterDetail(BuildContext context,
      List<ProblemSolveModel> oldestFirst, ProblemSolveTrend trend) {
    final selectedIndex = oldestFirst
        .indexWhere((solve) => solve.problemSolveId == _selectedSolveId);
    final safeSelectedIndex = selectedIndex >= 0 ? selectedIndex : 0;
    final selectedSolve = oldestFirst[safeSelectedIndex];
    // 높이가 낮은 가로 태블릿에서는 카드를 다 두면 아래 목록이 너무 좁아진다.
    final isShort = MediaQuery.sizeOf(context).height < 700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 20.0),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: constraints.maxHeight * 0.55),
              child: SingleChildScrollView(
                child: AppearTransition(
                  child: ReviewTrendPanel(
                    trend: trend,
                    accentColor: widget.iconColor,
                    isWide: true,
                    compact: isShort,
                    selectedRound: safeSelectedIndex + 1,
                    onRoundTap: (round) => _goToRound(oldestFirst, round),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
                child: _buildTabletSplit(
                    oldestFirst, selectedSolve, safeSelectedIndex)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletSplit(List<ProblemSolveModel> oldestFirst,
      ProblemSolveModel selectedSolve, int safeSelectedIndex) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.large),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: oldestFirst.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                // 최근 복습이 맨 위다.
                final round = oldestFirst.length - index;
                final solve = oldestFirst[round - 1];
                return AppearTransition(
                  delay: AppMotion.stagger * (index < 6 ? index : 6),
                  child: _TabletSolveListItem(
                    solve: solve,
                    index: round,
                    isSelected: solve.problemSolveId == _selectedSolveId,
                    onTap: () {
                      setState(() {
                        _selectedSolveId = solve.problemSolveId;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: _ProblemSolveCard(
              solve: selectedSolve,
              index: safeSelectedIndex + 1,
              iconColor: widget.iconColor,
              isExpanded: true,
              onToggle: (_) {},
              onRefreshAsync: refreshAsync,
              service: problemSolveService,
              problem: widget.problem,
              showExpandIcon: false,
            ),
          ),
        ),
      ],
    );
  }
}

class RepeatSectionV2Wrapper extends StatefulWidget {
  final ProblemModel problem;
  final Color iconColor;
  final bool isWide;
  final int refreshSignal;
  final VoidCallback? onStartSolve;

  const RepeatSectionV2Wrapper({
    super.key,
    required this.problem,
    required this.iconColor,
    required this.isWide,
    this.refreshSignal = 0,
    this.onStartSolve,
  });

  @override
  State<RepeatSectionV2Wrapper> createState() => _RepeatSectionV2WrapperState();
}

class _RepeatSectionV2WrapperState extends State<RepeatSectionV2Wrapper> {
  @override
  Widget build(BuildContext context) {
    return RepeatSectionV2(
      problem: widget.problem,
      iconColor: widget.iconColor,
      isWide: widget.isWide,
      refreshSignal: widget.refreshSignal,
      onStartSolve: widget.onStartSolve,
    );
  }
}

Widget buildRepeatSectionV2(
  BuildContext ctx,
  ProblemModel problem,
  Color iconColor,
  bool isWide, {
  int refreshSignal = 0,
  VoidCallback? onStartSolve,
}) {
  return RepeatSectionV2Wrapper(
    problem: problem,
    iconColor: iconColor,
    isWide: isWide,
    refreshSignal: refreshSignal,
    onStartSolve: onStartSolve,
  );
}

class _ProblemSolveCard extends StatelessWidget {
  final ProblemSolveModel solve;

  /// 내 풀이를 문제, 정답과 나란히 볼 때 쓴다.
  final ProblemModel problem;
  final int index;
  final Color iconColor;
  final bool isExpanded;
  final Function(bool) onToggle;
  final Future<void> Function() onRefreshAsync;
  final ProblemSolveService service;
  final bool showExpandIcon;

  const _ProblemSolveCard({
    required this.solve,
    required this.index,
    required this.iconColor,
    required this.isExpanded,
    required this.onToggle,
    required this.onRefreshAsync,
    required this.service,
    required this.problem,
    this.showExpandIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final statusColor = ReviewStatusStyle.color(solve.answerStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            PressableScale(
              haptic: HapticLevel.selection,
              onTap: () => onToggle(!isExpanded),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14.0)),
                ),
                child: Row(
                  children: [
                    // 상태 아이콘 + 뱃지
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Icon(ReviewStatusStyle.icon(solve.answerStatus),
                          color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StandardText(
                                text: '$index회차',
                                fontSize: MobileFontSize.reduced(context, 16),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.medium),
                                ),
                                child: StandardText(
                                  text: solve.answerStatus.displayName,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              // 회차마다 기분이 따로 남는다. 안 고른 회차도
                              // 있어서 있을 때만 그린다.
                              if (solve.moodEmojiKey != null) ...[
                                const SizedBox(width: 8),
                                OnoEmojiImage(
                                  emojiKey: solve.moodEmojiKey,
                                  size: 22,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_month,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              StandardText(
                                text: DateFormat('yyyy년 MM월 dd일 HH:mm')
                                    .format(solve.practicedAt),
                                fontSize: 13,
                                color: Colors.grey[600]!,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 확장 아이콘
                    if (showExpandIcon)
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: AppMotion.normal,
                        curve: AppMotion.emphasized,
                        child: Icon(Icons.expand_more, color: statusColor),
                      ),
                    if (showExpandIcon) const SizedBox(width: 8),
                    // 메뉴 버튼
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: statusColor,
                        size: 20,
                      ),
                      // 전에는 누르는 영역이 아이콘 크기(20)뿐이라 옆의 펼치기와
                      // 헷갈려 눌렸다.
                      tooltip: '복습 기록 관리',
                      constraints:
                          const BoxConstraints(minWidth: 44, minHeight: 44),
                      onPressed: () =>
                          _showOptionsDialog(context, themeProvider),
                    ),
                  ],
                ),
              ),
            ),

            // 상세 내용. 붙였다 뗐다 하면 툭툭 끊겨서, 높이가 늘어나는 동안
            // 내용이 옅게 들어오도록 바꿨다.
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild:
                  _buildExpandedContent(context, themeProvider, statusColor),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppMotion.normal,
              sizeCurve: AppMotion.emphasized,
              firstCurve: AppMotion.exit,
              secondCurve: AppMotion.enter,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
      BuildContext context, ThemeHandler themeProvider, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 소요 시간
          if (solve.timeSpentSeconds != null)
            _buildInfoRow(
              context,
              Icons.timer,
              '소요 시간',
              _formatTimeSpent(solve.timeSpentSeconds!),
              themeProvider.primaryColor,
            ),
          if (solve.timeSpentSeconds != null) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 20),
          ],

          // 개선사항
          if (solve.improvements.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Icon(Icons.trending_up,
                      color: themeProvider.primaryColor, size: 18),
                ),
                const SizedBox(width: 8),
                StandardText(
                  text: '개선된 점',
                  fontSize: MobileFontSize.reduced(context, 15),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...solve.improvements.map((improvement) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StandardLightText(
                        text: improvement.description,
                        fontSize: MobileFontSize.reduced(context, 14),
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 20),
          ],

          // 회고
          if (solve.reflection != null && solve.reflection!.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Icon(Icons.edit_note,
                      color: themeProvider.primaryColor, size: 18),
                ),
                const SizedBox(width: 8),
                StandardText(
                  text: '복습 메모',
                  fontSize: MobileFontSize.reduced(context, 15),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(color: AppColors.border),
              ),
              child: UnderlinedText(
                text: solve.reflection!,
                fontSize: MobileFontSize.reduced(context, 16),
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 20),
          ],

          // 풀이 이미지
          if (solve.imageUrls.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Icon(Icons.image,
                      color: themeProvider.primaryColor, size: 18),
                ),
                const SizedBox(width: 8),
                StandardText(
                  text: '풀이 이미지',
                  fontSize: MobileFontSize.reduced(context, 15),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: StandardText(
                    text: '${solve.imageUrls.length}장',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ImageSlider(
              imageUrls: solve.imageUrls,
              statusColor: statusColor,
              primaryColor: themeProvider.primaryColor,
            ),
            if (_compareGroups.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openCompare(context),
                  icon: Icon(Icons.compare,
                      size: 18, color: themeProvider.primaryColor),
                  label: StandardText(
                    text: '문제, 정답과 비교하기',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryColor,
                  ),
                  style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<ImageCompareGroup> get _compareGroups => [
        ImageCompareGroup(label: '내 풀이', imagePaths: solve.imageUrls),
        ImageCompareGroup(
          label: '문제',
          imagePaths: [
            for (final image in problem.problemImageDataList ?? const [])
              if (image.imageUrl.trim().isNotEmpty) image.imageUrl,
          ],
        ),
        ImageCompareGroup(
          label: '정답',
          imagePaths: [
            for (final image in problem.answerImageDataList ?? const [])
              if (image.imageUrl.trim().isNotEmpty) image.imageUrl,
          ],
        ),
      ].where((g) => g.imagePaths.isNotEmpty).toList();

  void _openCompare(BuildContext context) {
    AppAnalytics.logEvent('image_compare_open', {'source': 'history'});
    Navigator.push(
      context,
      TossPageRoute(
        builder: (_) => ImageCompareScreen(groups: _compareGroups),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        StandardText(
          text: '$label: ',
          fontSize: MobileFontSize.reduced(context, 14),
          fontWeight: FontWeight.bold,
          color: color,
        ),
        StandardText(
          text: value,
          fontSize: MobileFontSize.reduced(context, 14),
          color: AppColors.textPrimary,
        ),
      ],
    );
  }

  void _showOptionsDialog(
      BuildContext parentContext, ThemeHandler themeProvider) {
    showTossDialog(
      context: parentContext,
      builder: (dialogContext) => Dialog(
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
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  StandardText(
                    text: '복습 기록 관리',
                    fontSize: MobileFontSize.reduced(parentContext, 18),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 결과 고치기. 서버가 고친 결과로 복습 일정을 다시 계산한다
              // (OnO_BACKEND #348). 그 전에는 일정이 그대로 남아서 막아 뒀다.
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _editAnswerStatus(parentContext, themeProvider);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    backgroundColor:
                        themeProvider.primaryColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit,
                          color: themeProvider.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      StandardText(
                        text: '결과 고치기',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 삭제 버튼
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showDeleteConfirmDialog(parentContext, themeProvider);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      StandardText(
                        text: '삭제',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 취소 버튼
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                  ),
                  child: StandardText(
                    text: '취소',
                    fontSize: MobileFontSize.reduced(parentContext, 15),
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext parentContext, ThemeHandler themeProvider) {
    showTossDialog(
      context: parentContext,
      builder: (dialogContext) => Dialog(
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
                    text: '삭제 확인',
                    fontSize: MobileFontSize.reduced(parentContext, 18),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 내용
              StandardText(
                text: '이 복습 기록을 정말 삭제하시겠습니까?',
                fontSize: MobileFontSize.reduced(parentContext, 15),
                color: AppColors.textPrimary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 액션 버튼
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                      ),
                      child: StandardText(
                        text: '취소',
                        fontSize: MobileFontSize.reduced(parentContext, 14),
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _handleDelete(parentContext, themeProvider);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                      ),
                      child: const StandardText(
                        text: '삭제',
                        fontSize: 14,
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
  }

  // 삭제 핸들러
  /// 이 회차의 결과만 다시 고른다. 회고, 개선점, 시간, 기분은 그대로 둔다.
  Future<void> _editAnswerStatus(
      BuildContext context, ThemeHandler themeProvider) async {
    final picked = await showModalBottomSheet<AnswerStatus>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StandardText(
                text: '이번 복습 결과를 고칠게요',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: 6),
              const StandardText(
                text: '고친 결과로 다음 복습일을 다시 잡아요',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 14),
              for (final status in const [
                AnswerStatus.CORRECT,
                AnswerStatus.PARTIAL,
                AnswerStatus.WRONG,
              ])
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(
                    ReviewStatusStyle.icon(status),
                    color: ReviewStatusStyle.color(status),
                  ),
                  title: StandardText(
                    text: status.displayName,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  trailing: status == solve.answerStatus
                      ? Icon(Icons.check, color: themeProvider.primaryColor)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, status),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == solve.answerStatus || !context.mounted) {
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final problemsProvider = context.read<ProblemsProvider?>();
    final reviewDueProvider = context.read<ReviewDueProvider?>();
    LoadingDialog.show(context, '복습 기록 고치는 중...');
    try {
      // PATCH 는 전체 교체라 바꾸지 않는 값도 그대로 실어야 지워지지 않는다.
      await service.updateProblemSolve(
        ProblemSolveUpdateDto(
          problemSolveId: solve.problemSolveId,
          answerStatus: picked,
          reflection: solve.reflection,
          improvements: solve.improvements,
          timeSpentSeconds: solve.timeSpentSeconds,
          moodEmojiKey: solve.moodEmojiKey,
        ),
      );
      AppAnalytics.logEvent('problem_solve_edit', {
        'from': solve.answerStatus.name.toLowerCase(),
        'to': picked.name.toLowerCase(),
      });
      await onRefreshAsync();
      // 고친 결과로 다음 복습일과 추천 목록이 바뀐다.
      await problemsProvider?.fetchProblem(solve.problemId,
          showErrorSnackBar: false);
      unawaited(reviewDueProvider?.fetchReviewDue());

      if (rootNavigator.canPop()) rootNavigator.pop();
      AppToast.success('복습 결과를 고쳤어요');
    } catch (e) {
      if (rootNavigator.canPop()) rootNavigator.pop();
      AppToast.error('복습 결과를 고치지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  /// 목록에서 바로 빼고 잠깐 되돌리기를 보인 뒤에 지운다. 지운 뒤에는 서버가
  /// 다시 잡은 다음 복습일과 추천 목록도 맞춘다.
  Future<void> _handleDelete(
      BuildContext context, ThemeHandler themeProvider) async {
    final solveId = solve.problemSolveId;
    final problemsProvider = context.read<ProblemsProvider?>();
    final reviewDueProvider = context.read<ReviewDueProvider?>();

    try {
      final deleted = await PendingDeletion.instance.schedule(
        solveIds: [solveId],
        message: '복습 기록을 지웠어요',
        commit: () => service.deleteProblemSolve(solveId),
      );
      if (!deleted) return;

      await onRefreshAsync();
      await problemsProvider?.fetchProblem(solve.problemId,
          showErrorSnackBar: false);
      unawaited(reviewDueProvider?.fetchReviewDue());
    } catch (e) {
      AppToast.error('복습 기록을 지우지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  String _formatTimeSpent(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) return '$minutes분';
    return '$minutes분 ${seconds.toString().padLeft(2, '0')}초';
  }
}

class _TabletSolveListItem extends StatelessWidget {
  final ProblemSolveModel solve;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabletSolveListItem({
    required this.solve,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = ReviewStatusStyle.color(solve.answerStatus);
    final borderColor =
        isSelected ? statusColor.withOpacity(0.7) : Colors.grey[300]!;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected ? statusColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(ReviewStatusStyle.icon(solve.answerStatus),
                  color: statusColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StandardText(
                        text: '$index회차',
                        fontSize: MobileFontSize.reduced(context, 14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                        child: StandardText(
                          text: solve.answerStatus.displayName,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      if (solve.moodEmojiKey != null) ...[
                        const SizedBox(width: 6),
                        OnoEmojiImage(emojiKey: solve.moodEmojiKey, size: 18),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  StandardText(
                    text: DateFormat('yyyy/MM/dd HH:mm')
                        .format(solve.practicedAt),
                    fontSize: 12,
                    color: Colors.grey[600]!,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 이미지 슬라이더 위젯
class _ImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final Color statusColor;
  final Color primaryColor;

  const _ImageSlider({
    required this.imageUrls,
    required this.statusColor,
    required this.primaryColor,
  });

  @override
  State<_ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<_ImageSlider> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        // PageView - 이미지 슬라이더
        Container(
          height: screenHeight * 0.3,
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: widget.primaryColor.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              return PressableScale(
                haptic: HapticLevel.none,
                onTap: () => Navigator.push(
                  context,
                  TossPageRoute(
                    builder: (_) => FullScreenImage(
                      imagePaths: widget.imageUrls,
                      initialIndex: i,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: DisplayImage(
                    imagePath: widget.imageUrls[i],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          // 도트 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _current == i ? 12 : 8,
                height: _current == i ? 12 : 8,
                decoration: BoxDecoration(
                  color: _current == i
                      ? widget.primaryColor
                      : widget.primaryColor.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
