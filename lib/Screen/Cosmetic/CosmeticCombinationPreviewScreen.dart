import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Cosmetic/CosmeticItemModel.dart';
import '../../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/CosmeticProvider.dart';
import '../User/Widget/FrogCharacter.dart';
import 'Mock/CosmeticMockData.dart';

/// 조합을 한꺼번에 펼쳐 보는 **개발용** 화면이다.
///
/// 자리가 여덟이고 아이템이 서른다섯이라 조합 수가 곱으로 늘어난다. 옷장에서
/// 하나씩 갈아입혀 보는 것으로는 겹침이 이상한 짝을 찾을 수 없다. 그래서 한
/// 화면에 격자로 쏟아 놓고 눈으로 훑는다.
///
/// 세 묶음으로 나눠 본다.
///
/// 1. **레벨별 기본 차림** — Lv.1 부터 Lv.15 까지 자동으로 입게 되는 모습
/// 2. **자리별 아이템 전부** — 지금 차림에서 그 자리만 하나씩 갈아 낀 모습
/// 3. **이웃한 자리 겹침** — 그리는 순서가 붙어 있는 두 자리의 짝. 서로 가장
///    부딪히기 쉬운 조합이라 이 짝들만 본다
///
/// 옷장 화면에서 `kDebugMode` 일 때만 들어올 수 있다. 출시본에는 나가지 않는다.
class CosmeticCombinationPreviewScreen extends StatelessWidget {
  const CosmeticCombinationPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final cosmetic = context.watch<CosmeticProvider>();
    final sections = _buildSections(cosmetic);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: StandardText(
          text: '조합 검수',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 132).floor().clamp(2, 8);

            return CustomScrollView(
              slivers: [
                for (final section in sections) ...[
                  SliverToBoxAdapter(child: _buildHeader(section)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    sliver: SliverGrid.count(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.78,
                      children: [
                        for (final combo in section.combos) _buildCell(combo),
                      ],
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(_ComboSection section) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StandardText(
            text: '${section.title} (${section.combos.length})',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          StandardText(
            text: section.description,
            fontSize: 12,
            color: AppColors.textTertiary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 한 칸. 겹쳐 그린 개구리와 무엇을 입혔는지만 적는다.
  Widget _buildCell(_Combo combo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium - 1),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 칸에 꽉 차게 그린다. 작게 그리면 겹침이 안 보인다.
                  final side = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight;
                  return Center(
                    child: FrogLayerStack(
                      layers: combo.layers,
                      size: side,
                      borderRadius: 0,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        StandardText(
          text: combo.label,
          fontSize: 11,
          color: AppColors.textSecondary,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── 무엇을 보여 줄지 ────────────────────────────────────────────────

  List<_ComboSection> _buildSections(CosmeticProvider cosmetic) {
    return [
      _levelSection(cosmetic),
      ..._slotSections(cosmetic),
      ..._neighborSections(cosmetic),
    ];
  }

  /// 레벨별로 자동으로 입게 되는 차림.
  _ComboSection _levelSection(CosmeticProvider cosmetic) {
    return _ComboSection(
      title: '레벨별 기본 차림',
      description: '레벨을 올릴 때마다 개구리가 어떻게 달라지는지',
      combos: [
        for (var level = 1; level <= cosmetic.maxLevel; level++)
          _Combo(
            label: 'Lv.$level',
            layers: cosmetic.layersAtLevel(level),
          ),
      ],
    );
  }

  /// 지금 차림에서 한 자리만 갈아 낀 모습들.
  List<_ComboSection> _slotSections(CosmeticProvider cosmetic) {
    return [
      for (final slot in cosmetic.slots)
        if (cosmetic.itemsOfSlot(slot.slot).isNotEmpty)
          _ComboSection(
            title: '${slot.nameKo} 전부',
            description: '지금 입고 있는 차림에서 이 자리만 바꾼다',
            combos: [
              for (final item in cosmetic.itemsOfSlot(slot.slot))
                _Combo(
                  label: item.nameKo,
                  layers: _layersOf({
                    ...cosmetic.equipped,
                    slot.slot: item.itemKey,
                  }),
                ),
            ],
          ),
    ];
  }

  /// 그리는 순서가 이웃한 두 자리의 짝.
  ///
  /// 자리를 둘씩 다 짝지으면 스물여덟 짝이 나오는데, 실제로 부딪히는 것은
  /// 대개 **겹쳐 그리는 순서가 붙어 있는** 것들이다(얼굴과 머리, 목과 옷).
  /// 그래서 이웃한 짝만 본다. 다른 것은 아무것도 안 걸친 개구리에 둘만 얹어서
  /// 겹치는 자리만 도드라지게 한다.
  List<_ComboSection> _neighborSections(CosmeticProvider cosmetic) {
    final slots = [...cosmetic.slots]
      ..sort((a, b) => a.layerOrder.compareTo(b.layerOrder));

    final sections = <_ComboSection>[];
    for (var i = 0; i + 1 < slots.length; i++) {
      final first = slots[i];
      final second = slots[i + 1];
      final firstItems = cosmetic.itemsOfSlot(first.slot);
      final secondItems = cosmetic.itemsOfSlot(second.slot);
      if (firstItems.isEmpty || secondItems.isEmpty) continue;

      sections.add(
        _ComboSection(
          title: '${first.nameKo} × ${second.nameKo}',
          description: '겹쳐 그리는 순서가 붙어 있는 두 자리',
          combos: [
            for (final a in firstItems)
              for (final b in secondItems)
                _Combo(
                  label: '${_short(a)}+${_short(b)}',
                  layers: _layersOf({
                    first.slot: a.itemKey,
                    second.slot: b.itemKey,
                  }),
                ),
          ],
        ),
      );
    }
    return sections;
  }

  /// 이 차림을 그릴 층들.
  ///
  /// 옷장과 같은 길로 만든다. [CosmeticProvider] 는 지금 입고 있는 것만
  /// 돌려주므로, 임의의 조합은 카탈로그에서 직접 펼친다. 더미를 읽기만 한다.
  List<CosmeticLayerModel> _layersOf(Map<String, String> equipped) {
    return CosmeticMockData.loadout.resolveLayers(equippedOverride: equipped);
  }

  /// 칸 이름이 길어지지 않게 앞 네 글자만 쓴다.
  String _short(CosmeticItemModel item) {
    final name = item.nameKo;
    return name.length <= 4 ? name : name.substring(0, 4);
  }
}

/// 격자 한 묶음.
class _ComboSection {
  final String title;
  final String description;
  final List<_Combo> combos;

  const _ComboSection({
    required this.title,
    required this.description,
    required this.combos,
  });
}

/// 격자 한 칸.
class _Combo {
  final String label;
  final List<CosmeticLayerModel> layers;

  const _Combo({required this.label, required this.layers});
}
