import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/SelectionPop.dart';
import '../../User/Widget/FrogCharacter.dart';

/// 캐릭터 탭의 하단 아이콘이다. **사용자가 꾸민 개구리 얼굴 그대로**다.
///
/// 다른 넷은 선 아이콘인데 여기만 그림인 이유가 있다. 이 탭은 기능이 아니라
/// 내 개구리다. 옷을 갈아입히면 하단 탭의 얼굴도 같이 바뀌는 것이, 무엇을
/// 꾸몄는지 앱 어디에 있든 눈에 들어오게 한다. 아이콘 하나 고르는 것으로
/// 끝냈으면 이 탭은 다른 넷과 구별되지 않는다.
///
/// 안 고른 탭에서는 회색으로 뺀다. 다섯 칸 중 하나만 늘 컬러로 떠 있으면
/// 어느 탭에 있든 눈이 그리로 끌려간다.
class FrogNavIcon extends StatelessWidget {
  /// 겹쳐 그릴 층들. `CosmeticProvider.layers` 를 그대로 넘긴다.
  final List<CosmeticLayerModel> layers;

  final bool selected;

  /// 고른 탭의 테두리 색. 사용자가 테마에서 고른 색이다.
  final Color activeColor;

  final double size;

  const FrogNavIcon({
    super.key,
    required this.layers,
    required this.selected,
    required this.activeColor,
    this.size = 24,
  });

  /// 색을 빼는 행렬. 사람 눈이 느끼는 밝기 비율(0.2126 / 0.7152 / 0.0722)로
  /// 섞는다. 셋을 균등하게 나누면 초록 개구리가 실제보다 어둡게 죽는다.
  static const List<double> _grayscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    final frog = FrogHeadAvatar(layers: layers, size: size);

    return SelectionPop(
      selected: selected,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.55)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: selected
            ? frog
            : Opacity(
                opacity: 0.55,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(_grayscale),
                  child: frog,
                ),
              ),
      ),
    );
  }
}
