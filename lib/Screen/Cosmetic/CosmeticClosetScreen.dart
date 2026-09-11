import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Cosmetic/CosmeticItemModel.dart';
import '../../Model/Cosmetic/CosmeticSlotModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Design/AppToast.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/CosmeticProvider.dart';
import 'CosmeticCombinationPreviewScreen.dart';
import 'Widget/CosmeticCollectionMeter.dart';
import 'Widget/CosmeticItemTile.dart';
import 'Widget/CosmeticNextUnlockCard.dart';
import 'Widget/CosmeticSetBanner.dart';
import 'Widget/CosmeticSlotTabs.dart';
import 'Widget/CosmeticStage.dart';

/// 개구리 옷장이다.
///
/// 화면은 두 층이다. 위에는 지금 차림 그대로의 개구리와 레벨 슬라이더가
/// **붙박이로** 있고, 아래에서 자리를 골라 아이템을 갈아 끼운다. 무엇을 눌러도
/// 위쪽 개구리가 바로 바뀌는 것이 이 화면의 전부라서, 개구리는 스크롤을 따라
/// 사라지지 않는다.
///
/// 서버를 타지 않는다. 카탈로그도 장착 상태도 [CosmeticProvider] 가 더미로
/// 들고 있다.
class CosmeticClosetScreen extends StatefulWidget {
  const CosmeticClosetScreen({super.key});

  @override
  State<CosmeticClosetScreen> createState() => _CosmeticClosetScreenState();
}

class _CosmeticClosetScreenState extends State<CosmeticClosetScreen> {
  /// 지금 보고 있는 자리. [CosmeticProvider.slots] 의 순번이다.
  int _slotIndex = 0;

  /// 갈아입은 횟수. 개구리를 한 번 들썩이게 하는 신호로만 쓴다.
  int _equipTick = 0;

  /// 아이템 칸을 눌렀을 때.
  ///
  /// 가진 것이면 걸고, 이미 걸려 있던 것을 다시 누르면 벗는다. 못 가진 것도
  /// 눌리기는 한다. [CosmeticProvider.equip] 이 막아 주고 왜 안 되는지를
  /// 문구로 남기므로, 그것을 꺼내 알림으로 띄운다. 알림은 화면 위를 덮지 않아서
  /// 계속 다른 것을 눌러 볼 수 있다.
  void _onItemTap(
    CosmeticProvider cosmetic,
    CosmeticSlotModel slot,
    CosmeticItemModel item,
  ) {
    if (!item.owned) {
      AppHaptic.secondary();
      cosmetic.equip(slot.slot, item.itemKey);
      _showFailure(cosmetic);
      return;
    }

    AppHaptic.selection();
    if (cosmetic.equippedItemKeyOf(slot.slot) == item.itemKey) {
      cosmetic.unequip(slot.slot);
    } else {
      cosmetic.equip(slot.slot, item.itemKey);
    }
    _pulse();
  }

  /// 자리를 비운다. 이미 비어 있으면 아무 일도 하지 않는다.
  void _onEmptyTap(CosmeticProvider cosmetic, CosmeticSlotModel slot) {
    if (cosmetic.equippedItemKeyOf(slot.slot) == null) return;

    AppHaptic.selection();
    cosmetic.unequip(slot.slot);
    _pulse();
  }

  /// 못 쓰는 이유를 한 번 꺼내 알린다. 실수가 아니라 안내라서 빨간 알림이
  /// 아니다.
  void _showFailure(CosmeticProvider cosmetic) {
    final message = cosmetic.consumeFailure();
    if (message == null) return;
    AppToast.info(message);
  }

  /// 한 벌을 통째로 건다.
  ///
  /// 세트에 못 가진 것이 섞여 있으면 [CosmeticProvider.equipSet] 이 하나도
  /// 걸지 않는다. 절반만 입혀 두면 무엇이 모자란지 알 수 없기 때문이다.
  void _onSetTap(CosmeticProvider cosmetic, String setId) {
    cosmetic.equipSet(setId);

    final message = cosmetic.consumeFailure();
    if (message != null) {
      AppHaptic.secondary();
      AppToast.info(message);
      return;
    }

    AppHaptic.primary();
    _pulse();
  }

