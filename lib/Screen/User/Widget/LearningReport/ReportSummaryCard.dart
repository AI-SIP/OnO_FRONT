import 'package:flutter/material.dart';

import '../../../../Model/LearningReport/LearningOverviewModel.dart';
import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Motion/AnimatedCountText.dart';
import '../../../../Module/Motion/AppMotion.dart';
import '../../../../Module/Motion/AppearTransition.dart';
import '../../../../Module/Text/StandardText.dart';
import 'ReportCard.dart';
import 'ReportPalette.dart';
import 'ReportWording.dart';

/// 맨 위 요약 카드. 이 기간에 몇 문제를 복습했는지와 정답률, 공부한 날,
/// 연속 공부를 보여 준다.
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
    this.delay = Duration.zero,
  });

  bool get isEmpty => overview.summary.reviewCount == 0;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRangeRow(),
          if (isEmpty) ..._buildEmpty() else ..._buildFilled(),
        ],
      ),
    );
  }

  Widget _buildRangeRow() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Row(
        children: [
          Expanded(
            child: StandardText(
              text: formatReportRange(overview.startDate, overview.endDate),
              fontSize: 13,
              height: 1.3,
              fontFamily: 'PretendardLight',
              fontWeight: FontWeight.w300,
              color: ReportPalette.textMuted,
            ),
          ),
          // 전체는 넘겨 볼 기간이 없다.
          if (!wording.isTotal)
            // 화살표 칸의 빈 여백만큼 오른쪽으로 붙여 카드 안쪽 선과 맞춘다.
            Transform.translate(
              offset: const Offset(10, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _arrow(
                    icon: Icons.chevron_left_rounded,
                    tooltip: wording.previousTooltip,
                    onPressed: overview.hasPrevious ? onPrevious : null,
                  ),
                  _arrow(
                    icon: Icons.chevron_right_rounded,
                    tooltip: wording.nextTooltip,
                    onPressed: overview.hasNext ? onNext : null,
                  ),
                ],
              ),
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
      color: ReportPalette.textMuted,
      disabledColor: ReportPalette.gray,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  List<Widget> _buildFilled() {
    final summary = overview.summary;
    final previous = wording.isTotal ? null : overview.previous;

    return [
      const SizedBox(height: 10),
      StandardText(
        text: wording.reviewLabel,
        fontSize: 15,
        height: 1.3,
        fontFamily: 'PretendardLight',
        fontWeight: FontWeight.w300,
        color: AppColors.textSecondary,
      ),
      const SizedBox(height: 2),
      // 네 자리 넘는 수를 큰 글자로 키우면 작은 폰에서 카드 폭을 넘는다.
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            ConstrainedBox(
              // 숫자가 0 부터 올라가는 동안 옆의 `문제` 가 덜 흔들리게 자리를
              // 잡아 둔다. 세 자리가 넘으면 그만큼 늘어난다.
              constraints: const BoxConstraints(minWidth: 64),
              child: ReportTracking(
                letterSpacing: -2,
                child: AnimatedCountText(
                  value: summary.reviewCount,
                  fontSize: 56,
                  height: 1.1,
                  color: AppColors.textPrimary,
                  delay: delay + AppMotion.stagger * 2,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const ReportTracking(
              letterSpacing: -0.4,
              child: StandardText(
                text: '문제',
                fontSize: 22,
                height: 1.1,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      if (previous != null && previous.reviewCount > 0)
        AppearTransition(
          delay: delay + AppMotion.stagger * 11,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _DeltaPill(
              current: summary.reviewCount,
              previous: previous.reviewCount,
              wording: wording,
            ),
          ),
        ),
      const SizedBox(height: 20),
      const Divider(height: 1, thickness: 1, color: ReportPalette.divider),
      const SizedBox(height: 16),
      // 값 줄이 글자 기준선으로 맞춰져 있어 IntrinsicHeight 를 쓸 수 없다. 세
      // 칸 모두 이름 한 줄과 값 한 줄이라 높이가 같게 나온다.
      Row(
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
    ];
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
          ? const BoxDecoration(
              border: Border(
                left: BorderSide(color: ReportPalette.divider),
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
  static _Change? _accuracyChange(double? current, double? previous) {
    if (current == null || previous == null) return null;
    return _countChange((current - previous).round(), '%p');
  }

  /// 늘었으면 초록 `+1일`, 줄었으면 빨강 `-1일`, 같으면 쓰지 않는다.
  static _Change? _countChange(int diff, String unit) {
    if (diff == 0) return null;
    return _Change(
      diff > 0 ? '+$diff$unit' : '$diff$unit',
      diff > 0 ? ReportPalette.greenText : ReportPalette.redInk,
    );
  }

  List<Widget> _buildEmpty() {
    final due = dueCount;
    // 지난 기간에는 지금 할 일을 붙이지 않는다. 그 주를 돌아보는 중이다.
    final showDue = wording.isCurrent && due != null;

    return [
      const SizedBox(height: 10),
      ReportTracking(
        letterSpacing: -0.6,
        child: StandardText(
          text: wording.emptyTitle,
          fontSize: 24,
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
            child: ReportPrimaryButton(label: '복습하기', onTap: onStartReview!),
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

/// `지난주보다 5문제 더 풀었어요` 알약. 늘면 초록, 줄면 빨강, 같으면 회색.
class _DeltaPill extends StatelessWidget {
  final int current;
  final int previous;
  final ReportWording wording;

  const _DeltaPill({
    required this.current,
    required this.previous,
    required this.wording,
  });

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    final String text;
    final Color ink;
    final Color bg;
    final IconData? icon;
    if (diff > 0) {
      text = '${wording.previousPeriod}보다 $diff문제 더 풀었어요';
      ink = ReportPalette.greenInk;
      bg = ReportPalette.greenBg;
      icon = Icons.arrow_upward_rounded;
    } else if (diff < 0) {
      text = '${wording.previousPeriod}보다 ${-diff}문제 덜 풀었어요';
      ink = ReportPalette.redInk;
      bg = ReportPalette.redBg;
      icon = Icons.arrow_downward_rounded;
    } else {
      text = '${wording.withPreviousPeriod} 같아요';
      ink = AppColors.textSecondary;
      bg = AppColors.surfaceMuted;
      icon = null;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 10 : 8, 6, 10, 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: ink),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: StandardText(
              text: text,
              fontSize: 13,
              height: 1.3,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}
