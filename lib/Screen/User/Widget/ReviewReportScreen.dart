import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ono/Model/LearningReport/LearningOverviewModel.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Provider/ReviewDueProvider.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/Folder/DirectoryScreen.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';
import 'package:ono/Screen/ProblemShare/AchievementCardScreen.dart';
import 'package:ono/Service/Api/LearningReport/LearningReportService.dart';
import 'package:ono/Util/AppAnalytics.dart';
import 'package:ono/Util/AppClock.dart';
import 'package:provider/provider.dart';

import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppLayout.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/AppearTransition.dart';
import '../../../Module/Motion/MotionReplayScope.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Motion/TossPageRoute.dart';
import '../../../Util/AppSnackBar.dart';
import 'LearningReport/NoteStatusCard.dart';
import 'LearningReport/ReportCard.dart';
import 'LearningReport/ReportPalette.dart';
import 'LearningReport/ReportPeriodSegments.dart';
import 'LearningReport/ReportSummaryCard.dart';
import 'LearningReport/ReportTrendCard.dart';
import 'LearningReport/ReportWording.dart';
import 'LearningReport/ReviewDueCard.dart';
import 'LearningReport/WeakFolderCard.dart';

/// 학습 보고서.
///
/// 위에서 아래로 "이번 기간에 얼마나 했고, 내 오답노트가 지금 어떤 상태이고,
/// 그래서 지금 무엇을 풀면 되는지"가 읽히게 다섯 칸을 둔다. 요약, 오답노트
/// 상태, 오늘 복습할 문제, 자주 틀린 폴더, 막대 그래프 순이다.
class ReviewReportScreen extends StatefulWidget {
  /// 테스트에서 가짜 서비스를 넣기 위한 것이다. 앱에서는 넘기지 않는다.
  final LearningReportService? reportService;

  const ReviewReportScreen({super.key, this.reportService});

  @override
  State<ReviewReportScreen> createState() => _ReviewReportScreenState();
}

class _ReviewReportScreenState extends State<ReviewReportScreen> {
  late final LearningReportService _reportService =
      widget.reportService ?? LearningReportService();

  LearningOverviewPeriod _period = LearningOverviewPeriod.week;

  /// 기간마다 보고 있는 날. null 이면 오늘이 들어 있는 기간이다. 주간에서
  /// 지난 주로 넘긴 뒤 월간을 봤다가 돌아와도 보던 주가 그대로 있게 한다.
  final Map<LearningOverviewPeriod, DateTime?> _baseDates = {};

  /// 받은 보고서. 탭을 오갈 때마다 다시 부르지 않는다. 당겨서 새로 고치거나
  /// 복습하고 돌아오면 비운다.
  final Map<String, LearningOverviewModel> _cache = {};

  /// 지금 받는 중인 보고서의 키.
  String? _loadingKey;
  bool _failed = false;

  /// 늦게 돌아온 응답이 그사이 바꾼 기간을 덮지 않게 요청마다 올린다.
  int _requestSerial = 0;

  /// 바뀔 때마다 숫자와 막대가 처음부터 다시 차오른다.
  int _replayToken = 0;

  bool _sharing = false;
  bool _startingReview = false;

