import 'package:flutter/material.dart';

import '../../../../Model/LearningReport/LearningOverviewModel.dart';
import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Motion/AnimatedCountText.dart';
import '../../../../Module/Motion/AnimatedGauge.dart';
import '../../../../Module/Motion/AppMotion.dart';
import '../../../../Module/Motion/AppearTransition.dart';
import '../../../../Module/Text/StandardText.dart';
import 'ReportCard.dart';
import 'ReportPalette.dart';
import 'ReportWording.dart';

/// 맨 위 요약. 날짜를 넘기는 줄 아래에 `이번 주에 14문제 복습했어요` 를 큰
/// 문장으로 쓰고, 옆에 기간 막대를 작게 두고, 정답률, 공부한 날, 연속 공부를
/// 옅은 테마색 칸에 모은다.
///
/// 기록이 없는 기간이면 숫자 대신 `이번 주는 아직 복습을 안 했어요` 로 바뀌고,
/// 오늘 복습할 문제가 있으면 바로 시작할 버튼을 단다.
class ReportSummaryCard extends StatelessWidget {
  final LearningOverviewModel overview;
  final ReportWording wording;
  final ReportPalette palette;

  /// 오늘 복습할 문제 수. 아직 못 받았으면 null 이다.
  final int? dueCount;

  /// 기록이 없을 때 보이는 `복습하기`. null 이면 버튼을 두지 않는다.
  final VoidCallback? onStartReview;

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// 오늘이 들어 있는 막대를 진하게 칠하는 데 쓴다.
  final DateTime today;

  /// 카드가 나타나기 시작하는 때. 안쪽 항목은 이 뒤로 차례로 들어온다.
  final Duration delay;

  const ReportSummaryCard({
    super.key,
    required this.overview,
    required this.wording,
    required this.palette,
    required this.dueCount,
    required this.onStartReview,
    required this.onPrevious,
    required this.onNext,
    required this.today,
    this.delay = Duration.zero,
  });

  /// 문장 옆 작은 막대는 이 수까지만 그린다. 전체 기간은 달이 많아 최근 것만
  /// 남긴다.
  static const int miniBarLimit = 7;

