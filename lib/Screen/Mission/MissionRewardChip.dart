import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'MissionTag.dart';

/// 보상을 나타내는 작은 표시다.
///
/// 예전에는 금색 코인이었는데 누런 금색이 앱 어디에도 없는 색이라 겉돌았다.
/// **보상 색을 따로 만들지 않고 사용자가 고른 테마색을 쓴다.** 테마가 24종이라
/// 사람마다 보상의 색은 달라지지만, 적어도 자기 앱 안에서는 늘 같은 색이다.
class MissionRewardToken extends StatelessWidget {
  final double size;

  /// 색을 직접 정할 때. 주지 않으면 테마색이다.
  final Color? color;

  const MissionRewardToken({super.key, this.size = 16, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Provider.of<ThemeHandler>(context).primaryColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
      child: Center(child: _TokenLabel(size: size)),
    );
  }
}

/// 토큰 안의 `XP` 글자. 토큰 크기에 맞춰 줄어든다.
class _TokenLabel extends StatelessWidget {
  final double size;

  const _TokenLabel({required this.size});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Padding(
        padding: EdgeInsets.all(size * 0.18),
        child: Text(
          'XP',
          style: TextStyle(
            fontFamily: 'PretendardBold',
            fontSize: size * 0.4,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// 보상 칩. 다른 작은 라벨과 모양이 같고 색만 다르다.
class MissionRewardChip extends StatelessWidget {
  final MissionRewardType? rewardType;
  final int amount;

  /// 이미 받은 보상. 조용하게 둔다.
  final bool dimmed;

  /// 색을 직접 정할 때. 주지 않으면 테마색이다.
  final Color? color;

  const MissionRewardChip({
    super.key,
    required this.rewardType,
    required this.amount,
    this.dimmed = false,
    this.color,
  });

  /// 보상 종류를 모르면 액수를 앞세우지 않는다. 새 보상이 생겨도 말이 되게.
  String get label => rewardType == MissionRewardType.xp ? '+$amount XP' : '보상';

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Provider.of<ThemeHandler>(context).primaryColor;

    return MissionTag(
      text: label,
      color: tint,
      dimmed: dimmed,
      leading: MissionRewardToken(size: MissionTag.fontSize * 1.1, color: tint),
    );
  }
}
