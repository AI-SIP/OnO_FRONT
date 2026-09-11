import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticItemModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Text/StandardText.dart';
import 'CosmeticItemTile.dart';

/// 한 벌로 묶인 아이템들을 한 번에 입게 하는 줄이다.
///
/// 학사모와 학사복과 졸업장은 자리가 셋으로 흩어져 있어서, 탭을 세 번 옮겨
/// 하나씩 골라야 한 벌이 완성된다. 격자 위에 이 줄을 두면 한 번으로 끝난다.
///
/// 세트 이름을 따로 두지 않는다. 서버가 주는 것은 `setId` 뿐이고 사람이 읽을
/// 이름은 없다. 대신 **묶인 것들의 이름을 그대로 늘어놓는다.** 무엇이 함께
/// 오는지가 이름보다 정확하다.
class CosmeticSetBanner extends StatelessWidget {
  /// 이 세트에 묶인 아이템들.
  final List<CosmeticItemModel> members;

  /// 지금 이 세트를 통째로 입고 있는지.
  final bool equipped;

  /// 강조색. 사용자가 테마에서 고른 색이다.
  final Color color;

  final VoidCallback onTap;

  const CosmeticSetBanner({
    super.key,
    required this.members,
    required this.equipped,
    required this.color,
    required this.onTap,
  });

  /// 한 벌이 다 있는지. 하나라도 모자라면 입을 수 없다.
  bool get _owned => members.every((item) => item.owned);

  /// 이 한 벌에서 지금 가진 개수.
  int get _ownedCount => members.where((item) => item.owned).length;

  /// 아직 못 여는 이유를 짧게 적는다.
  ///
  /// 가장 늦게 열리는 것이 한 벌 전체의 조건이다. 하나라도 미션 보상이면
  /// 레벨로는 끝내 열리지 않으므로 그쪽을 먼저 말한다.
  ///
  /// 몇 개 중 몇 개인지는 [_buildProgress] 가 앞에서 따로 말한다. 여기에
  /// 같이 넣으면 좁은 폰에서 뒤가 잘려 나가는 쪽이 그 숫자가 된다.
  String get _hint {
    if (equipped) return '지금 이 한 벌을 입고 있어요';
    if (_owned) return '한 번에 입어요';

    var required = 0;
    for (final item in members) {
      final level = item.requiredLevel;
      if (level == null) return '미션을 마치면 받을 수 있어요';
      if (level > required) required = level;
    }
    return 'Lv.$required 부터 한 벌로 입어요';
  }

  @override
  Widget build(BuildContext context) {
    final ready = _owned && !equipped;

    return PressableScale(
      onTap: onTap,
      haptic: HapticLevel.none,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: ready
              ? Color.alphaBlend(color.withValues(alpha: 0.10), Colors.white)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(
            color: ready ? color.withValues(alpha: 0.45) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            for (final item in members)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _buildThumbnail(item),
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StandardText(
                    text: [for (final item in members) item.nameKo].join(' · '),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        _owned ? AppColors.textPrimary : AppColors.textDisabled,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  _buildProgress(),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildButton(ready),
          ],
        ),
      ),
    );
  }

  /// 한 벌을 얼마나 모았는지와, 아직 못 여는 이유.
  ///
  /// **숫자가 먼저 온다.** 세트는 자리가 흩어져 있어서 몇 개를 모았는지가
  /// 격자에서는 안 보인다. 여기가 아니면 셀 데가 없다. 좁은 폰에서는 뒤쪽
  /// 설명이 잘리는데, 잘려도 되는 쪽이 설명이다.
  Widget _buildProgress() {
    return Row(
      children: [
        StandardText(
          text: '$_ownedCount / ${members.length}',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _owned ? color : AppColors.textSecondary,
          maxLines: 1,
        ),
        Expanded(
          child: StandardText(
            text: ' · $_hint',
            fontSize: 11,
            color: AppColors.textTertiary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(CosmeticItemModel item) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: CosmeticPartPreview(
          imageUrl: item.imageUrl,
          locked: !item.owned,
        ),
      ),
    );
  }

  /// 오른쪽 끝 버튼.
  ///
  /// 이미 입고 있으면 체크만 둔다. 같은 자리에 계속 "세트로 입기"가 떠 있으면
  /// 눌러도 아무 변화가 없어서 고장처럼 보인다.
  Widget _buildButton(bool ready) {
    if (equipped) {
      return Icon(Icons.check_circle_rounded, size: 22, color: color);
    }

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: ready ? color : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: StandardText(
        text: '세트로 입기',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: ready ? Colors.white : AppColors.textDisabled,
        maxLines: 1,
      ),
    );
  }
}
