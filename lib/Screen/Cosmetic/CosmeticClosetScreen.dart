import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Cosmetic/CosmeticSlotModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/CosmeticProvider.dart';
import '../User/Widget/FrogCharacter.dart';
import 'Widget/CosmeticItemTile.dart';
import 'Widget/CosmeticSlotTabs.dart';

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
                constraints: const BoxConstraints(maxWidth: 720),
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
                          Center(
                            child: FrogCharacter(
                              layers: cosmetic.layers,
                              size: frogSize,
                              borderRadius: AppRadius.xlarge,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildLevelSlider(cosmetic, themeProvider),
                          const SizedBox(height: AppSpacing.md),
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

  /// 개구리 한 변의 길이. 좁은 쪽과 낮은 쪽 중 더 빡빡한 쪽을 따른다.
  double _frogSizeFor(BoxConstraints constraints) {
    final byWidth = constraints.maxWidth * 0.46;
    final byHeight = constraints.maxHeight * 0.30;
    final smaller = byWidth < byHeight ? byWidth : byHeight;
    return smaller.clamp(96.0, 240.0);
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

    final tiles = <Widget>[
      CosmeticSlotEmptyTile(selected: equippedKey == null, color: color),
      for (final item in items)
        CosmeticItemTile(
          item: item,
          equipped: item.itemKey == equippedKey,
          backdrop: backdrop,
          color: color,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 칸 하나가 120 언저리가 되게 나눈다. 폰은 셋, 태블릿은 여섯까지.
        final columns = (constraints.maxWidth / 118).floor().clamp(3, 6);

        return GridView.count(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.xs,
            AppSpacing.screenHorizontal,
            AppSpacing.xxl,
          ),
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          // 정사각 그림 아래에 이름 한 줄이 들어갈 만큼만 더 길다.
          childAspectRatio: 0.82,
          children: AppearTransition.stagger(tiles, maxStaggered: 6),
        );
      },
    );
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
