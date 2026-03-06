import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ono/Model/LearningReport/LearningReportResponseModel.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Service/Api/LearningReport/LearningReportService.dart';
import 'package:provider/provider.dart';

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
              color: Colors.black87,
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
                color: Colors.black87,
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
          color: Colors.black87,
        ),
      );
    }

    final periodReport = _getCurrentPeriodReport();
    final comparison = _getCurrentComparison();
    final viewData = _ReportViewData.fromPeriod(periodReport);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        _buildSummaryCard(themeProvider, viewData, comparison),
        const SizedBox(height: 26),
        _buildPeriodSelector(themeProvider),
        const SizedBox(height: 30),
        _buildSectionTitle(themeProvider, '핵심 지표', Icons.auto_graph),
        const SizedBox(height: 14),
        _buildStatsGrid(themeProvider, viewData),
        const SizedBox(height: 20),
        _buildSectionTitle(
          themeProvider,
          '복습 추이',
          Icons.stacked_bar_chart_rounded,
        ),
        const SizedBox(height: 14),
        _buildTrendCard(themeProvider, viewData),
        const SizedBox(height: 40),
        _buildSectionTitle(
          themeProvider,
          '집중 복습 추천',
          Icons.edit_note_rounded,
        ),
        const SizedBox(height: 14),
        _buildWeakTopicCard(themeProvider, viewData),
        const SizedBox(height: 14),
        _buildActionCard(themeProvider),
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
        borderRadius: BorderRadius.circular(18),
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
                  borderRadius: BorderRadius.circular(999),
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
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontFamily: 'PretendardBold',
          ),
          const SizedBox(height: 6),
          StandardText(
            text: _buildSummarySubtitle(comparison),
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontFamily: 'PretendardLight',
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
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
      child: GestureDetector(
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
            borderRadius: BorderRadius.circular(10),
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: themeProvider.primaryColor),
        ),
        const SizedBox(width: 8),
        StandardText(
          text: title,
          fontSize: 17,
          color: Colors.black87,
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
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                themeProvider,
                '복습노트 열람',
                '${data.notePracticeCount}회',
                Icons.menu_book_rounded,
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
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                themeProvider,
                '평균 정답률',
                '${data.averageAccuracy.toStringAsFixed(1)}%',
                Icons.check_circle_outline,
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
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                themeProvider,
                '평균 학습 시간',
                '${data.averageStudyTimeMinutes.toStringAsFixed(1)}분',
                Icons.schedule,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeHandler themeProvider,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      height: 106,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StandardText(
                text: label,
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontFamily: 'PretendardBold',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(icon, size: 16, color: themeProvider.primaryColor),
            ],
          ),
          const Spacer(),
          StandardText(
            text: value,
            fontSize: 20,
            color: themeProvider.darkPrimaryColor,
            fontFamily: 'PretendardBold',
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(ThemeHandler themeProvider, _ReportViewData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                width: 16,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
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
                                      color: Colors.black87,
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
                          color: Colors.grey[700]!,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
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
                  borderRadius: BorderRadius.circular(10),
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
                        color: Colors.black87,
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

  Widget _buildActionCard(ThemeHandler themeProvider) {
    final actions = _report!.recommendations.actions;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              StandardText(
                text: '학습 가이드',
                fontSize: 15,
                color: Colors.black87,
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
                      color: Colors.black87,
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
