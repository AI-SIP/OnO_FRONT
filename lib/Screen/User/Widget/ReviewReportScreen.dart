import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ono/Model/LearningReport/LearningReportResponseModel.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/ProblemShare/AchievementCardScreen.dart';
import 'package:ono/Service/Api/LearningReport/LearningReportService.dart';
import 'package:provider/provider.dart';
import '../../../Util/AppSnackBar.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Motion/TossPageRoute.dart';
import '../../../Module/Motion/AnimatedGauge.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/AppearTransition.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';

enum ReportPeriod { weekly, monthly, total }

class ReviewReportScreen extends StatefulWidget {
  const ReviewReportScreen({super.key});

  @override
  State<ReviewReportScreen> createState() => _ReviewReportScreenState();
}

class _ReviewReportScreenState extends State<ReviewReportScreen> {
  final LearningReportService _reportService = LearningReportService();

  ReportPeriod _selectedPeriod = ReportPeriod.weekly;
  LearningReportResponseModel? _report;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport({DateTime? baseDate}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await _reportService.getLearningReport(baseDate: baseDate);
      if (!mounted) return;
      setState(() {
        _report = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '학습 리포트를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.userInfoModel?.name ?? '사용자';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: '$userName님의 학습 리포트',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: _report != null
                  ? themeProvider.primaryColor
                  : Colors.grey[300],
            ),
            onPressed:
                _report != null ? () => _navigateToShareCard(context) : null,
          ),
        ],
      ),
      body: _buildBody(themeProvider),
    );
  }

  Widget _buildBody(ThemeHandler themeProvider) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/Icon/GlassDetail.svg',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 12),
            const StandardText(
              text: '리포트 분석 중...',
              fontSize: 17,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFamily: 'PretendardBold',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StandardText(
                text: _errorMessage!,
                fontSize: 14,
                color: AppColors.textPrimary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                ),
                child: const StandardText(
                  text: '다시 시도',
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_report == null) {
      return const Center(
        child: StandardText(
          text: '표시할 리포트가 없습니다.',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      );
    }

    final periodReport = _getCurrentPeriodReport();
    final comparison = _getCurrentComparison();
    final viewData = _ReportViewData.fromPeriod(periodReport);

    // 위에서부터 한 덩어리씩 들어오게 한다. 숫자와 그래프가 많은 화면이라
    // 한꺼번에 나타나면 어디를 봐야 할지 알기 어렵다.
    var step = 0;
    Widget appear(Widget child) => AppearTransition(
          delay: AppMotion.stagger * (step++),
          child: child,
        );

    return ListView(
      // 화면 밖 카드를 미리 만들어 두면 스크롤해서 닿기도 전에 막대가 다
      // 자라 버린다. 도달할 때 만들어지도록 미리 만드는 범위를 없앤다.
      // 카드가 열 개 남짓이라 이렇게 해도 스크롤이 무거워지지 않는다.
      cacheExtent: 0,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        appear(_buildSummaryCard(themeProvider, viewData, comparison)),
        const SizedBox(height: 26),
        appear(_buildPeriodSelector(themeProvider)),
        const SizedBox(height: 30),
        appear(_buildSectionTitle(themeProvider, '핵심 지표', Icons.auto_graph)),
        const SizedBox(height: 14),
        appear(_buildStatsGrid(themeProvider, viewData)),
        const SizedBox(height: 20),
        appear(_buildSectionTitle(
          themeProvider,
          '복습 횟수 추이',
          Icons.stacked_bar_chart_rounded,
        )),
        const SizedBox(height: 14),
        appear(_buildTrendCard(themeProvider, viewData)),
        const SizedBox(height: 40),
        appear(_buildSectionTitle(
          themeProvider,
          '집중 복습 추천',
          Icons.edit_note_rounded,
        )),
        const SizedBox(height: 14),
        appear(_buildWeakTopicCard(themeProvider, viewData)),
        const SizedBox(height: 14),
        appear(_buildActionCard(themeProvider)),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.grey,
              ),
              SizedBox(width: 6),
              StandardText(
                text: '학습 리포트는 매일 자정 갱신됩니다.',
                fontSize: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  LearningPeriodReport _getCurrentPeriodReport() {
    switch (_selectedPeriod) {
      case ReportPeriod.weekly:
        return _report!.weekly;
      case ReportPeriod.monthly:
        return _report!.monthly;
      case ReportPeriod.total:
        return _report!.total;
    }
  }

  LearningReportComparison? _getCurrentComparison() {
    switch (_selectedPeriod) {
      case ReportPeriod.weekly:
        return _report!.weeklyComparison;
      case ReportPeriod.monthly:
        return _report!.monthlyComparison;
      case ReportPeriod.total:
        return null;
    }
  }

  Widget _buildSummaryCard(
    ThemeHandler themeProvider,
    _ReportViewData data,
    LearningReportComparison? comparison,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: StandardText(
                  text: data.badge,
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'PretendardBold',
                ),
              ),
              const Spacer(),
              Icon(
                Icons.insights_rounded,
                color: themeProvider.primaryColor,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 10),
          StandardText(
            text: data.title,
            fontSize: 18,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontFamily: 'PretendardBold',
          ),
          const SizedBox(height: 6),
          StandardText(
            text: _buildSummarySubtitle(comparison),
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontFamily: 'PretendardLight',
          ),
          const SizedBox(height: AppSpacing.lg),
          // 이 기간을 한 줄로 요약한다. 아래 카드를 다 읽지 않아도
          // 무엇을 얼마나 했는지 먼저 눈에 들어오게 한다.
          Row(
            children: [
              _buildSummaryFigure(
                  '작성', '${data.noteWriteCount}', themeProvider),
              _buildSummaryDivider(),
              _buildSummaryFigure('복습', '${data.reviewCount}', themeProvider),
              _buildSummaryDivider(),
              _buildSummaryFigure(
                '정답률',
                '${data.averageAccuracy.toStringAsFixed(0)}%',
                themeProvider,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 요약 카드 안에 나란히 놓는 수치 하나.
  Widget _buildSummaryFigure(
      String label, String value, ThemeHandler themeProvider) {
    return Expanded(
      child: Column(
        children: [
          StandardText(
            text: value,
            fontSize: 20,
            color: themeProvider.primaryColor,
            fontFamily: 'PretendardBold',
          ),
          const SizedBox(height: 2),
          StandardText(
            text: label,
            fontSize: 11,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
    );
  }

  String _buildSummarySubtitle(LearningReportComparison? comparison) {
    if (comparison == null) {
      if (_report!.recommendations.nextWeekGoal.isNotEmpty) {
        return _report!.recommendations.nextWeekGoal;
      }
      return _report!.recommendations.strengths.isNotEmpty
          ? _report!.recommendations.strengths.first
          : '학습 리포트를 확인해 주세요.';
    }

    final reviewText =
        _buildChangeSentence('복습 횟수', comparison.reviewCountChangeRate);
    final accuracyText =
        _buildChangeSentence('정답률', comparison.averageAccuracyChangeRate);
    final tone = _buildComparisonTone(
      comparison.reviewCountChangeRate,
      comparison.averageAccuracyChangeRate,
    );
    return '이전 기간보다 $reviewText, $accuracyText. $tone';
  }

  String _buildChangeSentence(String subject, double value) {
    final subjectWithParticle = _withSubjectParticle(subject);
    final rate = _formatPercent(value.abs());
    if (value > 0) {
      return '$subjectWithParticle $rate% 상승했어요';
    }
    if (value < 0) {
      return '$subjectWithParticle $rate% 하락했어요';
    }
    return '$subjectWithParticle 변화가 없어요';
  }

  String _buildComparisonTone(double reviewRate, double accuracyRate) {
    if (reviewRate >= 0 && accuracyRate >= 0) {
      return '학습 흐름이 좋아지고 있어요.';
    }
    if (reviewRate < 0 && accuracyRate < 0) {
      return '복습 리듬을 다시 잡아보면 좋아요.';
    }
    return '현재 추이를 유지하면서 약한 부분을 보완해보세요.';
  }

  String _withSubjectParticle(String word) {
    if (word.isEmpty) return word;
    final lastCode = word.runes.last;
    if (lastCode < 0xAC00 || lastCode > 0xD7A3) {
      return '$word가';
    }
    final hasBatchim = ((lastCode - 0xAC00) % 28) != 0;
    return '$word${hasBatchim ? '이' : '가'}';
  }

  String _formatPercent(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  Widget _buildPeriodSelector(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildPeriodChip(themeProvider, ReportPeriod.weekly, '주간'),
          _buildPeriodChip(themeProvider, ReportPeriod.monthly, '월간'),
          _buildPeriodChip(themeProvider, ReportPeriod.total, '누적'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(
    ThemeHandler themeProvider,
    ReportPeriod period,
    String label,
  ) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: PressableScale(
        haptic: HapticLevel.selection,
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? themeProvider.primaryColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: isSelected
                ? Border.all(color: themeProvider.primaryColor, width: 1)
                : null,
          ),
          child: Center(
            child: StandardText(
              text: label,
              fontSize: 13,
              color:
                  isSelected ? themeProvider.darkPrimaryColor : Colors.black87,
              fontWeight: FontWeight.w800,
              fontFamily: 'PretendardBold',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    ThemeHandler themeProvider,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Icon(icon, size: 17, color: themeProvider.primaryColor),
        ),
        const SizedBox(width: AppSpacing.md),
        StandardText(
          text: title,
          fontSize: 17,
          color: AppColors.textPrimary,
          fontFamily: 'PretendardBold',
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ThemeHandler themeProvider, _ReportViewData data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                themeProvider,
                '작성한 오답 노트',
                '${data.noteWriteCount}개',
                Icons.edit_note_rounded,
                const Color(0xFF9B7EDE),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                themeProvider,
                '복습 세트 열람',
                '${data.notePracticeCount}회',
                Icons.menu_book_rounded,
                const Color(0xFF4A90D9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                themeProvider,
                '오답노트 복습',
                '${data.reviewCount}회',
                Icons.repeat,
                const Color(0xFF3DBE8B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                themeProvider,
                '평균 정답률',
                '${data.averageAccuracy.toStringAsFixed(1)}%',
                Icons.check_circle_outline,
                const Color(0xFF2FA97C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                themeProvider,
                '연속 학습일',
                '${data.consecutiveLearningDays}일',
                Icons.local_fire_department_outlined,
                const Color(0xFFF2764B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                themeProvider,
                '평균 학습 시간',
                '${data.averageStudyTimeMinutes.toStringAsFixed(1)}분',
                Icons.schedule,
                const Color(0xFFE0736F),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// "12개", "0.0%", "3.5분" 처럼 숫자 뒤에 단위가 붙은 값을 갈라 그린다.
  ///
  /// 통째로 키우면 글자가 커서 부담스럽고, 통째로 줄이면 무엇이 중요한 값인지
  /// 안 보인다. 숫자만 키우고 단위는 작고 옅게 두면 시선이 숫자에 먼저 간다.
  Widget _buildStatValue(String value) {
    final match = RegExp(r'^([\d.,]+)(.*)$').firstMatch(value);
    final number = match?.group(1) ?? value;
    final unit = match?.group(2) ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        StandardText(
          text: number,
          fontSize: 22,
          color: AppColors.textPrimary,
          fontFamily: 'PretendardBold',
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 2),
          StandardText(
            text: unit,
            fontSize: 13,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    ThemeHandler themeProvider,
    String label,
    String value,
    IconData icon,
    Color accent,
  ) {
    return Container(
      height: 104,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘을 맨몸으로 두면 존재감이 없다. 지표마다 다른 색을 옅게 깔되,
          // 라벨과 같은 줄에 둔다. 세로로 쌓으면 카드 높이를 넘긴다.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StandardText(
                  text: label,
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'PretendardBold',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildStatValue(value),
        ],
      ),
    );
  }

  Widget _buildTrendCard(ThemeHandler themeProvider, _ReportViewData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: SizedBox(
        height: 134,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(data.trendBars.length, (index) {
            final isPeak = data.trendBars[index] ==
                data.trendBars.reduce((a, b) => a > b ? a : b);
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const labelHeight = 14.0;
                        const gap = 4.0;
                        const minBarHeight = 4.0;
                        final usableBarHeight =
                            (constraints.maxHeight - labelHeight - gap)
                                .clamp(0.0, constraints.maxHeight);

                        final rawBarHeight =
                            usableBarHeight * data.trendBars[index];
                        final barHeight = rawBarHeight < minBarHeight
                            ? minBarHeight
                            : (rawBarHeight > usableBarHeight
                                ? usableBarHeight
                                : rawBarHeight);

                        final numberBottom = barHeight + gap;

                        return Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomCenter,
                              // 0 에서 제 높이까지 자라난다. 값이 바뀌면 그때
                              // 있던 높이에서 이어서 움직인다.
                              child: AnimatedGaugeValue(
                                value: barHeight,
                                duration: AppMotion.gauge,
                                delay: AppMotion.stagger * index,
                                builder: (context, grown) => Container(
                                  width: 16,
                                  height: grown,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.small),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        themeProvider.primaryColor,
                                        themeProvider.lightPrimaryColor,
                                      ],
                                    ),
                                    boxShadow: isPeak
                                        ? [
                                            BoxShadow(
                                              color: themeProvider.primaryColor
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: numberBottom,
                              child: Center(
                                child: SizedBox(
                                  height: labelHeight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: StandardText(
                                      text: data.trendCounts[index].toString(),
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'PretendardBold',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 16,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StandardText(
                          text: data.trendLabels[index],
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'PretendardBold',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWeakTopicCard(ThemeHandler themeProvider, _ReportViewData data) {
    final items = data.weakAreas.isEmpty
        ? ['현재 취약 영역 데이터가 없습니다.']
        : data.weakAreas
            .map((e) => '${e.topic} (오답 ${e.wrongCount}회)')
            .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (topic) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  color: themeProvider.primaryColor.withValues(alpha: 0.08),
                  border: Border.all(
                    color: themeProvider.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_right_alt_rounded,
                      size: 18,
                      color: themeProvider.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: StandardText(
                        text: topic,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'PretendardBold',
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _navigateToShareCard(BuildContext context) {
    final userInfo =
        Provider.of<UserProvider>(context, listen: false).userInfoModel;
    if (userInfo == null) {
      AppSnackBar.showError('사용자 정보를 불러올 수 없어요.');
      return;
    }
    Navigator.push(
      context,
      TossPageRoute(
        builder: (_) => AchievementCardScreen(
          userInfo: userInfo,
          weeklyReport: _report!.weekly,
        ),
      ),
    );
  }

  Widget _buildActionCard(ThemeHandler themeProvider) {
    final actions = _report!.recommendations.actions;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              StandardText(
                text: '학습 가이드',
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontFamily: 'PretendardBold',
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StandardText(
                      text: action,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'PretendardLight',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportViewData {
  final String badge;
  final String title;
  final int noteWriteCount;
  final int notePracticeCount;
  final int reviewCount;
  final double averageAccuracy;
  final int consecutiveLearningDays;
  final double averageStudyTimeMinutes;
  final List<double> trendBars;
  final List<int> trendCounts;
  final List<String> trendLabels;
  final List<LearningWeakArea> weakAreas;

  const _ReportViewData({
    required this.badge,
    required this.title,
    required this.noteWriteCount,
    required this.notePracticeCount,
    required this.reviewCount,
    required this.averageAccuracy,
    required this.consecutiveLearningDays,
    required this.averageStudyTimeMinutes,
    required this.trendBars,
    required this.trendCounts,
    required this.trendLabels,
    required this.weakAreas,
  });

  factory _ReportViewData.fromPeriod(LearningPeriodReport report) {
    final maxReview = report.trend.isEmpty
        ? 1
        : report.trend
            .map((e) => e.reviewCount)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 1 << 30);

    final bars = report.trend
        .map((e) => e.reviewCount == 0 ? 0.06 : e.reviewCount / maxReview)
        .toList();
    final counts = report.trend.map((e) => e.reviewCount).toList();

    final labels = report.trend
        .map((e) => _formatTrendLabel(e.label, report.periodLabel))
        .toList();

    return _ReportViewData(
      badge: report.periodLabel,
      title: _buildTitle(report),
      noteWriteCount: report.noteWriteCount,
      notePracticeCount: report.notePracticeCount,
      reviewCount: report.reviewCount,
      averageAccuracy: report.averageAccuracy,
      consecutiveLearningDays: report.consecutiveLearningDays,
      averageStudyTimeMinutes: report.averageStudyTimeMinutes,
      trendBars: bars,
      trendCounts: counts,
      trendLabels: labels,
      weakAreas: report.weakAreas,
    );
  }

  static String _buildTitle(LearningPeriodReport report) {
    final end = report.endDate != null
        ? DateFormat('yyyy.MM.dd').format(report.endDate!)
        : '';

    if (report.startDate != null) {
      final start = DateFormat('yyyy.MM.dd').format(report.startDate!);
      return '$start ~ $end 리포트';
    }

    if (end.isNotEmpty) {
      return '누적 리포트';
    }

    return '학습 리포트';
  }

  static String _formatTrendLabel(String raw, String periodLabel) {
    // 월간은 서버가 '1주차/2주차' 같은 표시용 라벨을 내려주므로 그대로 사용
    if (periodLabel == 'MONTHLY') {
      return raw;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      // 일 단위 데이터
      if (raw.length == 10) {
        return '${parsed.month}/${parsed.day}';
      }
      return DateFormat('M월').format(parsed);
    }

    // yyyy-MM 형태 처리
    final ym = RegExp(r'^\\d{4}-\\d{2}$');
    if (ym.hasMatch(raw)) {
      final month = int.tryParse(raw.split('-')[1]);
      if (month != null) {
        return '$month월';
      }
    }

    return raw;
  }
}
