import 'package:flutter/material.dart';

import '../../../../Model/LearningReport/LearningOverviewModel.dart';
import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Design/AppRadius.dart';
import '../../../../Module/Motion/AnimatedCountText.dart';
import '../../../../Module/Motion/AnimatedGauge.dart';
import '../../../../Module/Motion/AppMotion.dart';
import '../../../../Module/Motion/Skeleton.dart';
import '../../../../Module/Text/StandardText.dart';
import '../../../../Service/Api/LearningReport/LearningReportService.dart';
import '../../../../Util/AppClock.dart';
import 'ReportPalette.dart';

/// 마이페이지의 학습 보고서 카드 안쪽. 이번 주에 몇 문제를 복습했는지,
/// 지난주와 견주면 어떤지, 요일 막대를 보여 준다.
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
          const SkeletonBox(height: 98, borderRadius: 16)
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

  /// 학습 달력의 옅은 패널과 같은 판. 왼쪽에 이번 주 복습 수를 크게, 오른쪽에
  /// 요일 막대를 둔다. 숫자와 막대를 위아래로 쌓았을 때는 막대 바탕만 줄지어
  /// 보여서 밋밋했다. 받지 못했으면 숫자 자리에 `-` 를 둔다.
  Widget _buildPanel(Color primary, LearningOverviewModel? overview) {
    final palette = ReportPalette.of(primary);
    final count = overview?.summary.reviewCount;
    final change = _changeText(overview);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StandardText(
                  text: '이번 주 복습',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (count == null)
                      StandardText(
                        text: '-',
                        fontSize: 30,
                        color: palette.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      )
                    else
                      AnimatedCountText(
                        value: count,
                        fontSize: 30,
                        color: palette.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    const SizedBox(width: 3),
                    const StandardText(
                      text: '문제',
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.15,
                    ),
                  ],
                ),
                if (change != null) ...[
                  const SizedBox(height: 6),
                  StandardText(
                    text: change.$1,
                    fontSize: 12,
                    color: change.$2 ? palette.ink : AppColors.textTertiary,
                    height: 1.3,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: _WeekBars(
              trend: overview?.trend ?? const [],
              primary: primary,
            ),
          ),
        ],
      ),
    );
  }

  /// `지난주보다 3문제 더` 처럼 지난주와 견준 한 줄. 늘었으면 테마색, 아니면
  /// 회색이다. 지난주 기록이 없으면 비교할 게 없어서 쓰지 않는다.
  (String, bool)? _changeText(LearningOverviewModel? overview) {
    final previous = overview?.previous;
    if (overview == null || previous == null) return null;
    final diff = overview.summary.reviewCount - previous.reviewCount;
    if (diff > 0) return ('지난주보다 $diff문제 더', true);
    if (diff < 0) return ('지난주보다 ${-diff}문제 덜', false);
    if (previous.reviewCount == 0) return null;
    return ('지난주만큼 했어요', false);
  }
}

/// 월요일부터 일요일까지 일곱 막대. 바탕 트랙 없이 바닥선에서 자라고, 안 한
/// 날은 작은 점만 찍는다. 오늘은 막대와 요일 글자를 테마색으로 진하게 칠한다.
class _WeekBars extends StatelessWidget {
  final List<LearningTrendBucket> trend;
  final Color primary;

  const _WeekBars({required this.trend, required this.primary});

  static const List<String> _labels = ['월', '화', '수', '목', '금', '토', '일'];
  static const double _height = 48;
  static const double _width = 12;

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
              child: _column(
                i < trend.length ? trend[i] : null,
                maxCount,
                i,
              ),
            ),
        ],
      ),
    );
  }

  Widget _column(LearningTrendBucket? bucket, int maxCount, int index) {
    final count = bucket?.reviewCount ?? 0;
    final isToday = bucket != null && _isToday(bucket);
    final full = maxCount == 0 || count == 0
        ? 0.0
        : (_height * count / maxCount).clamp(6.0, _height);
    final barColor = isToday ? primary : primary.withValues(alpha: 0.4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _height,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: count == 0
                ? Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: isToday
                          ? primary
                          : AppColors.textTertiary.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  )
                : AnimatedGaugeValue(
                    // 값이 바뀌면 그 자리에서 다시 자란다.
                    key: ValueKey(full),
                    value: 1,
                    delay: AppMotion.stagger * index,
                    builder: (context, progress) => Container(
                      width: _width,
                      height: full * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(_width / 2),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        StandardText(
          text: _labels[index],
          fontSize: 11,
          color: isToday ? primary : AppColors.textTertiary,
          height: 1.3,
        ),
      ],
    );
  }
}
