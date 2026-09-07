import 'package:flutter/material.dart';

import 'AppMotion.dart';

/// 화면이 열릴 때 내용이 살짝 커지며 자리를 잡는다.
///
/// 좌우로 밀려 들어오는 전환만 있으면 화면이 통째로 이동할 뿐, 도착한 뒤에는
/// 정지 화면이 붙은 것처럼 보인다. 밀려 들어오는 것과 거의 같이, 내용이
/// 아주 살짝 작은 상태에서 제 크기로 자리 잡으면 "떴다"는 느낌이 난다.
///
/// 값을 크게 잡으면 화면마다 튀어나오는 것처럼 보여 금방 피로해진다. 눈에
/// 띄지 않을 만큼만 준다.
///
/// [TossPageRoute] 가 모든 화면을 이걸로 감싸므로 화면 쪽에서 따로 쓸 일은
/// 거의 없다.
class ScreenEnterTransition extends StatefulWidget {
  final Widget child;

  /// 시작 크기. 1.0 에 가까울수록 조용하다.
  final double beginScale;

  const ScreenEnterTransition({
    super.key,
    required this.child,
    this.beginScale = 0.985,
  });

  @override
  State<ScreenEnterTransition> createState() => _ScreenEnterTransitionState();
}

class _ScreenEnterTransitionState extends State<ScreenEnterTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: widget.beginScale,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.enter));

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.85,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
