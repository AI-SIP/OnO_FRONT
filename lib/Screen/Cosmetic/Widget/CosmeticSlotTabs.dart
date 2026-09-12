import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticSlotModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Text/StandardText.dart';

/// 옷장에서 걸 자리(슬롯)를 고르는 탭이다.
///
/// **흰 알약은 하나뿐이고, 그것이 좌우로 미끄러진다.** 미션 화면의
/// MissionSegments 와 같은 이유다. 칸마다 각자 배경을 켜고 끄면 바뀌는
/// 동안 한쪽은 흐려지는 중이고 다른 쪽은 밝아지는 중이라 둘 다 회색으로
/// 보인다. 알약이 하나면 어느 순간에도 고른 칸이 비어 있지 않다.
///
/// 미션은 칸이 둘뿐이라 화면을 반씩 나눠 쓰지만, 자리는 여덟 개이고 더 늘어날
/// 예정이다. 그래서 칸 너비를 글자 길이로 재고, 다 들어가지 않으면 옆으로
/// 밀어서 본다. 고른 칸은 가운데로 끌어다 놓는다.
class CosmeticSlotTabs extends StatefulWidget {
  /// 보여 줄 자리들. `CosmeticProvider.slots` 를 그대로 넘긴다.
  final List<CosmeticSlotModel> slots;

  /// 지금 고른 칸.
  final int index;

  /// 강조색. 사용자가 테마에서 고른 색이다.
  final Color color;

  final ValueChanged<int> onChanged;

  const CosmeticSlotTabs({
    super.key,
    required this.slots,
    required this.index,
    required this.color,
    required this.onChanged,
  });

  /// 미끄러지는 흰 알약을 테스트에서 찾는 키.
  static const Key pillKey = Key('cosmetic_slot_pill');

  /// 자리 이름의 크기. 여덟 칸이 보통 폰의 한 줄에 들어가야 해서 본문보다
  /// 한 단계 작다.
  static const double _fontSize = 13.0;

  /// 칸 안쪽 좌우 여백. 글자 너비에 이만큼 더한 것이 칸 너비다.
  static const double _labelPadding = 10.0;

  /// 칸 하나의 가장 좁은 너비. 한 글자짜리 이름(`옷`, `손`)이 점처럼 보이지
  /// 않게 바닥을 둔다.
  static const double _minTabWidth = 40.0;

  @override
  State<CosmeticSlotTabs> createState() => _CosmeticSlotTabsState();
}

class _CosmeticSlotTabsState extends State<CosmeticSlotTabs> {
  final ScrollController _scrollController = ScrollController();

  /// 마지막으로 계산한 칸 너비들. 고른 칸을 끌어다 놓을 때 다시 쓴다.
  List<double> _widths = const [];

  /// 마지막으로 본 탭 줄의 너비.
  double _viewport = 0;

  @override
  void didUpdateWidget(covariant CosmeticSlotTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _revealSelected();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 고른 칸이 화면 밖에 있으면 가운데로 끌어다 놓는다.
  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (widget.index < 0 || widget.index >= _widths.length) return;

      var start = 0.0;
      for (var i = 0; i < widget.index; i++) {
        start += _widths[i];
      }

      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return;

      final target =
          (start + _widths[widget.index] / 2 - _viewport / 2).clamp(0.0, max);
      if (AppMotion.isReduced(context)) {
        _scrollController.jumpTo(target);
        return;
      }
      _scrollController.animateTo(
        target,
        duration: AppMotion.normal,
        curve: AppMotion.emphasized,
      );
    });
  }

  /// 이름 하나가 차지하는 너비를 잰다.
  ///
  /// 자리 이름은 서버가 주는 값이라 길이를 미리 알 수 없다. 글자를 실제로
  /// 재야 `배경` 과 `옷` 이 같은 폭으로 어색하게 벌어지지 않는다.
  double _measure(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slots.isEmpty) return const SizedBox.shrink();

    final reduced = AppMotion.isReduced(context);
    const labelStyle = TextStyle(
      fontFamily: 'PretendardBold',
      fontSize: CosmeticSlotTabs._fontSize,
      fontWeight: FontWeight.bold,
      height: 1.8,
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth;
          final widths = <double>[
            for (final slot in widget.slots)
              (_measure(slot.nameKo, labelStyle) +
                      CosmeticSlotTabs._labelPadding * 2)
                  .clamp(CosmeticSlotTabs._minTabWidth, double.infinity),
          ];

          var total = widths.fold<double>(0, (sum, width) => sum + width);

          // 남는 자리가 있으면 칸들이 고르게 나눠 갖는다. 여덟 개가 왼쪽에만
          // 몰려 있고 오른쪽이 비어 있으면 잘린 것처럼 보인다.
          if (total < available && widths.isNotEmpty) {
            final extra = (available - total) / widths.length;
            for (var i = 0; i < widths.length; i++) {
              widths[i] += extra;
            }
            total = available;
          }

          _widths = widths;
          _viewport = available;

          var offset = 0.0;
          final offsets = <double>[];
          for (final width in widths) {
            offsets.add(offset);
            offset += width;
          }

          final index = widget.index.clamp(0, widths.length - 1);

          final row = SizedBox(
            width: total,
            child: Stack(
              children: [
                // 알약이 먼저 깔리고 글자가 그 위에 얹힌다.
                AnimatedPositioned(
                  duration: reduced ? Duration.zero : AppMotion.normal,
                  curve: AppMotion.emphasized,
                  left: offsets[index],
                  width: widths[index],
                  top: 0,
                  bottom: 0,
                  child: Container(
                    key: CosmeticSlotTabs.pillKey,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < widget.slots.length; i++)
                      SizedBox(
                        width: widths[i],
                        child: PressableScale(
                          onTap: () {
                            if (widget.index == i) return;
                            AppHaptic.selection();
                            widget.onChanged(i);
                          },
                          haptic: HapticLevel.none,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: StandardText(
                              text: widget.slots[i].nameKo,
                              fontSize: CosmeticSlotTabs._fontSize,
                              color: index == i
                                  ? widget.color
                                  : AppColors.textTertiary,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );

          // 다 들어가면 스크롤 자체를 만들지 않는다. 스크롤이 걸려 있으면
          // 손가락이 미끄러질 때 탭 줄이 괜히 흔들린다.
          if (total <= available) return row;

          return SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: row,
          );
        },
      ),
    );
  }
}
