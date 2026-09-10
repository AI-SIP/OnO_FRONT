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
  // 늦게(late) 만들지 않고 initState 에서 바로 만든다. 늦게 만들면 "동작
  // 줄이기"를 켠 기기에서 build 가 컨트롤러를 건드리지 않은 채 끝나고,
  // dispose 가 그제서야 컨트롤러를 만들면서 이미 트리에서 빠진 위젯의 조상을
  // 찾다가 죽는다. (알림이 뜨고 사라질 때마다 났다)
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.page);

    /// 되돌아오는 구간에 시간을 더 준다. 앞뒤가 같으면 튕겼다기보다 깜빡인
    /// 것처럼 보인다.
    _scale = TweenSequence<double>([
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
  }

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
    if (AppMotion.isReduced(context)) return widget.child;

    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
