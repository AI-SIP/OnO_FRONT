import 'package:flutter/material.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppRewardColors.dart';
import '../../Module/Text/StandardText.dart';

/// 금색 코인 하나. 칩 안에도, 날아가는 연출에도 같은 것을 쓴다.
///
/// 이미지가 아니라 그라데이션 원이다. 에셋이 없어도 되고, 어떤 크기로도
/// 또렷하다.
class MissionCoin extends StatelessWidget {
  final double size;

  const MissionCoin({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppRewardColors.coinLight, AppRewardColors.coin],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33C98A06),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: StandardText(
          text: 'XP',
          // 코인이 작아지면 글자도 같이 줄어야 원 밖으로 나가지 않는다.
          fontSize: size * 0.34,
          color: AppRewardColors.onCoin,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 보상을 보여 주는 금색 칩이다.
///
/// XP 를 회색 작은 글씨로 두면 보상이 보상으로 안 보인다. 코인과 금색 바탕을
/// 줘서 화면에서 이것만 색이 다르게 만든다.
class MissionRewardChip extends StatelessWidget {
  final MissionRewardType? rewardType;
  final int amount;

  /// 이미 받은 보상. 채도를 낮춰 조용하게 둔다.
  final bool dimmed;

  /// 채운 카드(받을 수 있는 미션) 위에 얹을 때. 바탕이 진해서 칩을 밝게 든다.
  final bool onFilled;

  final double fontSize;

  const MissionRewardChip({
    super.key,
    required this.rewardType,
    required this.amount,
    this.dimmed = false,
    this.onFilled = false,
    this.fontSize = 12,
  });

  /// 보상 종류를 모르면 액수를 앞세우지 않는다. 새 보상이 생겨도 말이 되게.
  String get label => rewardType == MissionRewardType.xp ? '+$amount XP' : '보상';

  @override
  Widget build(BuildContext context) {
    final background = onFilled
        ? Colors.white.withValues(alpha: 0.22)
        : AppRewardColors.coinSurface;

    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.7,
          vertical: fontSize * 0.28,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: onFilled
                ? Colors.white.withValues(alpha: 0.5)
                : AppRewardColors.coin.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MissionCoin(size: fontSize * 1.2),
            SizedBox(width: fontSize * 0.4),
            // 글자를 키운 기기에서도 칩이 줄을 밀어내지 않게 한 줄로 줄인다.
            Flexible(
              child: StandardText(
                text: label,
                fontSize: fontSize,
                color: onFilled ? Colors.white : AppRewardColors.onCoin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
