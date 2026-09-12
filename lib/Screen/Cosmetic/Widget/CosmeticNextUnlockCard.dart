import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticAbilityLevels.dart';
import '../../../Model/Cosmetic/CosmeticItemModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Motion/AnimatedGauge.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Text/StandardText.dart';
import 'CosmeticAbilityStyle.dart';
import 'CosmeticItemTile.dart';

/// 이 자리에서 **다음에 열릴 것** 하나를 고른다. 전부 가졌으면 null 이다.
///
/// **남은 레벨이 가장 적은 것**을 고른다. 필요 레벨이 가장 낮은 것이 아니다.
/// 능력치가 넷으로 갈린 뒤로 둘은 다른 말이 됐다. 같은 자리에 출석 Lv.3 짜리와
/// 복습 Lv.4 짜리가 있을 때, 내 출석이 Lv.2 이고 복습이 Lv.10 이면 복습 쪽은
/// 이미 열려 있고 손이 닿는 것은 출석 쪽이다. 필요 레벨로 고르면 이 카드가
/// "다음"이라고 말하면서 이미 가진 것을 가리키게 된다.
///
/// 남은 레벨이 같으면 필요 레벨이 낮은 쪽을, 그것도 같으면 카탈로그 순서를
/// 따른다. 어느 쪽을 골라도 틀리지 않는 자리라서 늘 같은 답이 나오게만 한다.
CosmeticItemModel? cosmeticNextUnlockOf(
  List<CosmeticItemModel> items,
  CosmeticAbilityLevels levels,
) {
  CosmeticItemModel? best;

  for (final item in items) {
    if (item.owned) continue;
    if (best == null) {
      best = item;
      continue;
    }

    final remaining = item.remainingLevelsAt(levels);
    final bestRemaining = best.remainingLevelsAt(levels);
    if (remaining < bestRemaining ||
        (remaining == bestRemaining &&
            item.requiredLevel < best.requiredLevel)) {
      best = item;
    }
  }

  return best;
}

/// 이 자리에서 **가장 마지막에 열린 것**. 아직 하나도 못 열었으면 null 이다.
///
/// 다 모은 자리의 카드가 이것을 보여 준다. 필요 레벨이 가장 높은 것이 그
/// 자리에서 제일 멀리 온 표시다.
CosmeticItemModel? cosmeticLastUnlockedOf(List<CosmeticItemModel> items) {
  CosmeticItemModel? last;

  for (final item in items) {
    if (!item.owned) continue;
    if (last == null || item.requiredLevel >= last.requiredLevel) last = item;
  }

  return last;
}

/// 이 자리에서 다음에 열릴 것 하나를 크게 미리 보여 주는 카드다.
///
/// 잠긴 칸 수십 개를 격자에 흑백으로 늘어놓기만 하면 "못 쓰는 것들"로 읽힌다.
/// **바로 다음 하나를 그림과 함께 크게 보여 주는 쪽**이 훨씬 당긴다. 지금
/// 손이 닿을 만한 거리에 무엇이 있는지가 눈에 들어와야 한다.
///
/// 세 줄로 말한다.
///
/// 1. 이 카드가 무엇인지 · 자리별 진행도
/// 2. 다음에 열릴 것의 이름 · 무엇을 얼마나 올려야 하는지 (`출석 Lv.14`)
/// 3. **지금 내가 그 능력치에서 몇 레벨인지** (`지금 출석 Lv.13 · 한 레벨만 더!`)
///
/// 셋째 줄이 없으면 `출석 Lv.14` 가 코앞인지 한참 남았는지 알 수 없다. 격자
/// 칸은 좁아서 조건까지밖에 못 적는데, 이 카드는 자리가 있어서 거리까지 적는다.
///
/// **다 모은 자리에서도 카드는 그대로 있다.** 카드가 사라졌다 나타났다 하면 탭을
/// 옮길 때마다 격자가 위아래로 튄다. 대신 말을 바꾼다. 다음에 열릴 것 대신
/// **마지막으로 열린 것**을 그 자리에 세운다. 잘했다는 축하는 하지 않는다.
/// 자리마다 다 모을 때마다 축하 문구가 뜨면 금세 잔소리가 된다.
class CosmeticNextUnlockCard extends StatelessWidget {
  /// 이 자리의 아이템 전부. `owned` 가 지금 레벨로 매겨져 있어야 한다.
  final List<CosmeticItemModel> items;

  /// 자리 이름. `머리`, `배경` 처럼 사용자가 읽는 말이다.
  final String slotName;

  /// 개구리 뒤에 깔리는 자리인지. [CosmeticPartPreview.backdrop] 으로 간다.
  final bool backdrop;

