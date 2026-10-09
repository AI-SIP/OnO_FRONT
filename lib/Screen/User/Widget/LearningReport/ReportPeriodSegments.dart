import 'package:flutter/material.dart';

import '../../../../Model/LearningReport/LearningOverviewModel.dart';
import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Motion/AppHaptic.dart';
import '../../../../Module/Motion/AppMotion.dart';
import '../../../../Module/Motion/PressableScale.dart';
import '../../../../Module/Text/StandardText.dart';
import 'ReportPalette.dart';

/// 주간, 월간, 전체를 고르는 밑줄 탭이다.
///
/// 회색 트랙 위에 흰 알약을 미끄러뜨리던 모양은 설정 화면 스위치처럼 보여서
/// 테마색 밑줄 하나가 옆으로 미끄러지게 바꿨다. 칸마다 밑줄을 켜고 끄면
/// 바뀌는 동안 두 칸에 다 줄이 없어 보인다.
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

  /// 미끄러지는 밑줄을 테스트에서 찾는 키.
  static const Key indicatorKey = Key('report_segment_indicator');

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    const periods = LearningOverviewPeriod.values;
    final index = periods.indexOf(selected);
    // 세 칸이라 왼쪽부터 -1, 0, 1 이다.
    final x = periods.length == 1 ? 0.0 : -1 + 2 * index / (periods.length - 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: ReportPalette.divider)),
      ),
      child: Stack(
        children: [
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
                      constraints: const BoxConstraints(minHeight: 46),
                      child: Center(
                        child: StandardText(
                          text: labels[period]!,
                          fontSize: 15,
                          height: 1.3,
                          color: period == selected
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 2,
            child: AnimatedAlign(
              duration: reduced ? Duration.zero : AppMotion.normal,
              curve: AppMotion.emphasized,
              alignment: Alignment(x, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / periods.length,
                heightFactor: 1,
                child: DecoratedBox(
                  key: indicatorKey,
                  decoration: BoxDecoration(
                    color: palette.deep,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
