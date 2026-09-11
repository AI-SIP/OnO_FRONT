import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticItemModel.dart';
import '../../../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Motion/SelectionPop.dart';
import '../../../Module/Text/StandardText.dart';

/// 아이템 한 장을 개구리 위에 얹어 보여 주는 그림이다.
///
/// 파츠 그림은 512 캔버스의 **제자리**에 그려져 있다. 나비넥타이는 캔버스
/// 아래쪽 가운데, 모자는 맨 위에 있다. 그래서 그림만 따로 놓으면 작은 조각이
/// 구석에 뜬 것처럼 보이고, 그게 목에 걸리는 것인지 머리에 쓰는 것인지 알 수
/// 없다.
///
/// **개구리를 아주 옅게 깔고 그 위에 파츠를 얹는다.** 종이인형과 같은 방식이라
/// 조각이 어디에 붙는지가 그림 한 장에서 바로 보인다. 확대해서 조각만 키우는
/// 방법도 있지만, 파츠마다 차지하는 자리가 제각각(모자는 위 25%, 소품은 아래
/// 12%)이라 한 배율로는 어떤 것은 잘리고 어떤 것은 그대로다. 아이템마다 잘라
/// 낼 자리를 알려면 서버가 썸네일을 따로 주거나 앱이 그림의 알파 경계를 직접
/// 재야 하는데, 시안 단계에서 할 일은 아니다.
class CosmeticPartPreview extends StatelessWidget {
  /// 파츠 그림. 비어 있으면 개구리만 그린다.
  final String imageUrl;

  /// 개구리 **뒤에** 깔리는 자리인지.
  ///
  /// 배경은 투명한 데가 없는 정사각형이라 그 자체가 썸네일이 된다. 대신
  /// 개구리를 위에 얹어서 "이 그림은 뒤에 깔린다"는 것을 보여 준다.
  final bool backdrop;

  const CosmeticPartPreview({
    super.key,
    required this.imageUrl,
    this.backdrop = false,
  });

  /// 옅게 깔거나 얹는 개구리의 진하기.
  static const double _ghostOnFront = 0.55;
  static const double _ghostBehind = 0.22;

  static ImageProvider<Object> _providerOf(String url) => url.startsWith('http')
      ? NetworkImage(url) as ImageProvider<Object>
      : AssetImage(url);

  Widget _image(String url, {double opacity = 1.0, BoxFit fit = BoxFit.cover}) {
    if (url.isEmpty) return const SizedBox.shrink();

    return Image(
      image: _providerOf(url),
      fit: fit,
      opacity: opacity >= 1.0 ? null : AlwaysStoppedAnimation<double>(opacity),
      // 그림 한 장을 못 읽었다고 칸이 깨지면 안 된다. 그 층만 비운다.
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ghost = CosmeticLoadoutModel.defaultBaseImageUrl;

    return Stack(
      fit: StackFit.expand,
      children: backdrop
          ? [
              _image(imageUrl),
              _image(ghost, opacity: _ghostOnFront, fit: BoxFit.contain),
            ]
          : [
              _image(ghost, opacity: _ghostBehind, fit: BoxFit.contain),
              _image(imageUrl, fit: BoxFit.contain),
            ],
    );
  }
}

/// 옷장 격자의 칸 하나다.
///
/// 상태가 셋이고 한눈에 갈라져야 한다.
///
/// - **장착 중**: 테마색 테두리와 옅은 바탕, 오른쪽 위에 체크
/// - **보유**: 흰 바탕에 옅은 테두리
/// - **미보유**: 흑백으로 죽이고 아래에 `Lv.14` 또는 `미션 보상` 배지
class CosmeticItemTile extends StatelessWidget {
  final CosmeticItemModel item;

  /// 지금 이 아이템을 입고 있는지.
  final bool equipped;

  /// 개구리 뒤에 깔리는 자리인지. [CosmeticPartPreview.backdrop] 으로 간다.
  final bool backdrop;

  /// 강조색. 사용자가 테마에서 고른 색이다.
  final Color color;

  final VoidCallback? onTap;