  /// 걸친 것을 전부 벗는다.
  void _onResetTap(CosmeticProvider cosmetic) {
    AppHaptic.selection();
    cosmetic.unequipAll();
    _pulse();
  }

  void _pulse() {
    if (!mounted) return;
    setState(() => _equipTick++);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    // LayoutBuilder 안에서는 watch 가 듣지 않는다. build 최상단에서 받는다.
    final cosmetic = context.watch<CosmeticProvider>();

    final slots = cosmetic.slots;
    final slotIndex = slots.isEmpty ? 0 : _slotIndex.clamp(0, slots.length - 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: StandardText(
          text: '개구리 꾸미기',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        actions: [
          // 레벨로 열리는 것은 서른다섯 중 열여섯뿐이고 나머지는 미션 보상이라
          // 슬라이더를 끝까지 올려도 안 걸린다. 시안을 보는 동안은 전부 입어
          // 볼 수 있어야 해서 잠금을 통째로 푸는 스위치를 둔다. 출시본에는
          // 이 버튼이 아예 없다.
          if (kDebugMode)
            IconButton(
              icon: Icon(
                cosmetic.unlockAll
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                color: cosmetic.unlockAll
                    ? themeProvider.primaryColor
                    : AppColors.textSecondary,
              ),
              tooltip: cosmetic.unlockAll ? '잠금 되돌리기' : '전부 입어 보기',
              onPressed: () {
                final next = !cosmetic.unlockAll;
                cosmetic.setUnlockAll(next);
                AppHaptic.selection();
                AppToast.show(
                  message: next ? '잠긴 아이템까지 전부 열었어요.' : '레벨대로 다시 잠갔어요.',
                  context: context,
                );
              },
            ),
          // 조합이 자리 수의 곱으로 늘어나서 옷장에서 하나씩 입혀 보는 것으로는
          // 겹침이 이상한 짝을 찾을 수 없다. 한꺼번에 펼쳐 보는 화면을 개발
          // 중에만 열어 둔다. 출시본에는 이 버튼이 아예 없다.
          if (kDebugMode)
            IconButton(
              icon: Icon(
                Icons.grid_view_rounded,
                color: themeProvider.primaryColor,
              ),
              tooltip: '조합 검수',
              onPressed: () => Navigator.push(
                context,
                TossPageRoute(
                  builder: (_) => const CosmeticCombinationPreviewScreen(),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 개구리는 화면이 좁으면 너비를, 낮으면 높이를 따라간다. 위쪽이
            // 붙박이라서 개구리가 크면 아래 아이템 자리가 없어진다.
            final frogSize = _frogSizeFor(constraints);

            return Center(
              child: ConstrainedBox(
                // 태블릿에서 격자가 끝없이 넓어지지 않게 가운데로 모은다.
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        0,
                        AppSpacing.screenHorizontal,
                        AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          _buildStage(
                            cosmetic,
                            themeProvider,
                            frogSize,
                          ),
                          _buildLevelSlider(cosmetic, themeProvider),
                          const SizedBox(height: AppSpacing.sm),
                          CosmeticSlotTabs(
                            slots: slots,
                            index: slotIndex,
                            color: themeProvider.primaryColor,
                            onChanged: (index) =>
                                setState(() => _slotIndex = index),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: slots.isEmpty
                          ? _buildEmpty()
                          : _buildSlotItems(
                              cosmetic,
                              slots[slotIndex],
                              themeProvider.primaryColor,
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 개구리가 서는 자리. 이 화면의 주인공이다.
  ///
  /// 바탕은 위가 밝고 아래로 갈수록 테마색이 도는 세로 그라데이션이다. 위에서
  /// 빛이 들어오고 아래가 바닥인 무대의 결이라, 그 위에 선 개구리가 조각이
  /// 아니라 장면으로 읽힌다. 빛무리와 바닥 그림자는
  /// [CosmeticStageFrog] 가 그린다.
  ///
  /// 금색 같은 별도의 장식색을 쓰지 않는다. 그러면 이 화면만 앱에서 겉돈다.
  Widget _buildStage(
    CosmeticProvider cosmetic,
    ThemeHandler themeProvider,
    double frogSize,
  ) {
    final color = themeProvider.primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(color.withValues(alpha: 0.05), Colors.white),
            Color.alphaBlend(color.withValues(alpha: 0.13), Colors.white),
            Color.alphaBlend(color.withValues(alpha: 0.20), Colors.white),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        // 무대가 바닥에서 살짝 떠 보이게 한다. 카드가 아니라 장면이라는
        // 신호라서 테마색 그림자를 옅게 쓴다.
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 수집률과 되돌리기는 개구리 위에 겹치지 않게 한 줄을 따로 쓴다.
          // 겹쳐 두면 배경을 입은 개구리의 모서리를 가린다.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CosmeticCollectionMeter(
                  owned: cosmetic.items.where((item) => item.owned).length,
                  total: cosmetic.items.length,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _buildResetButton(cosmetic, color),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          CosmeticStageFrog(
            layers: cosmetic.layers,
            size: frogSize,
            color: color,
            equipTick: _equipTick,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  /// 이것저것 입혀 보다 엉망이 됐을 때 돌아올 자리.
  ///
  /// 지금 레벨에서 자동으로 입게 되는 차림으로 되돌린다. 개구리 옆에 두는
  /// 이유는, 되돌린 결과가 바로 그 자리에서 보여야 무엇이 일어났는지 알기
  /// 때문이다.
  Widget _buildResetButton(CosmeticProvider cosmetic, Color color) {
    return PressableScale(
      onTap: () => _onResetTap(cosmetic),
      haptic: HapticLevel.none,
      scale: 0.92,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
            StandardText(
              text: '전부 벗기',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  /// 개구리 한 변의 길이. 좁은 쪽과 낮은 쪽 중 더 빡빡한 쪽을 따른다.
  double _frogSizeFor(BoxConstraints constraints) {
    final byWidth = constraints.maxWidth * 0.50;
    final byHeight = constraints.maxHeight * 0.28;
    final smaller = byWidth < byHeight ? byWidth : byHeight;
    // 태블릿에서는 폭이 남아도 여기서 멈춘다. 더 키우면 아이템 격자가 첫
    // 화면에서 사라진다. 무대가 주인공이 되면서 280 으로는 넓은 무대 한가운데
    // 작은 조각이 놓인 것처럼 보여 한 단계 키웠다.
    return smaller.clamp(96.0, 340.0);
  }

  /// 레벨을 직접 옮겨 보는 슬라이더.
  ///
  /// 시안의 핵심이다. Lv.1 부터 Lv.15 까지 훑으면서 해금이 어떻게 쌓이는지
  /// 개구리에 바로 보이게 한다. 실제 출시 화면에는 들어가지 않는다.
  Widget _buildLevelSlider(
    CosmeticProvider cosmetic,
    ThemeHandler themeProvider,
  ) {
    return Row(
      children: [
        const SizedBox(width: AppSpacing.xs),
        StandardText(
          text: 'Lv.${cosmetic.level}',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: themeProvider.primaryColor,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: cosmetic.level.toDouble(),
              min: 1,
              max: cosmetic.maxLevel.toDouble(),
              divisions: cosmetic.maxLevel - 1,
              label: 'Lv.${cosmetic.level}',
              activeColor: themeProvider.primaryColor,
              inactiveColor: AppColors.surfaceMuted,
              onChanged: (value) => cosmetic.setMockLevel(value.round()),
            ),
          ),
        ),
      ],
    );
  }

  /// 고른 자리의 아이템들.
  ///
  /// 자리를 옮기면 격자가 옅게 갈린다. 자리마다 아이템 수가 달라서 목록을
  /// 그대로 바꾸면 화면이 툭 끊긴다.
  Widget _buildSlotItems(
    CosmeticProvider cosmetic,
    CosmeticSlotModel slot,
    Color color,
  ) {
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      // 페이드만 한다. 크기를 건드리면 격자 가장자리에 틈이 생긴다.
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: KeyedSubtree(
        key: ValueKey<String>(slot.slot),
        child: _buildGrid(cosmetic, slot, color),
      ),
    );
  }

  Widget _buildGrid(
    CosmeticProvider cosmetic,
    CosmeticSlotModel slot,
    Color color,
  ) {
    final items = cosmetic.itemsOfSlot(slot.slot);
    final equippedKey = cosmetic.equippedItemKeyOf(slot.slot);
    final backdrop = _isBackdrop(cosmetic.slots, slot);
    // 이번 레벨에 열린 것들. 마흔 칸을 눈으로 훑어 무엇이 늘었는지 찾게 하면
    // 안 된다.
    final newKeys = <String>{
      for (final item in cosmetic.unlockedAt(cosmetic.level)) item.itemKey,
    };

    final tiles = <Widget>[
      CosmeticSlotEmptyTile(
        selected: equippedKey == null,
        color: color,
        onTap: () => _onEmptyTap(cosmetic, slot),
      ),
      for (final item in items)
        CosmeticItemTile(
          item: item,
          equipped: item.itemKey == equippedKey,
          backdrop: backdrop,
          isNew: newKeys.contains(item.itemKey),
          color: color,
          onTap: () => _onItemTap(cosmetic, slot, item),
        ),
    ];

    // 이 자리에 한 벌로 묶인 것이 있으면 격자 위에 세트 줄을 얹는다.
    final setId = _setIdOf(items);
    final members = setId == null
        ? const <CosmeticItemModel>[]
        : cosmetic.itemsOfSet(setId);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 칸 하나가 120 언저리가 되게 나눈다. 폰은 셋, 태블릿은 여섯까지.
        final columns = (constraints.maxWidth / 118).floor().clamp(3, 6);

        return CustomScrollView(
          slivers: [
            // 격자보다 먼저 온다. 잠긴 칸을 훑기 전에 "다음은 이것"이 눈에
            // 들어와야 격자가 모으는 중인 목록으로 읽힌다.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xs,
                AppSpacing.screenHorizontal,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: AppearTransition(
                  child: CosmeticNextUnlockCard(
                    items: items,
                    slotName: slot.nameKo,
                    backdrop: backdrop,
                    color: color,
                  ),
                ),
              ),
            ),
            if (setId != null && members.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.xs,
                  AppSpacing.screenHorizontal,
                  AppSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: AppearTransition(
                    child: CosmeticSetBanner(
                      members: members,
                      equipped: _isSetEquipped(cosmetic, members),
                      color: color,
                      onTap: () => _onSetTap(cosmetic, setId),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xs,
                AppSpacing.screenHorizontal,
                AppSpacing.xxl,
              ),
              sliver: SliverGrid.count(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                // 정사각 그림 아래에 이름 한 줄이 들어갈 만큼만 더 길다.
                childAspectRatio: 0.82,
                children: AppearTransition.stagger(tiles, maxStaggered: 6),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 이 자리의 아이템 중 한 벌로 묶인 것이 있으면 그 세트 키.
  String? _setIdOf(List<CosmeticItemModel> items) {
    for (final item in items) {
      final setId = item.setId;
      if (setId != null) return setId;
    }
    return null;
  }

  /// 세트가 통째로 걸려 있는지.
  bool _isSetEquipped(
    CosmeticProvider cosmetic,
    List<CosmeticItemModel> members,
  ) {
    for (final item in members) {
      if (cosmetic.equippedItemKeyOf(item.slot) != item.itemKey) return false;
    }
    return members.isNotEmpty;
  }

  /// 개구리 **뒤에** 깔리는 자리인지.
  ///
  /// 가장 뒤에 그려지는 자리가 배경이다. 슬롯 키를 박아 두지 않는 이유는
  /// 자리 이름이 서버가 정하는 값이기 때문이다. 그리는 순서만 보면 된다.
  bool _isBackdrop(List<CosmeticSlotModel> slots, CosmeticSlotModel slot) {
    var lowest = slot.layerOrder;
    for (final entry in slots) {
      if (entry.layerOrder < lowest) lowest = entry.layerOrder;
    }
    return slot.layerOrder == lowest;
  }

  /// 자리 자체가 하나도 없을 때. 더미에서는 나지 않지만 서버가 붙으면 난다.
  Widget _buildEmpty() {
    return const Center(
      child: StandardText(
        text: '아직 꾸밀 수 있는 것이 없어요.',
        fontSize: 13,
        color: AppColors.textTertiary,
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    );
  }
}
