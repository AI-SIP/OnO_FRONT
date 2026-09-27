import 'package:flutter/material.dart';

import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Text/StandardText.dart';

/// 일일과 주간을 고르는 세그먼트다.
///
/// **흰 알약은 하나뿐이고, 그것이 좌우로 미끄러진다.** 전에는 칸 두 개가 각자
/// 흰 배경을 켜고 끄면서 바뀌었는데, 그 사이 180ms 동안 한쪽은 아직 흐려지는
/// 중이고 다른 쪽은 아직 밝아지는 중이라 **둘 다 회색으로 보였다.** 알약이
/// 하나면 어느 순간에도 선택된 칸이 비어 있지 않다.
class MissionSegments extends StatelessWidget {
  /// 지금 고른 칸. 0 이면 일일, 1 이면 주간.
  final int index;

  final Color color;
  final ValueChanged<int> onChanged;

  const MissionSegments({
    super.key,
    required this.index,
    required this.color,
    required this.onChanged,
  });

  static const List<String> labels = ['일일', '주간'];

  /// 미끄러지는 흰 알약을 테스트에서 찾는 키.
  static const Key pillKey = Key('mission_segment_pill');

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Stack(
        children: [
          // 알약이 먼저 깔리고 글자가 그 위에 얹힌다.
          Positioned.fill(
            child: AnimatedAlign(
              duration: reduced ? Duration.zero : AppMotion.normal,
              curve: AppMotion.emphasized,
              alignment:
                  index == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                child: Container(
                  key: pillKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.16),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: PressableScale(
                    onTap: () {
                      if (index == i) return;
                      AppHaptic.selection();
                      onChanged(i);
                    },
                    haptic: HapticLevel.none,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: StandardText(
                        text: labels[i],
                        fontSize: 14,
                        color: index == i ? color : AppColors.textTertiary,
                        textAlign: TextAlign.center,
                        maxLines: 1,
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
