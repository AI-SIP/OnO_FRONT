import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/CosmeticProvider.dart';
import '../User/Widget/FrogCharacter.dart';
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
                    Expanded(child: _buildPlaceholder()),
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

  /// 아이템 격자가 들어올 자리. 지금은 비어 있다는 것만 알린다.
  Widget _buildPlaceholder() {
    return const Center(
      child: StandardText(
        text: '아이템 목록은 여기에 들어갑니다.',
        fontSize: 13,
        color: AppColors.textTertiary,
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    );
  }
}