  @override
  void initState() {
    super.initState();
    AppAnalytics.logScreenView('ReviewReportScreen');
    _load();
    // 첫 build 안에서 Provider 를 건드리면 build 중 알림 오류가 난다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReviewDueProvider>().fetchReviewDue();
    });
  }

  DateTime get _today => DateUtils.dateOnly(AppClock.now());

  /// [date] 가 들어 있는 주의 월요일이나 달의 1일.
  DateTime _periodStart(LearningOverviewPeriod period, DateTime date) {
    final day = DateUtils.dateOnly(date);
    switch (period) {
      case LearningOverviewPeriod.week:
        return _shiftDays(day, -(day.weekday - DateTime.monday));
      case LearningOverviewPeriod.month:
        return DateTime(day.year, day.month, 1);
      case LearningOverviewPeriod.total:
        return day;
    }
  }

  /// 기간과 그 첫날로 보고서를 구분한다.
  String _keyOf(LearningOverviewPeriod period, DateTime? baseDate) {
    if (period == LearningOverviewPeriod.total) return period.apiValue;
    final start = _periodStart(period, baseDate ?? _today);
    return '${period.apiValue}:${DateFormat('yyyy-MM-dd').format(start)}';
  }

  String get _currentKey => _keyOf(_period, _baseDates[_period]);

  LearningOverviewModel? get _overview => _cache[_currentKey];

  Future<void> _load({bool force = false}) async {
    final period = _period;
    final baseDate = _baseDates[period];
    final key = _keyOf(period, baseDate);

    if (!force && _cache.containsKey(key)) {
      // 다른 탭에서 받던 응답이 늦게 와도 지금 화면을 다시 그리지 않게 한다.
      // 받은 것은 그대로 기억해 둔다.
      _requestSerial++;
      setState(() {
        _loadingKey = null;
        _failed = false;
        _replayToken++;
      });
      return;
    }

    final serial = ++_requestSerial;
    setState(() {
      _loadingKey = key;
      _failed = false;
    });

    try {
      final overview = await _reportService.getOverview(
        period: period,
        baseDate: baseDate,
      );
      if (!mounted) return;
      // 늦게 온 응답은 비어 있는 자리만 채운다. 그사이 새로 고친 값이 있으면
      // 그게 더 최신이라 덮지 않는다.
      if (serial == _requestSerial || !_cache.containsKey(key)) {
        _cache[key] = overview;
      }
      if (serial != _requestSerial) return;
      setState(() {
        _loadingKey = null;
        _replayToken++;
      });
    } catch (_) {
      if (!mounted || serial != _requestSerial) return;
      // 받아 둔 것을 그대로 보여 주는 중이면 실패를 알리지 않으면 새로 고친
      // 줄 안다.
      if (_cache.containsKey(key)) {
        AppSnackBar.showError('보고서를 새로 불러오지 못했어요.');
      }
      setState(() {
        _loadingKey = null;
        _failed = true;
      });
    }
  }

  void _selectPeriod(LearningOverviewPeriod period) {
    if (period == _period) return;
    AppAnalytics.logEvent(
      'report_period_view',
      {'period': period.analyticsValue},
    );
    _period = period;
    _load();
  }

  /// 이전, 다음 기간으로 넘긴다. 그 기간 안의 아무 날이나 보내면 서버가 그
  /// 주나 달을 준다.
  void _move({required bool forward}) {
    final overview = _overview;
    if (overview == null) return;
    final DateTime? target = forward
        ? (overview.endDate == null ? null : _shiftDays(overview.endDate!, 1))
        : (overview.startDate == null
            ? null
            : _shiftDays(overview.startDate!, -1));
    if (target == null) return;

    AppAnalytics.logEvent('report_period_move', {
      'period': _period.analyticsValue,
      'choice': forward ? 'next' : 'previous',
    });

    // 오늘이 들어 있는 기간으로 돌아오면 날짜 없이 부른다. 서버의 오늘(KST)
    // 기준으로 받아야 기기 시간대가 달라도 이번 주가 어긋나지 않는다.
    final isCurrent =
        _periodStart(_period, target) == _periodStart(_period, _today);
    _baseDates[_period] = isCurrent ? null : target;
    _load();
  }

  /// 받아 둔 보고서를 버리고 다시 받는다. 보고 있는 기간은 새 응답이 올
  /// 때까지 그대로 둔다. 같이 비우면 새로 고치는 동안 화면이 로딩으로 바뀐다.
  Future<void> _refresh() async {
    final shown = _cache[_currentKey];
    _cache.clear();
    if (shown != null) _cache[_currentKey] = shown;
    await Future.wait([
      _load(force: true),
      context.read<ReviewDueProvider>().fetchReviewDue(),
    ]);
  }

  /// 추천 복습 화면의 시작 버튼과 같은 순서로 연다. 복습하고 돌아오면 숫자가
  /// 바뀌었으니 보고서와 오늘 복습할 문제를 다시 받는다.
  Future<void> _startReview(List<int> queue) async {
    // 빠르게 두 번 누르면 문제 화면이 두 번 쌓인다.
    if (queue.isEmpty || _startingReview) return;
    _startingReview = true;
    AppAnalytics.logEvent('review_due_start', {
      'count': queue.length,
      'source': 'report',
    });
    try {
      await Navigator.push(
        context,
        TossPageRoute(
          builder: (_) => ProblemDetailScreen(
            problemId: queue.first,
            reviewQueue: queue,
          ),
        ),
      );
    } finally {
      _startingReview = false;
    }
    if (!mounted) return;
    _refresh();
  }

  void _openFolder(LearningWeakFolder folder, int rank) {
    AppAnalytics.logEvent('report_folder_tap', {'rank': rank});
    Navigator.push(
      context,
      TossPageRoute(builder: (_) => DirectoryScreen(folderId: folder.folderId)),
    );
  }

  /// 공유 카드는 예전 보고서의 주간 값을 그린다. 화면을 열 때마다 부르지
  /// 않고 공유를 누를 때 한 번만 받는다.
  Future<void> _share() async {
    if (_sharing) return;
    final userInfo = context.read<UserProvider>().userInfoModel;
    if (userInfo == null) {
      AppSnackBar.showError('사용자 정보를 불러올 수 없어요.');
      return;
    }
    setState(() => _sharing = true);
    try {
      final report = await _reportService.getLearningReport();
      if (!mounted) return;
      await Navigator.push(
        context,
        TossPageRoute(
          builder: (_) => AchievementCardScreen(
            userInfo: userInfo,
            weeklyReport: report.weekly,
          ),
        ),
      );
    } catch (_) {
      AppSnackBar.showError('공유할 보고서를 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeHandler>();
    final palette = ReportPalette.of(themeProvider.primaryColor);
    final overview = _overview;
    final isEmpty = overview != null && overview.summary.reviewCount == 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: DefaultTextStyle.merge(
          style: reportTabularFigures,
          child: AppContentWidth(
            child: Column(
              children: [
                _buildHeader(
                  showShare: !isEmpty,
                  titleColor: themeProvider.primaryColor,
                ),
                AppearTransition(
                  child: ReportPeriodSegments(
                    selected: _period,
                    palette: palette,
                    onChanged: _selectPeriod,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: palette.deep,
                    onRefresh: _refresh,
                    child: MotionReplayScope(
                      token: _replayToken,
                      child: SingleChildScrollView(
                        // 내용이 짧아도 당겨서 새로 고칠 수 있게 한다.
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 32),
                        child: _buildBody(palette, overview),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 뒤로 가기, 가운데 제목, 공유. 제목은 마이페이지처럼 테마색으로 쓴다.
  Widget _buildHeader({required bool showShare, required Color titleColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: '뒤로 가기',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: StandardText(
              text: '학습 보고서',
              fontSize: 18,
              height: 1.3,
              color: titleColor,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          if (!showShare)
            // 공유 버튼이 없어도 제목이 가운데에 오게 같은 폭을 비워 둔다.
            const SizedBox(width: 48)
          else
            _sharing
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: '공유하기',
                    onPressed: _share,
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildBody(ReportPalette palette, LearningOverviewModel? overview) {
    if (overview == null) {
      if (_failed && _loadingKey == null) return _buildError();
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: palette.deep,
            ),
          ),
        ),
      );
    }

    final wording = ReportWording.of(overview);
    final reviewDue = context.watch<ReviewDueProvider>();
    final dueData = reviewDue.data;
    final queue = dueData?.problems.map((p) => p.problemId).toList() ?? [];
    final dueCount = dueData?.dueCount;
    final canStartReview = (dueCount ?? 0) > 0 && queue.isNotEmpty;
    final isEmpty = overview.summary.reviewCount == 0;

    final cards = <(String, Widget Function(Duration delay))>[
      (
        'summary',
        (delay) => ReportSummaryCard(
              overview: overview,
              wording: wording,
              palette: palette,
              dueCount: dueCount,
              onStartReview: canStartReview ? () => _startReview(queue) : null,
              onPrevious: () => _move(forward: false),
              onNext: () => _move(forward: true),
              today: _today,
              delay: delay,
            )
      ),
      (
        'status',
        (delay) => NoteStatusCard(
              status: overview.noteStatus,
              wording: wording,
              palette: palette,
              delay: delay,
            )
      ),
      // 기록이 없는 지금 기간에는 요약 카드에 같은 버튼이 이미 있다.
      if (canStartReview && !(isEmpty && wording.isCurrent))
        (
          'due',
          (_) => ReviewDueCard(
                dueCount: dueCount!,
                oldestNextReviewAt: dueData!.problems.first.nextReviewAt,
                today: _today,
                palette: palette,
                onStart: () => _startReview(queue),
              )
        ),
      if (!isEmpty && overview.weakFolders.isNotEmpty)
        (
          'folders',
          (delay) => WeakFolderCard(
                folders: overview.weakFolders,
                palette: palette,
                onTap: _openFolder,
                delay: delay,
              )
        ),
      if (!isEmpty && overview.trend.isNotEmpty)
        (
          'trend',
          (delay) => ReportTrendCard(
                trend: overview.trend,
                wording: wording,
                palette: palette,
                today: _today,
                delay: delay,
              )
        ),
      if (isEmpty && overview.hasPrevious && !wording.isTotal)
        (
          'previous',
          (_) => _PreviousReportRow(
                overview: overview,
                wording: wording,
                onTap: () => _move(forward: false),
              )
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const ReportSectionGap(),
          // 칸은 머리와 탭 뒤로 하나씩 들어온다.
          // 오늘 복습할 문제 카드가 생기거나 빠질 때 아래 카드가 새로 만들어져
          // 차오름이 다시 돌지 않게 카드마다 key 를 준다.
          AppearTransition(
            key: ValueKey(cards[i].$1),
            delay: AppMotion.stagger * 2 * (i + 1),
            child: cards[i].$2(AppMotion.stagger * 2 * (i + 1)),
          ),
        ],
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          const StandardText(
            text: '보고서를 불러오지 못했어요',
            fontSize: 15,
            height: 1.4,
            color: AppColors.textPrimary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const StandardText(
            text: '잠시 뒤에 다시 시도해 주세요',
            fontSize: 13,
            height: 1.4,
            fontFamily: 'PretendardLight',
            fontWeight: FontWeight.w300,
            color: ReportPalette.textMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PressableScale(
            onTap: () => _load(force: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(ReportPalette.buttonRadius),
              ),
              child: const StandardText(
                text: '다시 시도',
                fontSize: 14,
                height: 1.3,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 기록이 없는 기간의 맨 아래 줄. 앞 기간으로 넘긴다.
class _PreviousReportRow extends StatelessWidget {
  final LearningOverviewModel overview;
  final ReportWording wording;
  final VoidCallback onTap;

  const _PreviousReportRow({
    required this.overview,
    required this.wording,
    required this.onTap,
  });

  /// 앞 기간의 날짜. 주는 7일 앞, 달은 앞 달 1일부터 말일까지다.
  (DateTime, DateTime)? get _previousRange {
    final start = overview.startDate;
    if (start == null) return null;
    if (wording.period == LearningOverviewPeriod.month) {
      return (
        DateTime(start.year, start.month - 1, 1),
        DateTime(start.year, start.month, 0),
      );
    }
    return (
      _shiftDays(start, -7),
      _shiftDays(start, -1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _previousRange;
    final previous = overview.previous;
    final parts = [
      if (range != null) formatReportRange(range.$1, range.$2),
      // 지금 기간의 비교 값은 오늘까지와 같은 날 수만 센 것이라 앞 기간
      // 전체 수가 아니다. 지난 기간을 보고 있을 때만 앞 기간 전체와 비교한다.
      if (!wording.isCurrent && previous != null)
        '${previous.reviewCount}문제 복습',
    ];

    return PressableScale(
      onTap: onTap,
      child: ReportCard(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportTracking(
                    letterSpacing: -0.2,
                    child: StandardText(
                      text: wording.previousReportLabel,
                      fontSize: 15,
                      height: 1.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (parts.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    StandardText(
                      text: parts.join(' · '),
                      fontSize: 13,
                      height: 1.3,
                      fontFamily: 'PretendardLight',
                      fontWeight: FontWeight.w300,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

/// 날짜를 달력 기준으로 며칠 옮긴다.
///
/// `Duration(days: 1)` 은 24시간이라 서머타임이 끝나는 25시간짜리 날에는 같은
/// 날에 머문다. 그러면 다음 주 화살표가 같은 주를 다시 부른다.
DateTime _shiftDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);
