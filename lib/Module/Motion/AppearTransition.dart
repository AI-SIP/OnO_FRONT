import 'dart:async';

import 'package:flutter/material.dart';

import 'AppMotion.dart';

/// 화면에 처음 그려질 때 옅게 나타나면서 살짝 올라온다.
///
/// 데이터를 받아온 목록이나 검색 결과가 툭 나타나는 대신 부드럽게 들어오게
/// 만든다. 한 번만 재생하고 끝난다.
///
/// ```dart
/// AppearTransition(child: SearchResultCard(problem: problem))
/// ```
///
/// 목록에 쓸 때는 [stagger] 로 항목마다 지연을 매겨 하나씩 들어오게 한다.
class AppearTransition extends StatefulWidget {
  final Widget child;

  /// 시작을 미루는 시간.
  final Duration delay;

  final Duration duration;
  final Curve curve;

  /// 아래에서 올라오는 거리. 0 이면 투명도만 변한다.
  final double offset;

  /// false 면 애니메이션 없이 그대로 그린다. 화면 테스트나 저사양 대응에 쓴다.
  final bool enabled;

  const AppearTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.curve = AppMotion.enter,
    this.offset = AppMotion.enterOffset,
    this.enabled = true,
  });

  /// [children] 에 순서대로 지연을 매겨 하나씩 나타나게 감싼다.
  ///
  /// 항목이 많을 때 끝까지 지연을 매기면 마지막 것이 한참 뒤에 나타나므로
  /// [maxStaggered] 번째까지만 어긋나게 하고 나머지는 같은 시점에 들어온다.
  static List<Widget> stagger(
    List<Widget> children, {
    Duration interval = AppMotion.stagger,
    Duration initialDelay = Duration.zero,
    int maxStaggered = 8,
    Duration duration = AppMotion.slow,
    double offset = AppMotion.enterOffset,
    bool enabled = true,
  }) {
    return List<Widget>.generate(children.length, (index) {
      final steps = index < maxStaggered ? index : maxStaggered;
      return AppearTransition(
        delay: initialDelay + interval * steps,
        duration: duration,
        offset: offset,
        enabled: enabled,
        child: children[index],
      );
    });
  }

  @override
  State<AppearTransition> createState() => _AppearTransitionState();
}

class _AppearTransitionState extends State<AppearTransition> {
  bool _started = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled || widget.delay == Duration.zero) {
      _started = true;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      setState(() => _started = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _started ? 1.0 : 0.0),
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}
