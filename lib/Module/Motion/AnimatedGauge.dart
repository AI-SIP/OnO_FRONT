import 'dart:async';

import 'package:flutter/material.dart';

import 'AppMotion.dart';
import 'MotionReplayScope.dart';

/// 0 에서 목표값까지 차오르는 값을 만들어 [builder] 에 넘긴다.
///
/// 화면에 처음 그려질 때 0 에서 시작하고, [value] 가 나중에 바뀌면 그때 있던
/// 값에서 새 값까지 이어서 움직인다. 게이지든 숫자든 진행 원이든 "차오르는"
/// 표현이 필요하면 이걸 쓴다.
///
/// ```dart
/// AnimatedGaugeValue(
///   value: 0.7,
///   builder: (context, value) => LinearProgressIndicator(value: value),
/// )
/// ```
class AnimatedGaugeValue extends StatefulWidget {
  /// 도달할 값.
  final double value;

  final Duration duration;
  final Curve curve;

  /// 시작을 미루는 시간. 카드 여러 개가 한 화면에 있을 때 조금씩 어긋나게
  /// 두면 하나씩 차오르는 것처럼 보인다.
  final Duration delay;

  final Widget Function(BuildContext context, double value) builder;

  const AnimatedGaugeValue({
    super.key,
    required this.value,
    required this.builder,
    this.duration = AppMotion.gauge,
    this.curve = AppMotion.emphasized,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedGaugeValue> createState() => _AnimatedGaugeValueState();
}

class _AnimatedGaugeValueState extends State<AnimatedGaugeValue>
    with MotionReplayMixin<AnimatedGaugeValue> {
  /// [delay] 가 지나기 전에는 0 에 머문다.
  bool _started = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _started = true;
      return;
    }
    _startAfterDelay();
  }

  void _startAfterDelay() {
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      setState(() => _started = true);
    });
  }

  /// 화면이 다시 보일 때 0 부터 다시 차오르게 한다.
  ///
  /// 여기서는 setState 를 부르지 않는다. 이 메서드는 build 직전에 불리므로
  /// 값만 되돌려 두면 뒤따르는 build 가 반영한다.
  @override
  void onMotionReplay() {
    _timer?.cancel();
    _started = false;

    if (widget.delay != Duration.zero) {
      _startAfterDelay();
      return;
    }
    // 지연이 없어도 한 프레임은 0 으로 그려야 차오르는 것이 보인다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    if (AppMotion.isReduced(context)) {
      return widget.builder(context, widget.value);
    }

    return TweenAnimationBuilder<double>(
      // key 가 바뀌면 위젯이 새로 만들어져 begin 부터 다시 그린다. 값만
      // 0 으로 되돌리면 되돌아가는 과정까지 애니메이션으로 보인다.
      key: ValueKey<int>(replaySeed),
      tween: Tween<double>(begin: 0.0, end: _started ? widget.value : 0.0),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, _) => widget.builder(context, value),
    );
  }
}

/// 차오르는 가로 막대다. `LinearProgressIndicator` 를 대신한다.
///
/// 모서리를 직접 둥글게 깎으므로 바깥에서 `ClipRRect` 로 감쌀 필요가 없다.
class AnimatedLinearGauge extends StatelessWidget {
  /// 0 에서 1 사이. 벗어난 값은 잘라서 쓴다.
  final double value;

  final Color color;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;
  final Duration duration;
  final Curve curve;
  final Duration delay;

  const AnimatedLinearGauge({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor,
    this.height = 6.0,
    this.borderRadius = 4.0,
    this.duration = AppMotion.gauge,
    this.curve = AppMotion.emphasized,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return AnimatedGaugeValue(
      value: value.clamp(0.0, 1.0),
      duration: duration,
      curve: curve,
      delay: delay,
      builder: (context, current) => ClipRRect(
        borderRadius: radius,
        child: Container(
          height: height,
          color: backgroundColor ?? Colors.grey[100],
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: current,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: radius),
            ),
          ),
        ),
      ),
    );
  }
}

/// 차오르는 진행 원이다. 마이 페이지의 학습 레벨 도넛처럼 가운데에 글자를
/// 넣어야 하는 곳에서 [child] 를 함께 준다.
class AnimatedCircularGauge extends StatelessWidget {
  /// 0 에서 1 사이. 벗어난 값은 잘라서 쓴다.
  final double value;

  final Color color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;

  /// 원 가운데에 놓을 것.
  final Widget? child;

  final Duration duration;
  final Curve curve;
  final Duration delay;

  const AnimatedCircularGauge({
    super.key,
    required this.value,
    required this.color,
    required this.size,
    this.backgroundColor,
    this.strokeWidth = 9.0,
    this.child,
    this.duration = AppMotion.gauge,
    this.curve = AppMotion.emphasized,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedGaugeValue(
            value: value.clamp(0.0, 1.0),
            duration: duration,
            curve: curve,
            delay: delay,
            builder: (context, current) => SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: current,
                strokeWidth: strokeWidth,
                backgroundColor: backgroundColor ?? Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
