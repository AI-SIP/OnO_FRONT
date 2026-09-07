import 'package:flutter/material.dart';

import 'AppHaptic.dart';
import 'AppMotion.dart';

/// 흐름이 끝났을 때 원이 퍼지고 체크가 그어지는 표시다.
///
/// 오답노트를 다 쓰거나 복습을 마쳤을 때 화면만 바뀌면 끝났다는 느낌이 없다.
/// 짧게 한 번 확인해 주면 그 자리에서 마무리됐다는 것이 보인다.
///
/// Lottie 같은 것을 얹지 않고 [CustomPainter] 로 그린다. 체크 표시 하나를
/// 위해 애니메이션 패키지를 하나 더 들이는 것보다 이쪽이 가볍다.
class SuccessCheck extends StatefulWidget {
  final double size;
  final Color color;

  /// 원 안을 채우는 색. 주지 않으면 [color] 를 옅게 깐다.
  final Color? backgroundColor;

  /// 그리기가 끝났을 때 한 번 불린다.
  final VoidCallback? onCompleted;

  /// 표시가 뜨는 순간 진동을 줄지.
  final bool haptic;

  const SuccessCheck({
    super.key,
    this.size = 72,
    required this.color,
    this.backgroundColor,
    this.onCompleted,
    this.haptic = true,
  });

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  /// 원이 먼저 자리를 잡고, 그 위에 체크가 그어진다. 둘이 동시에 움직이면
  /// 무엇이 그려지는지 읽히지 않는다.
  late final Animation<double> _circle = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.45, curve: AppMotion.emphasized),
  );

  late final Animation<double> _check = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1.0, curve: AppMotion.enter),
  );

  @override
  void initState() {
    super.initState();
    if (widget.haptic) AppHaptic.primary();
    _controller.forward().whenComplete(() {
      if (mounted) widget.onCompleted?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background =
        widget.backgroundColor ?? widget.color.withValues(alpha: 0.12);

    // 움직임을 끈 사용자에게는 다 그려진 모습만 보인다.
    if (AppMotion.isReduced(context)) {
      return _paint(background, circle: 1, check: 1);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _paint(
        background,
        circle: _circle.value,
        check: _check.value,
      ),
    );
  }

  Widget _paint(Color background,
      {required double circle, required double check}) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Transform.scale(
        scale: circle,
        child: CustomPaint(
          painter: _SuccessCheckPainter(
            color: widget.color,
            background: background,
            progress: check,
          ),
        ),
      ),
    );
  }
}

class _SuccessCheckPainter extends CustomPainter {
  final Color color;
  final Color background;

  /// 체크를 얼마나 그었는지. 0 이면 아직 원만 있다.
  final double progress;

  _SuccessCheckPainter({
    required this.color,
    required this.background,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2, Paint()..color = background);

    if (progress <= 0) return;

    // 체크는 꺾인 선 두 개다. 짧은 쪽을 먼저 긋고 긴 쪽으로 넘어간다.
    final start = Offset(size.width * 0.28, size.height * 0.52);
    final corner = Offset(size.width * 0.44, size.height * 0.68);
    final end = Offset(size.width * 0.74, size.height * 0.35);

    final firstLength = (corner - start).distance;
    final secondLength = (end - corner).distance;
    final total = firstLength + secondLength;
    final drawn = total * progress;

    final path = Path()..moveTo(start.dx, start.dy);
    if (drawn <= firstLength) {
      final t = firstLength == 0 ? 1.0 : drawn / firstLength;
      final p = Offset.lerp(start, corner, t)!;
      path.lineTo(p.dx, p.dy);
    } else {
      path.lineTo(corner.dx, corner.dy);
      final t = secondLength == 0 ? 1.0 : (drawn - firstLength) / secondLength;
      final p = Offset.lerp(corner, end, t)!;
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SuccessCheckPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.background != background;
}