  const CosmeticItemTile({
    super.key,
    required this.item,
    required this.equipped,
    required this.backdrop,
    required this.color,
    this.onTap,
  });

  /// 아직 못 가진 것을 흑백으로 만드는 행렬이다.
  static const List<double> _grayscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  bool get _owned => item.owned;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      haptic: HapticLevel.none,
      scale: 0.95,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildThumbnail()),
          const SizedBox(height: AppSpacing.xs),
          StandardText(
            text: item.nameKo,
            fontSize: 12,
            fontWeight: equipped ? FontWeight.w700 : FontWeight.w500,
            color: equipped
                ? color
                : (_owned ? AppColors.textSecondary : AppColors.textDisabled),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final preview = CosmeticPartPreview(
      imageUrl: item.imageUrl,
      backdrop: backdrop,
    );

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: equipped
            ? Color.alphaBlend(color.withValues(alpha: 0.10), Colors.white)
            : (_owned ? AppColors.surface : AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: equipped ? color.withValues(alpha: 0.55) : AppColors.border,
          width: equipped ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.large - 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(2),
              child: _owned
                  ? preview
                  // 못 가진 것은 색을 빼고 옅게 둔다. 흐리게만 하면 옆 칸과
                  // 구분이 잘 안 되는데, 색이 빠지면 멀리서도 갈라진다.
                  : Opacity(
                      opacity: 0.55,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(_grayscale),
                        child: preview,
                      ),
                    ),
            ),
            if (!_owned)
              Positioned(
                left: AppSpacing.xs,
                right: AppSpacing.xs,
                bottom: AppSpacing.xs,
                child: Center(child: _buildLockBadge()),
              ),
            // 체크는 늘 자리에 두고 켜고 끈다. 입는 순간에만 만들면 튀어오르는
            // 연출이 제 시점을 놓친다.
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: SelectionPop(
                selected: equipped,
                child: AnimatedOpacity(
                  duration: AppMotion.fast,
                  opacity: equipped ? 1 : 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 왜 못 쓰는지 한 조각으로 알린다.
  ///
  /// 레벨로 열리는 것은 몇 레벨부터인지 숫자로, 미션 보상은 말로 적는다.
  /// 미션 보상에 `Lv.0` 같은 없는 숫자를 쓰면 안 된다.
  Widget _buildLockBadge() {
    final byLevel = item.unlocksByLevel;
    final text = byLevel ? 'Lv.${item.requiredLevel}' : '미션 보상';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: byLevel ? AppColors.textSecondary : _missionReward,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: StandardText(
        text: text,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 미션 보상 배지 색. 미션 화면의 오답노트 갈래와 같은 보라다.
  ///
  /// 레벨로 열리는 것과 미션으로 받는 것은 얻는 길이 다르다. 색을 갈라 두면
  /// 격자를 훑을 때 "이건 미션 쪽"이 한눈에 걸린다.
  static const Color _missionReward = Color(0xFFBA68C8);
}

/// 이 자리를 비워 두는 칸이다.
///
/// 입고 있는 것을 다시 눌러도 벗겨지지만, 그걸 아는 사람은 눌러 본 사람뿐이다.
/// 격자 맨 앞에 **벗은 모습**을 한 칸 두면 비울 수 있다는 것도, 지금 이 자리가
/// 비어 있다는 것도 같이 보인다.
class CosmeticSlotEmptyTile extends StatelessWidget {
  /// 지금 이 자리가 비어 있는지.
  final bool selected;

  final Color color;
  final VoidCallback? onTap;

  const CosmeticSlotEmptyTile({
    super.key,
    required this.selected,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      haptic: HapticLevel.none,
      scale: 0.95,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              decoration: BoxDecoration(
                color: selected
                    ? Color.alphaBlend(
                        color.withValues(alpha: 0.10),
                        Colors.white,
                      )
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.55)
                      : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.large - 2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(2),
                      child: CosmeticPartPreview(imageUrl: ''),
                    ),
                    Center(
                      child: Icon(
                        Icons.do_not_disturb_alt_rounded,
                        size: 24,
                        color: selected ? color : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          StandardText(
            text: '안 입기',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : AppColors.textSecondary,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
