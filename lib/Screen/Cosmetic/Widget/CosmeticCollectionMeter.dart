import 'package:flutter/material.dart';

import '../../../Module/Design/AppColors.dart';
import '../../../Module/Motion/AnimatedCountText.dart';
import '../../../Module/Motion/AnimatedGauge.dart';
import '../../../Module/Text/StandardText.dart';

/// 옷장 전체를 얼마나 모았는지 알려 주는 줄이다.
///
/// 마흔 가지 중 스물넷이 잠겨 있다. 잠긴 칸만 흑백으로 죽여 두면 "못 쓰는
/// 것들"로만 읽히는데, **몇 개 중 몇 개**라는 숫자가 앞에 있으면 같은 격자가
/// 모으는 중인 수집품으로 바뀐다. 그래서 무대 맨 위, 개구리 바로 위에 둔다.
///
/// 이 화면에서 세는 자리는 여기 하나뿐이다. 자리마다 배지와 숫자를 흩뿌리면
/// 다시 산만해진다.
class CosmeticCollectionMeter extends StatelessWidget {
  /// 지금 가지고 있는 개수.
  final int owned;

  /// 옷장에 있는 전부.
  final int total;

  /// 강조색. 사용자가 테마에서 고른 색이다.
  final Color color;

  const CosmeticCollectionMeter({
    super.key,
    required this.owned,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? owned / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 글자를 키운 기기에서 숫자가 남은 폭을 넘는다. 넘치게 두는 대신
        // 줄여서 앉힌다.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const StandardText(
                text: '모은 치장',
                fontSize: 11,
                color: AppColors.textSecondary,
                maxLines: 1,
              ),
              const SizedBox(width: 6),
              AnimatedCountText(
                value: owned,
                fontSize: 17,
                color: color,
              ),
              StandardText(
                text: ' / $total',
                fontSize: 12,
                color: AppColors.textTertiary,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        AnimatedLinearGauge(
          value: ratio,
          color: color,
          // 무대 바탕이 이미 테마색으로 물들어 있다. 회색을 깔면 그 자리만
          // 탁해지고, 흰색을 깔면 무대 위쪽이 거의 흰색이라 홈이 안 보인다.
          // 같은 테마색을 한 단계 진하게 깔아 파인 자리로 만든다.
          backgroundColor: color.withValues(alpha: 0.16),
          height: 5,
          borderRadius: 3,
        ),
      ],
    );
  }
}
