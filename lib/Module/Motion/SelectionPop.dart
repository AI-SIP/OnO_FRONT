import 'package:flutter/material.dart';

import 'AppMotion.dart';

/// 선택이 켜지는 순간 한 번 커졌다가 제자리로 돌아온다.
///
/// 체크박스나 탭 아이콘처럼 켜고 끄는 것들은 색만 바뀌면 눌렀는지가 눈에 잘
/// 안 들어온다. 짧게 튀어오르면 손끝에서 일어난 일이 화면에서 확인된다.
///
/// 선택이 풀릴 때는 튀지 않는다. 끄는 동작까지 튀면 목록에서 여러 개를
/// 골랐다 풀었다 할 때 화면이 계속 들썩인다.
class SelectionPop extends StatefulWidget {
  final bool selected;
  final Widget child;

  /// 가장 커졌을 때의 배율.
  final double peak;

  const SelectionPop({
    super.key,
    required this.selected,
    required this.child,
    this.peak = 1.22,
  });

  @override
  State<SelectionPop> createState() => _SelectionPopState();
}

class _SelectionPopState extends State<SelectionPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.page,
  );

  /// 되돌아오는 구간에 시간을 더 준다. 앞뒤가 같으면 튕겼다기보다 깜빡인
  /// 것처럼 보인다.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.0, end: widget.peak)
          .chain(CurveTween(curve: AppMotion.enter)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: widget.peak, end: 1.0)
          .chain(CurveTween(curve: AppMotion.emphasized)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant SelectionPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
