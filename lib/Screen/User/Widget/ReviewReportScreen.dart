import 'package:flutter/material.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:provider/provider.dart';

enum ReportPeriod { weekly, monthly, total }

class ReviewReportScreen extends StatefulWidget {
  const ReviewReportScreen({super.key});

  @override
  State<ReviewReportScreen> createState() => _ReviewReportScreenState();
}

class _ReviewReportScreenState extends State<ReviewReportScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.weekly;

  final Map<ReportPeriod, _ReportData> _mockData = {
    ReportPeriod.weekly: const _ReportData(
      badge: 'WEEKLY',
      title: '2월 4주차 복습 리포트',
      subtitle: '지난주 대비 복습 빈도 +12%, 정답률 +5%',
      solvedCount: '18',
      accuracy: '74%',
      streak: '5',
      avgDuration: '23분',
      bars: [0.32, 0.58, 0.46, 0.68, 0.82, 0.64, 0.51],
      labels: ['월', '화', '수', '목', '금', '토', '일'],
      weakTopics: ['미적분 - 함수 극한', '확률과 통계 - 조건부확률', '기하 - 벡터 연산'],
    ),
    ReportPeriod.monthly: const _ReportData(
      badge: 'MONTHLY',
      title: '2월 월간 복습 리포트',
      subtitle: '월 목표 달성률 83%, 루틴 안정화 단계',
      solvedCount: '76',
      accuracy: '71%',
      streak: '12',
      avgDuration: '27분',
      bars: [0.48, 0.52, 0.63, 0.78],
      labels: ['1주', '2주', '3주', '4주'],
      weakTopics: ['수열 - 귀납적 추론', '기하 - 공간도형', '함수 - 역함수/합성함수'],
    ),
    ReportPeriod.total: const _ReportData(
      badge: 'TOTAL',
      title: '누적 학습 리포트',
      subtitle: '누적 기준 복습 유지율이 꾸준히 상승 중',
      solvedCount: '241',
      accuracy: '69%',
      streak: '19',
      avgDuration: '29분',
      bars: [0.35, 0.42, 0.5, 0.57, 0.64, 0.71],
      labels: ['1개월', '2개월', '3개월', '4개월', '5개월', '6개월+'],
      weakTopics: ['미적분 - 도함수 활용', '확률 - 독립시행', '기하 - 벡터의 내적'],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final data = _mockData[_selectedPeriod]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: '복습 리포트',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          _buildSummaryCard(themeProvider, data),
          const SizedBox(height: 26),
          _buildPeriodSelector(themeProvider),
          const SizedBox(height: 30),
          _buildSectionTitle(themeProvider, '핵심 지표', Icons.auto_graph),
          const SizedBox(height: 14),
          _buildStatsGrid(themeProvider, data),
          const SizedBox(height: 20),
          _buildSectionTitle(
            themeProvider,
            '복습 추이',
            Icons.stacked_bar_chart_rounded,
          ),
          const SizedBox(height: 14),
          _buildTrendCard(themeProvider, data),
          const SizedBox(height: 40),
          _buildSectionTitle(
            themeProvider,
            '집중 복습 추천',
            Icons.edit_note_rounded,
          ),
          const SizedBox(height: 14),
          _buildWeakTopicCard(themeProvider, data),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeHandler themeProvider, _ReportData data) {
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
            fontSize: 19,
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontFamily: 'PretendardBold',
          ),
          const SizedBox(height: 6),
          StandardText(
            text: data.subtitle,
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontFamily: 'PretendardLight',
          ),
        ],
      ),
    );
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

  Widget _buildStatsGrid(ThemeHandler themeProvider, _ReportData data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.48,
      children: [
        _buildStatCard(
            themeProvider, '복습 횟수', '${data.solvedCount}회', Icons.repeat),
        _buildStatCard(
            themeProvider, '평균 정답률', data.accuracy, Icons.check_circle_outline),
        _buildStatCard(themeProvider, '연속 학습일', '${data.streak}일',
            Icons.local_fire_department_outlined),
        _buildStatCard(
            themeProvider, '평균 학습 시간', data.avgDuration, Icons.schedule),
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

  Widget _buildTrendCard(ThemeHandler themeProvider, _ReportData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(data.bars.length, (index) {
            final isPeak =
                data.bars[index] == data.bars.reduce((a, b) => a > b ? a : b);
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    height: 86 * data.bars[index],
                    width: 16,
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
                  const SizedBox(height: 8),
                  StandardText(
                    text: data.labels[index],
                    fontSize: 11,
                    color: Colors.grey[700]!,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'PretendardBold',
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWeakTopicCard(ThemeHandler themeProvider, _ReportData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.weakTopics
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
}

class _ReportData {
  final String badge;
  final String title;
  final String subtitle;
  final String solvedCount;
  final String accuracy;
  final String streak;
  final String avgDuration;
  final List<double> bars;
  final List<String> labels;
  final List<String> weakTopics;

  const _ReportData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.solvedCount,
    required this.accuracy,
    required this.streak,
    required this.avgDuration,
    required this.bars,
    required this.labels,
    required this.weakTopics,
  });
}
