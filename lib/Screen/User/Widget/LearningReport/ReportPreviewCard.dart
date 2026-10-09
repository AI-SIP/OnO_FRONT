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
import 'ReportPalette.dart';

/// 마이페이지의 학습 보고서 카드 안쪽. 이번 주에 몇 문제를 복습했는지 한
/// 문장과 요일 막대, 보고서로 가는 줄을 둔다.
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
    final palette = ReportPalette.of(primary);
    final overview = _overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(primary),
        const SizedBox(height: 14),
        if (overview == null && _loading)
          const SkeletonBox(height: 124, borderRadius: 16)
        else
          _buildPanel(primary, palette, overview),
        const SizedBox(height: 4),
        _buildOpenRow(palette),
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

  /// 학습 달력의 옅은 패널과 같은 판. 위에 보고서 첫머리와 같은 문장, 아래에
  /// 달력의 요일 줄처럼 일곱 막대를 둔다.
  ///
  /// 큰 숫자와 지난주 비교, 막대를 좌우로 나눴을 때는 굵기와 색이 제각각이라
  /// 촌스러웠다. 문장 하나와 막대 한 줄로 줄이고 숫자만 테마색으로 둔다.
  Widget _buildPanel(
    Color primary,
    ReportPalette palette,
    LearningOverviewModel? overview,
  ) {
    final count = overview?.summary.reviewCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSentence(palette, count),
          const SizedBox(height: 14),
          _WeekBars(trend: overview?.trend ?? const [], primary: primary),
        ],
      ),
    );
  }

  /// `이번 주 8문제 복습했어요`. 받지 못했으면 숫자 없이 둔다.
  Widget _buildSentence(ReportPalette palette, int? count) {
    const style = TextStyle(
      fontFamily: 'PretendardBold',
      fontSize: 15,
      height: 1.3,
      color: AppColors.textPrimary,
    );
    if (count == null) {
      return const Text('이번 주 복습 기록', style: style);
    }
    if (count == 0) {
      return const Text('이번 주는 아직 복습 전이에요', style: style);
    }
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: '이번 주 '),
          TextSpan(
            text: '$count문제',
            style: TextStyle(color: palette.ink),
          ),
          const TextSpan(text: ' 복습했어요'),
        ],
      ),
      style: style,
    );
  }

  /// 판 아래 `이번 주 보고서 보기 >`. 학습 달력의 `한 달 보기` 와 같은 자리,
  /// 같은 크기다. 다른 화면으로 가는 줄이라 회색 대신 테마색으로 둔다. 누르는
  /// 동작은 카드 전체를 감싼 마이페이지 쪽이 받는다.
  Widget _buildOpenRow(ReportPalette palette) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StandardText(
            text: '이번 주 보고서 보기',
            fontSize: 13,
            color: palette.ink,
          ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 18, color: palette.ink),
        ],
      ),
    );
  }
}

/// 월요일부터 일요일까지 일곱 칸. 학습 달력의 요일 줄처럼 글자를 위에 두고
/// 아래에 막대를 세운다. 안 한 날은 낮은 회색 막대, 오늘은 글자와 막대를
/// 테마색으로 진하게 칠한다.
class _WeekBars extends StatelessWidget {
  final List<LearningTrendBucket> trend;
  final Color primary;

  const _WeekBars({required this.trend, required this.primary});

  static const List<String> _labels = ['월', '화', '수', '목', '금', '토', '일'];
  static const double _height = 40;
  static const double _width = 14;
  static const double _stub = 4;

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
        ? _stub
        : (_height * count / maxCount).clamp(8.0, _height);
    final Color color;
    if (count == 0) {
      color = AppColors.textTertiary.withValues(alpha: 0.18);
    } else {
      color = isToday ? primary : primary.withValues(alpha: 0.45);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StandardText(
          text: _labels[index],
          fontSize: 11,
          color: isToday ? primary : AppColors.textTertiary,
          height: 1.3,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _height,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedGaugeValue(
              // 값이 바뀌면 그 자리에서 다시 자란다.
              key: ValueKey(full),
              value: 1,
              delay: AppMotion.stagger * index,
              builder: (context, progress) => Container(
                width: _width,
                height: (full * progress.clamp(0.0, 1.0)).clamp(_stub, _height),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(_stub),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