  /// 강조색. 사용자가 테마에서 고른 색이다.
  final Color color;

  /// 지금 능력치 레벨 다섯. 셋째 줄과 "다음 하나" 고르기가 이걸 본다.
  final CosmeticAbilityLevels levels;

  const CosmeticNextUnlockCard({
    super.key,
    required this.items,
    required this.slotName,
    required this.backdrop,
    required this.color,
    required this.levels,
  });

  /// 썸네일 한 변. 격자 칸보다 작고 세트 줄의 조각보다는 크다.
  static const double _thumbnailSize = 58.0;

  int get _owned => items.where((item) => item.owned).length;

  @override
  Widget build(BuildContext context) {
    final next = cosmeticNextUnlockOf(items, levels);
    // 다 모은 자리에서는 마지막으로 연 것을 그 자리에 세운다.
    final shown = next ?? cosmeticLastUnlockedOf(items);
    final total = items.length;
    final ratio = total > 0 ? _owned / total : 0.0;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        // 흰 카드로 두면 격자 맨 윗줄처럼 보여서 눈이 그냥 지나친다. 테마색을
        // 옅게 깔아 격자와 다른 것이라고 알린다.
        color: Color.alphaBlend(color.withValues(alpha: 0.07), Colors.white),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          _buildThumbnail(shown, locked: next != null),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitleRow(next != null, total),
                const SizedBox(height: 2),
                _buildNameRow(shown),
                const SizedBox(height: 1),
                _buildProgressRow(shown, hasNext: next != null),
                const SizedBox(height: AppSpacing.sm),
                AnimatedLinearGauge(
                  value: ratio,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.16),
                  height: 4,
                  borderRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 왼쪽 그림.
  ///
  /// 아직 못 가진 것이면 흑백이다. 감추지는 않는다. 무엇이 기다리고 있는지
  /// 보여야 갖고 싶어진다. 다 모은 자리에서는 마지막으로 연 것을 제 색으로
  /// 보여 준다. 가진 것을 흑백으로 두면 아직 못 가진 것처럼 읽힌다.
  Widget _buildThumbnail(CosmeticItemModel? shown, {required bool locked}) {
    return Container(
      width: _thumbnailSize,
      height: _thumbnailSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium - 1),
        child: shown == null
            ? Center(
                child: Icon(Icons.checkroom_rounded, size: 24, color: color))
            : Padding(
                padding: const EdgeInsets.all(2),
                child: CosmeticPartPreview(
                  imageUrl: shown.imageUrl,
                  backdrop: backdrop,
                  locked: locked,
                ),
              ),
      ),
    );
  }

  /// 첫 줄. 왼쪽은 이 카드가 무엇인지, 오른쪽은 이 자리의 진행도다.
  Widget _buildTitleRow(bool hasNext, int total) {
    return Row(
      children: [
        Expanded(
          child: StandardText(
            text: hasNext ? '다음에 열려요' : '마지막으로 열린 것',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StandardText(
          text: '$slotName $_owned / $total',
          fontSize: 11,
          color: AppColors.textTertiary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 둘째 줄. 이름과, 무엇을 얼마나 올려야 열리는지.
  ///
  /// 보여 줄 것이 아예 없으면(이 자리에 아이템이 하나도 없는 경우) 줄을 비운다.
  /// 지우지 않고 [Visibility] 로 자리만 남기는 이유는, 탭을 옮길 때 카드 높이가
  /// 달라지면 아래 격자가 위아래로 튀기 때문이다.
  Widget _buildNameRow(CosmeticItemModel? shown) {
    return Visibility(
      visible: shown != null,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Row(
        children: [
          Expanded(
            child: StandardText(
              text: shown?.nameKo ?? '',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (shown != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: CosmeticLockBadge(item: shown, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  /// 셋째 줄. 지금 내가 그 능력치에서 몇 레벨이고 몇 레벨이 남았는지.
  ///
  /// 다 모은 자리에서는 남은 레벨을 말할 것이 없어서 그 사실을 그대로 적는다.
  /// 잘했다는 축하가 아니라 상태 한 줄이다. 자리마다 다 모을 때마다 칭찬이
  /// 뜨면 금세 잔소리가 된다.
  Widget _buildProgressRow(CosmeticItemModel? shown, {required bool hasNext}) {
    return Visibility(
      visible: shown != null,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: StandardText(
        text: switch (shown) {
          null => '',
          _ when !hasNext => '이 자리는 더 열릴 것이 없어요',
          _ => CosmeticAbilityStyle.progressOf(shown, levels),
        },
        fontSize: 11,
        color: AppColors.textTertiary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
