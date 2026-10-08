import 'package:flutter/material.dart';

import '../../../../Model/LearningReport/LearningOverviewModel.dart';
import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Motion/AppHaptic.dart';
import '../../../../Module/Motion/AppMotion.dart';
import '../../../../Module/Motion/PressableScale.dart';
import '../../../../Module/Text/StandardText.dart';
import 'ReportPalette.dart';

/// 주간, 월간, 전체를 고르는 세그먼트다.
///
/// 미션 화면의 `MissionSegments` 와 같은 구조로, 흰 알약 하나가 옆으로
/// 미끄러진다. 칸마다 흰 바탕을 켜고 끄면 바뀌는 동안 두 칸이 다 회색으로
/// 보인다.
class ReportPeriodSegments extends StatelessWidget {
  final LearningOverviewPeriod selected;
  final ReportPalette palette;
  final ValueChanged<LearningOverviewPeriod> onChanged;

  const ReportPeriodSegments({
    super.key,
    required this.selected,
    required this.palette,
    required this.onChanged,
  });

  static const Map<LearningOverviewPeriod, String> labels = {
    LearningOverviewPeriod.week: '주간',
    LearningOverviewPeriod.month: '월간',
    LearningOverviewPeriod.total: '전체',
  };

  /// 미끄러지는 흰 알약을 테스트에서 찾는 키.
  static const Key pillKey = Key('report_segment_pill');

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    const periods = LearningOverviewPeriod.values;
    final index = periods.indexOf(selected);
    // 세 칸이라 왼쪽부터 -1, 0, 1 이다.
    final x = periods.length == 1 ? 0.0 : -1 + 2 * index / (periods.length - 1);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.track,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: reduced ? Duration.zero : AppMotion.normal,
              curve: AppMotion.emphasized,
              alignment: Alignment(x, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / periods.length,
                heightFactor: 1,
                child: Container(
                  key: pillKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final period in periods)
                Expanded(
                  child: PressableScale(
                    haptic: HapticLevel.none,
                    onTap: () {
                      if (period == selected) return;
                      AppHaptic.selection();
                      onChanged(period);
                    },
                    child: ConstrainedBox(
                      // 글자를 키운 기기에서는 늘어나야 해서 높이를 고정하지
                      // 않고 최소만 잡는다.
                      constraints: const BoxConstraints(minHeight: 36),
                      child: Center(
                        child: StandardText(
                          text: labels[period]!,
                          fontSize: 14,
                          height: 1.3,
                          color: period == selected
                              ? AppColors.textPrimary
                              : ReportPalette.textMuted,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
