import 'package:flutter/material.dart';

import 'AppMotion.dart';
import 'SelectionPop.dart';

/// 하단 탭이 선택될 때 아이콘이 한 번 튀어오른다.
///
/// `BottomNavigationBar` 의 기본 동작은 아이콘 색만 바뀌어서, 탭을 눌렀는지
/// 아닌지가 손끝에 걸리지 않는다. 눌린 탭을 살짝 키웠다 되돌리고 테두리
/// 아이콘을 꽉 찬 아이콘으로 바꿔서 "여기로 넘어왔다"가 보이게 한다.
///
/// `BottomNavigationBarItem.icon` 자리에 넣고 [selected] 를 넘긴다.
/// `activeIcon` 은 따로 주지 않는다. 선택 여부를 이 위젯이 직접 알아야
/// 튀어오르는 시점을 잡을 수 있기 때문이다.
class BouncyNavIcon extends StatelessWidget {
  /// 선택되지 않았을 때의 아이콘. 보통 테두리만 있는 쪽이다.
  final IconData icon;

  /// 선택됐을 때의 아이콘. 보통 꽉 찬 쪽이다.
  final IconData activeIcon;

  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const BouncyNavIcon({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;

    return SelectionPop(
      selected: selected,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        builder: (context, animatedColor, _) {
          return Icon(
            selected ? activeIcon : icon,
            size: size,
            color: animatedColor ?? color,
          );
        },
      ),
    );
  }
}
