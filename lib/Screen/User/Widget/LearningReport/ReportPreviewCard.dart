import 'package:flutter/material.dart';

import '../../../../Model/LearningReport/LearningOverviewModel.dart';
import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Design/AppRadius.dart';
import '../../../../Module/Motion/AnimatedGauge.dart';
import '../../../../Module/Motion/AppMotion.dart';
import '../../../../Module/Motion/Skeleton.dart';
import '../../../../Module/Text/StandardText.dart';
import '../../../../Service/Api/LearningReport/LearningReportService.dart';
import '../../../../Util/AppClock.dart';

/// 마이페이지의 학습 보고서 카드 안쪽. 이번 주에 몇 문제를 복습했는지와
/// 요일 막대만 보여 준다.
///
/// 예전에는 흐리게 가린 가짜 막대를 두었는데, 보고서를 열어 보기 전에는 내
/// 기록인지 아닌지 알 수 없었다. 바로 위 학습 달력 카드와 같은 머리, 같은
/// 옅은 패널을 쓴다. 숫자와 날짜를 더 넣었더니 글자가 많고 그 카드와 따로
/// 놀았다. 카드 테두리와 누르는 동작은 마이페이지가 감싼다.
class ReportPreviewCard extends StatefulWidget {
  final Color primaryColor;

  /// 바뀌면 다시 받는다. 마이페이지 탭에 들어올 때마다 올린다.
  final int refreshToken;

  /// 테스트에서 가짜 서비스를 넣기 위한 것이다. 앱에서는 넘기지 않는다.
  final LearningReportService? reportService;

  const ReportPreviewCard({
    super.key,
    required this.primaryColor,
    this.refreshToken = 0,
    this.reportService,
  });

  @override
  State<ReportPreviewCard> createState() => ReportPreviewCardState();
}

class ReportPreviewCardState extends State<ReportPreviewCard> {
  late final LearningReportService _reportService =
      widget.reportService ?? LearningReportService();

  LearningOverviewModel? _overview;
  bool _loading = true;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(covariant ReportPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) reload();
  }

  /// 이번 주 보고서를 다시 받는다. 실패하면 받아 둔 것을 그대로 둔다.
  Future<void> reload() async {
    final serial = ++_requestSerial;
    try {
      final overview = await _reportService.getOverview(
        period: LearningOverviewPeriod.week,
        showErrorSnackBar: false,
      );
      if (!mounted || serial != _requestSerial) return;
      setState(() {
        _overview = overview;
        _loading = false;
      });
    } catch (_) {
      // 마이페이지 카드라 실패를 알리지 않는다. 눌러서 보고서를 열면 거기서
      // 다시 받는다.
      if (mounted && serial == _requestSerial) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor;
    final overview = _overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(primary),
        const SizedBox(height: 14),
        if (overview == null && _loading)
          const SkeletonBox(height: 104, borderRadius: 16)
        else
          _buildPanel(primary, overview),
      ],
    );
  }

  /// 아이콘 칩 + `학습 보고서` + `>`. 바로 위 학습 달력 카드의 머리와 같다.
  Widget _buildHeader(Color primary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Icon(Icons.bar_chart_rounded, color: primary, size: 16),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: StandardText(
            text: '학습 보고서',
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
      ],
    );
  }

  /// 학습 달력의 옅은 패널과 같은 판. 위에 `이번 주 복습 8문제`, 아래에 요일
  /// 일곱 막대를 둔다. 받지 못했으면 막대 자리만 비워 둔다.
  Widget _buildPanel(Color primary, LearningOverviewModel? overview) {
    final count = overview?.summary.reviewCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: StandardText(
                  text: '이번 주 복습',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              StandardText(
                text: count == null ? '-' : '$count문제',
                fontSize: 14,
                color: primary,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WeekBars(trend: overview?.trend ?? const [], primary: primary),
        ],
      ),
    );
  }
}

/// 월요일부터 일요일까지 일곱 막대. 학습 달력의 점 줄처럼 요일 글자를 위에
/// 두고, 오늘 막대만 테마색을 진하게 칠한다.
class _WeekBars extends StatelessWidget {
  final List<LearningTrendBucket> trend;
  final Color primary;

  const _WeekBars({required this.trend, required this.primary});

  static const List<String> _labels = ['월', '화', '수', '목', '금', '토', '일'];
  static const double _height = 36;
  static const double _width = 10;

  bool _isToday(LearningTrendBucket bucket) {
    final start = bucket.startDate;
    final end = bucket.endDate ?? start;
    if (start == null || end == null) return false;
    final day = DateUtils.dateOnly(AppClock.now());
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = trend.fold<int>(
        0, (max, b) => b.reviewCount > max ? b.reviewCount : max);

    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StandardText(
                    text: _labels[i],
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    height: 1.3,
                  ),
                  const SizedBox(height: 6),
                  _bar(i < trend.length ? trend[i] : null, maxCount, i),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(LearningTrendBucket? bucket, int maxCount, int index) {
    final count = bucket?.reviewCount ?? 0;
    final full = maxCount == 0 || count == 0
        ? 0.0
        : (_height * count / maxCount).clamp(5.0, _height);
    final isToday = bucket != null && _isToday(bucket);

    return Container(
      width: _width,
      height: _height,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(_width / 2),
      ),
      child: AnimatedGaugeValue(
        // 값이 바뀌면 그 자리에서 다시 자란다.
        key: ValueKey(full),
        value: 1,
        delay: AppMotion.stagger * index,
        builder: (context, progress) => Container(
          width: _width,
          height: full * progress.clamp(0.0, 1.0),
          decoration: BoxDecoration(
            color: isToday ? primary : primary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(_width / 2),
          ),
        ),
      ),
    );
  }
}