  bool get isEmpty => overview.summary.reviewCount == 0;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRangeRow(),
          if (isEmpty) ..._buildEmpty() else ..._buildFilled(),
        ],
      ),
    );
  }

  /// `‹ 10월 5일 ~ 10월 11일 ›`. 가운데에 두고 화살표를 양옆에 붙인다.
  Widget _buildRangeRow() {
    final range = StandardText(
      text: formatReportRange(overview.startDate, overview.endDate),
      fontSize: 15,
      height: 1.3,
      color: AppColors.textPrimary,
      textAlign: TextAlign.center,
      maxLines: 1,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 전체는 넘겨 볼 기간이 없다.
          if (!wording.isTotal)
            _arrow(
              icon: Icons.chevron_left_rounded,
              tooltip: wording.previousTooltip,
              onPressed: overview.hasPrevious ? onPrevious : null,
            ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(fit: BoxFit.scaleDown, child: range),
            ),
          ),
          if (!wording.isTotal)
            _arrow(
              icon: Icons.chevron_right_rounded,
              tooltip: wording.nextTooltip,
              onPressed: overview.hasNext ? onNext : null,
            ),
        ],
      ),
    );
  }

  Widget _arrow({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 22,
      color: AppColors.textSecondary,
      disabledColor: ReportPalette.gray,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  List<Widget> _buildFilled() {
    final summary = overview.summary;
    final previous = wording.isTotal ? null : overview.previous;
    final bars = overview.trend.length > miniBarLimit
        ? overview.trend.sublist(overview.trend.length - miniBarLimit)
        : overview.trend;

    return [
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildSentence(summary.reviewCount)),
          if (bars.isNotEmpty) ...[
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MiniBars(
                trend: bars,
                today: today,
                palette: palette,
                delay: delay + AppMotion.stagger * 4,
              ),
            ),
          ],
        ],
      ),
      if (previous != null && previous.reviewCount > 0)
        AppearTransition(
          delay: delay + AppMotion.stagger * 11,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _DeltaLine(
              current: summary.reviewCount,
              previous: previous.reviewCount,
              wording: wording,
              palette: palette,
            ),
          ),
        ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: palette.page,
          borderRadius: BorderRadius.circular(18),
        ),
        // 값 줄이 글자 기준선으로 맞춰져 있어 IntrinsicHeight 를 쓸 수 없다.
        // 세 칸 모두 이름 한 줄과 값 한 줄이라 높이가 같게 나온다.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AppearTransition.stagger(
            [
              _stat(
                label: '정답률',
                value: summary.accuracy == null
                    ? '-'
                    : '${summary.accuracy!.round()}%',
                change: _accuracyChange(summary.accuracy, previous?.accuracy),
              ),
              _stat(
                label: '공부한 날',
                value: '${summary.studyDays}일',
                change: previous == null
                    ? null
                    : _countChange(summary.studyDays - previous.studyDays, '일'),
                divided: true,
              ),
              // 연속 공부는 기간과 상관없는 값이라 비교하지 않는다.
              _stat(
                label: '연속 공부',
                value: '${summary.currentStreak}일째',
                divided: true,
              ),
            ],
            initialDelay: delay + AppMotion.stagger * 5,
          ).map((child) => Expanded(child: child)).toList(),
        ),
      ),
    ];
  }

  /// `이번 주에` / `14문제 복습했어요` 두 줄. 숫자만 테마색으로 칠하고 0 부터
  /// 올라간다. 읽어 주기는 한 문장으로 묶는다.
  Widget _buildSentence(int count) {
    const size = 26.0;
    return Semantics(
      label: '${wording.inThisPeriod} $count문제 복습했어요',
      excludeSemantics: true,
      child: ReportTracking(
        letterSpacing: -0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StandardText(
              text: wording.inThisPeriod,
              fontSize: size,
              height: 1.35,
              color: AppColors.textPrimary,
            ),
            // 네 자리 넘는 수나 큰 글자에서 한 줄을 넘지 않게 줄인다.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedCountText(
                    value: count,
                    fontSize: size,
                    height: 1.35,
                    color: palette.ink,
                    delay: delay + AppMotion.stagger * 2,
                  ),
                  StandardText(
                    text: '문제',
                    fontSize: size,
                    height: 1.35,
                    color: palette.ink,
                  ),
                  const StandardText(
                    text: ' 복습했어요',
                    fontSize: size,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat({
    required String label,
    required String value,
    _Change? change,
    bool divided = false,
  }) {
    return Container(
      padding: EdgeInsets.only(left: divided ? 16 : 0),
      decoration: divided
          ? BoxDecoration(
              border: Border(
                left: BorderSide(color: palette.line),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StandardText(
            text: label,
            fontSize: 13,
            height: 1.3,
            fontFamily: 'PretendardLight',
            fontWeight: FontWeight.w300,
            color: ReportPalette.textMuted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // 세 칸이 폭을 나눠 쓰는데 글자를 키운 기기에서는 값과 변화가 한 줄에
          // 안 들어간다. 줄을 바꾸면 칸 높이가 들쭉날쭉해져서 줄인다.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                ReportTracking(
                  letterSpacing: -0.4,
                  child: StandardText(
                    text: value,
                    fontSize: 19,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (change != null) ...[
                  const SizedBox(width: 5),
                  StandardText(
                    text: change.text,
                    fontSize: 12,
                    height: 1.3,
                    color: change.color,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `+8%p`. 둘 중 하나라도 채점 기록이 없으면 비교하지 않는다.
  _Change? _accuracyChange(double? current, double? previous) {
    if (current == null || previous == null) return null;
    return _countChange((current - previous).round(), '%p');
  }

  /// 늘었으면 테마색 `+1일`, 줄었으면 회색 `-1일`, 같으면 쓰지 않는다.
  ///
  /// 옅은 테마색 칸 안이라 초록과 빨강을 섞으면 분홍이나 파랑 테마에서 색이
  /// 서로 부딪쳤다.
  _Change? _countChange(int diff, String unit) {
    if (diff == 0) return null;
    return _Change(
      diff > 0 ? '+$diff$unit' : '$diff$unit',
      diff > 0 ? palette.ink : AppColors.textTertiary,
    );
  }

  List<Widget> _buildEmpty() {
    final due = dueCount;
    // 지난 기간에는 지금 할 일을 붙이지 않는다. 그 주를 돌아보는 중이다.
    final showDue = wording.isCurrent && due != null;

    return [
      const SizedBox(height: 14),
      ReportTracking(
        letterSpacing: -0.7,
        child: StandardText(
          text: wording.emptyTitle,
          fontSize: 26,
          height: 1.35,
          color: AppColors.textPrimary,
        ),
      ),
      if (showDue) ...[
        const SizedBox(height: 8),
        if (due > 0)
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '오늘 복습할 문제가 '),
                TextSpan(
                  text: '$due개',
                  style: TextStyle(
                    fontFamily: 'PretendardBold',
                    fontWeight: FontWeight.w700,
                    color: palette.deep,
                  ),
                ),
                const TextSpan(text: ' 있어요'),
              ],
            ),
            style: _emptyBodyStyle,
          )
        else
          const Text('오늘 복습할 문제는 없어요', style: _emptyBodyStyle),
      ],
      if (showDue && due > 0 && onStartReview != null)
        AppearTransition(
          delay: delay + AppMotion.stagger * 4,
          child: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: ReportPrimaryButton(
              label: '복습하기',
              color: palette.base,
              onTap: onStartReview!,
            ),
          ),
        ),
    ];
  }

  static const TextStyle _emptyBodyStyle = TextStyle(
    fontFamily: 'PretendardLight',
    fontWeight: FontWeight.w300,
    fontSize: 14,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}

class _Change {
  final String text;
  final Color color;

  const _Change(this.text, this.color);
}

/// `지난주보다 5문제 더 풀었어요`. 늘면 테마색, 줄거나 같으면 회색이다.
/// 바로 위 문장의 문제 수와 같은 색을 써서 한 덩어리로 읽힌다.
///
/// 알약으로 감싸면 흰 화면에서 버튼처럼 보여서 글자와 화살표만 둔다.
class _DeltaLine extends StatelessWidget {
  final int current;
  final int previous;
  final ReportWording wording;
  final ReportPalette palette;

  const _DeltaLine({
    required this.current,
    required this.previous,
    required this.wording,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    final String text;
    final Color ink;
    final IconData? icon;
    if (diff > 0) {
      text = '${wording.previousPeriod}보다 $diff문제 더 풀었어요';
      ink = palette.ink;
      icon = Icons.arrow_upward_rounded;
    } else if (diff < 0) {
      text = '${wording.previousPeriod}보다 ${-diff}문제 덜 풀었어요';
      ink = AppColors.textTertiary;
      icon = Icons.arrow_downward_rounded;
    } else {
      text = '${wording.withPreviousPeriod} 같아요';
      ink = AppColors.textSecondary;
      icon = null;
    }

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: ink),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: StandardText(
            text: text,
            fontSize: 14,
            height: 1.3,
            color: ink,
          ),
        ),
      ],
    );
  }
}

/// 문장 옆의 작은 막대. 아래 막대 칸을 줄여 놓은 것이라 숫자와 이름은 없다.
class _MiniBars extends StatelessWidget {
  final List<LearningTrendBucket> trend;
  final DateTime today;
  final ReportPalette palette;
  final Duration delay;

  const _MiniBars({
    required this.trend,
    required this.today,
    required this.palette,
    required this.delay,
  });

  static const double _height = 36;
  static const double _width = 7;

  bool _isToday(LearningTrendBucket bucket) {
    final start = bucket.startDate;
    final end = bucket.endDate ?? start;
    if (start == null || end == null) return false;
    final day = DateUtils.dateOnly(today);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = trend.fold<int>(
        0, (max, b) => b.reviewCount > max ? b.reviewCount : max);

    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < trend.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            AnimatedGaugeValue(
              value: 1,
              delay: delay + AppMotion.stagger * i,
              builder: (context, progress) {
                final count = trend[i].reviewCount;
                final full = maxCount == 0 || count == 0
                    ? 0.0
                    : (_height * count / maxCount).clamp(4.0, _height);
                return Container(
                  width: _width,
                  height: _height,
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(
                    color: palette.soft,
                    borderRadius: BorderRadius.circular(_width / 2),
                  ),
                  child: Container(
                    width: _width,
                    height: full * progress.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: _isToday(trend[i]) ? palette.deep : palette.base,
                      borderRadius: BorderRadius.circular(_width / 2),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
