import 'package:flutter/material.dart';

import '../../../../Model/LearningReport/LearningOverviewModel.dart';
import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Motion/AnimatedGauge.dart';
import '../../../../Module/Motion/AppMotion.dart';
import '../../../../Module/Text/StandardText.dart';
import 'ReportCard.dart';
import 'ReportPalette.dart';
import 'ReportWording.dart';

/// 막대 그래프. 주간은 요일별, 월간은 주별, 전체는 최근 여섯 달의 월별이다.
///
/// 오늘이 들어 있는 칸은 진한 테마색으로 칠하고 아래에 알약을 단다. 아직
/// 오지 않은 칸은 숫자도 막대도 비워 둔다. 0 으로 그리면 그날 쉬었다는
/// 뜻으로 읽힌다.
class ReportTrendCard extends StatelessWidget {
  final List<LearningTrendBucket> trend;
  final ReportWording wording;
  final ReportPalette palette;
  final DateTime today;
  final Duration delay;

  const ReportTrendCard({
    super.key,
    required this.trend,
    required this.wording,
    required this.palette,
    required this.today,
    this.delay = Duration.zero,
  });

  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  bool _isFuture(LearningTrendBucket bucket) {
    final start = bucket.startDate;
    return start != null && start.isAfter(DateUtils.dateOnly(today));
  }

  bool _isToday(LearningTrendBucket bucket) {
    final start = bucket.startDate;
    final end = bucket.endDate ?? start;
    if (start == null || end == null) return false;
    final day = DateUtils.dateOnly(today);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  String _label(LearningTrendBucket bucket, int index) {
    final start = bucket.startDate;
    switch (wording.period) {
      case LearningOverviewPeriod.week:
        if (_isToday(bucket)) return '오늘';
        return start == null ? '' : _weekdays[start.weekday - 1];
      case LearningOverviewPeriod.month:
        return '${index + 1}주';
      case LearningOverviewPeriod.total:
        return start == null ? '' : '${start.month}월';
    }
  }

  /// 지난 칸만으로 낸 평균. 이번 주가 목요일까지면 넷으로 나눈다. 일곱으로
  /// 나누면 주 초반에는 늘 평균이 낮게 나온다.
  double get _average {
    final past = trend.where((b) => !_isFuture(b)).toList();
    if (past.isEmpty) return 0;
    final sum = past.fold<int>(0, (acc, b) => acc + b.reviewCount);
    return sum / past.length;
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = trend.fold<int>(
      1,
      (acc, b) => b.reviewCount > acc ? b.reviewCount : acc,
    );

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: ReportCardTitle(wording.trendTitle)),
              const SizedBox(width: 8),
              StandardText(
                text: '${wording.trendUnit} 평균 '
                    '${formatReportDecimal(_average)}문제',
                fontSize: 13,
                height: 1.3,
                fontFamily: 'PretendardLight',
                fontWeight: FontWeight.w300,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // 막대 높이는 카드 폭에 맞춘다. 고정값이면 태블릿에서 납작하고
              // 작은 폰에서는 길쭉하다.
              final barHeight =
                  (constraints.maxWidth * 0.32).clamp(80.0, 120.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < trend.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _Bar(
                        count: trend[i].reviewCount,
                        maxCount: maxCount,
                        label: _label(trend[i], i),
                        isFuture: _isFuture(trend[i]),
                        isToday: _isToday(trend[i]),
                        barHeight: barHeight,
                        palette: palette,
                        delay: delay + AppMotion.stagger * (2 + i),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int count;
  final int maxCount;
  final String label;
  final bool isFuture;
  final bool isToday;
  final double barHeight;
  final ReportPalette palette;
  final Duration delay;

  const _Bar({
    required this.count,
    required this.maxCount,
    required this.label,
    required this.isFuture,
    required this.isToday,
    required this.barHeight,
    required this.palette,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    // 0 인 날도 바닥에 조금은 보이게 한다. 아예 비우면 아직 오지 않은 날과
    // 구분되지 않는다.
    final fullHeight =
        isFuture ? 0.0 : (count / maxCount * barHeight).clamp(8.0, barHeight);

    return AnimatedGaugeValue(
      value: 1,
      delay: delay,
      builder: (context, progress) => Column(
        children: [
          Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: StandardText(
                // 빈 칸도 줄 높이는 차지해야 막대 윗선이 맞는다.
                text: isFuture ? ' ' : '$count',
                fontSize: 12,
                height: 1.3,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 28),
            child: Container(
              height: barHeight,
              width: double.infinity,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: palette.soft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                height: fullHeight * progress.clamp(0.0, 1.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isToday ? palette.deep : palette.base,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 알약은 글자 폭만큼만 칠한다. alignment 를 주면 칸 폭을 다 채운다.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isToday ? palette.deep : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: StandardText(
                text: label,
                fontSize: 12,
                height: 1.3,
                fontFamily: isToday ? 'PretendardBold' : 'PretendardLight',
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w300,
                color: isToday ? Colors.white : AppColors.textTertiary,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
