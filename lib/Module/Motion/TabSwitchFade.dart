import 'package:flutter/material.dart';

import 'AppMotion.dart';

/// 하단 탭을 옮길 때 내용이 부드럽게 바뀌게 한다.
///
/// 홈은 탭 다섯을 `IndexedStack` 으로 들고 있어서 탭을 누르면 화면이 즉시
/// 교체된다. 스크롤 위치와 불러온 데이터를 유지하려면 `IndexedStack` 이
/// 필요하지만, 그래서 전환이 뚝 끊긴다.
///
/// 자식을 갈아 끼우는 대신 [index] 가 바뀔 때 잠깐 흐려졌다 돌아오게 한다.
/// 완전히 사라졌다 나타나면 깜빡이는 것처럼 보여서 [_dimmedOpacity] 까지만
/// 흐려진다. `IndexedStack` 자체는 그대로 두므로 상태도 유지된다.
///
/// ```dart
/// TabSwitchFade(
///   index: screenIndex,
///   child: IndexedStack(index: screenIndex, children: tabs),
/// )
/// ```
class TabSwitchFade extends StatefulWidget {
  /// 지금 선택된 탭. 이 값이 바뀔 때마다 재생된다.
  final int index;

  final Widget child;

  const TabSwitchFade({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<TabSwitchFade> createState() => _TabSwitchFadeState();
}

class _TabSwitchFadeState extends State<TabSwitchFade>
    with SingleTickerProviderStateMixin {
  /// 흐려지는 정도. 0 에 가까울수록 깜빡임이 커진다.
  static const double _dimmedOpacity = 0.55;

  /// 시작 크기. 화면 전환과 같은 느낌을 주되 더 조용해야 한다.
  static const double _dimmedScale = 0.99;

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.normal,
      // 처음 그릴 때는 이미 다 보이는 상태로 둔다.
      value: 1.0,
    );
    _opacity = Tween<double>(begin: _dimmedOpacity, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.standard),
    );
    _scale = Tween<double>(begin: _dimmedScale, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.enter),
    );
  }

  @override
  void didUpdateWidget(TabSwitchFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 흐려졌다 돌아오기만 하면 탭이 바뀐 것이 잘 안 느껴진다. 화면을 여는
    // 것과 같은 결로, 살짝 작은 상태에서 제 크기로 자리 잡게 한다.
    if (AppMotion.isReduced(context)) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
    );
  }
}
