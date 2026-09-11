import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticItemModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Motion/AnimatedGauge.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Text/StandardText.dart';
import 'CosmeticItemTile.dart';

/// 이 자리에서 **다음에 열릴 것** 하나를 고른다.
///
/// 레벨로 열리는 것 중 가장 빨리 열리는 것이 먼저다. 레벨로 열리는 것이 더
/// 없으면 미션 보상 중 첫 번째를 고른다. 전부 가졌으면 null 이다.
CosmeticItemModel? cosmeticNextUnlockOf(List<CosmeticItemModel> items) {
  CosmeticItemModel? byLevel;
  CosmeticItemModel? byMission;

  for (final item in items) {
    if (item.owned) continue;

    final level = item.requiredLevel;
    if (level == null) {
      byMission ??= item;
      continue;
    }
    final current = byLevel?.requiredLevel;
    if (current == null || level < current) byLevel = item;
  }

  return byLevel ?? byMission;
}

/// 이 자리에서 다음에 열릴 것 하나를 크게 미리 보여 주는 카드다.
///
/// 잠긴 칸 스물넷을 격자에 흑백으로 늘어놓기만 하면 "못 쓰는 것들"로 읽힌다.
/// **바로 다음 하나를 그림과 함께 크게 보여 주는 쪽**이 훨씬 당긴다. 지금
/// 손이 닿을 만한 거리에 무엇이 있는지가 눈에 들어와야 한다.
///
/// 자리별로 몇 개 중 몇 개를 모았는지도 여기에 같이 얹는다. 탭 여덟 개에
/// 숫자를 하나씩 달면 줄이 시끄러워지는데, 고른 자리의 것만 이 카드에서 말하면
/// 한 번에 하나씩만 보인다.
///
/// 다 모아서 예고할 것이 없어도 카드는 그대로 둔다. 카드가 사라졌다 나타났다
/// 하면 탭을 옮길 때마다 격자가 위아래로 튄다. 대신 **잘했다는 말은 하지
/// 않는다.** 자리마다 다 모을 때마다 축하 문구가 뜨면 금세 잔소리가 된다.
/// 아랫줄을 자리만 차지한 채 비워 두고, 남는 것은 진행도와 꽉 찬 막대다.
class CosmeticNextUnlockCard extends StatelessWidget {
  /// 이 자리의 아이템 전부. `owned` 가 지금 레벨로 매겨져 있어야 한다.
  final List<CosmeticItemModel> items;

  /// 자리 이름. `머리`, `배경` 처럼 사용자가 읽는 말이다.
  final String slotName;

  /// 개구리 뒤에 깔리는 자리인지. [CosmeticPartPreview.backdrop] 으로 간다.
  final bool backdrop;

  /// 강조색. 사용자가 테마에서 고른 색이다.
  final Color color;

  const CosmeticNextUnlockCard({
    super.key,
    required this.items,
    required this.slotName,
    required this.backdrop,
    required this.color,
  });

  /// 썸네일 한 변. 격자 칸보다 작고 세트 줄의 조각보다는 크다.
  static const double _thumbnailSize = 58.0;

  int get _owned => items.where((item) => item.owned).length;

  @override
  Widget build(BuildContext context) {
    final next = cosmeticNextUnlockOf(items);
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
          _buildThumbnail(next),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitleRow(next, total),
                const SizedBox(height: 2),
                _buildNameRow(next, total),
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

  /// 왼쪽 그림. 아직 못 가진 것이라 흑백이다.
  ///
  /// 감추지 않는다. 무엇이 기다리고 있는지 보여야 갖고 싶어진다.
  Widget _buildThumbnail(CosmeticItemModel? next) {
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
        child: next == null
            ? Center(
                child: Icon(Icons.check_rounded, size: 26, color: color),
              )
            : Padding(
                padding: const EdgeInsets.all(2),
                child: CosmeticPartPreview(
                  imageUrl: next.imageUrl,
                  backdrop: backdrop,
                  locked: true,
                ),
              ),
      ),
    );
  }

  /// 첫 줄. 왼쪽은 이 카드가 무엇인지, 오른쪽은 이 자리의 진행도다.
  Widget _buildTitleRow(CosmeticItemModel? next, int total) {
    return Row(
      children: [
        Expanded(
          child: StandardText(
            // 예고할 것이 없으면 왼쪽을 비운다. 다 모았다고 말하지 않는다.
            text: next == null ? '' : '다음에 열려요',
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

  /// 둘째 줄. 다음에 열릴 것의 이름과, 어떻게 얻는지.
  ///
  /// 예고할 것이 없으면 줄을 비운다. 지우지 않고 [Visibility] 로 자리만
  /// 남기는 이유는, 탭을 옮길 때 카드 높이가 달라지면 아래 격자가 위아래로
  /// 튀기 때문이다.
  Widget _buildNameRow(CosmeticItemModel? next, int total) {
    return Visibility(
      visible: next != null,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Row(
        children: [
          Expanded(
            child: StandardText(
              text: next?.nameKo ?? '',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (next != null) ...[
            const SizedBox(width: AppSpacing.sm),
            CosmeticLockBadge(item: next, fontSize: 11),
          ],
        ],
      ),
    );
  }
}
