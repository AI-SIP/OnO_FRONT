import 'dart:async';

import 'package:flutter/material.dart';

import '../Text/HandWriteText.dart';
import 'AppMotion.dart';

/// 손글씨 문구가 왼쪽부터 써지듯 드러난다.
///
/// 그동안 스플래시는 `animated_text_kit` 의 타자기 효과로 글자를 한 자씩
/// 찍었는데, 손글씨 글씨체에 타자기 효과를 얹으면 글씨를 쓰는 것이 아니라
/// 자판을 두드리는 것처럼 보였다. 획이 이어지는 글씨체와 맞지 않는다.
///
/// 여기서는 완성된 문구를 [ShaderMask] 로 가려 두고 가리개를 왼쪽에서
/// 오른쪽으로 걷는다. 실제 획순은 아니지만 손이 지나간 자리만 글씨가 남는
/// 것처럼 보이고, [penTip] 을 켜면 걷히는 경계에 펜촉이 같이 움직여서 쓰는
/// 느낌이 분명해진다.
///
/// ```dart
/// HandwritingReveal(
///   text: '"나만의 진정한 오답노트, OnO"',
///   fontSize: 28,
///   color: Colors.white,
///   onCompleted: () => _writingDone.complete(),
/// )
/// ```
///
/// 획을 진짜로 따라 그리려면 문구를 획 경로 SVG 로 만들어 `PathMetric` 으로
/// 그려야 하는데, 그렇게 하면 문구를 코드에서 바꿀 수 없게 된다. 문구가
/// 확정되지 않은 동안에는 이쪽이 낫다.
///
/// 한 줄짜리 문구를 전제로 한다. 가리개가 화면 가로 방향으로만 움직이므로
/// 두 줄을 넣으면 두 줄이 같이 드러나서 써지는 것처럼 보이지 않는다.
class HandwritingReveal extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;

  /// 문구가 다 써지기까지 걸리는 시간. [underline] 을 켜면 밑줄을 긋는
  /// 시간까지 포함한 값이다.
  final Duration duration;

  /// 시작을 미루는 시간. 위에 있는 그림이 자리를 잡은 뒤에 쓰기 시작하도록
  /// 늦출 때 쓴다.
  final Duration delay;

  /// 걷히는 경계를 따라 움직이는 펜촉을 그릴지.
  final bool penTip;

  /// 문구를 다 쓴 뒤 아래에 선을 한 번 그을지.
  final bool underline;

  /// 밑줄까지 끝났을 때 한 번 불린다. 움직임을 끈 기기에서는 그릴 것이 없어
  /// 첫 프레임 뒤에 바로 불린다. 이 콜백으로 다음 화면으로 넘어가는 흐름을
  /// 이어 붙이는 곳이 있어서 어느 경우에도 반드시 불려야 한다.
  final VoidCallback? onCompleted;

  const HandwritingReveal({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 24,
    this.fontWeight = FontWeight.bold,
    this.duration = const Duration(milliseconds: 1100),
    this.delay = Duration.zero,
    this.penTip = false,
    this.underline = false,
    this.onCompleted,
  });

  @override
  State<HandwritingReveal> createState() => _HandwritingRevealState();
}

class _HandwritingRevealState extends State<HandwritingReveal>
    with SingleTickerProviderStateMixin {
  /// 움직임을 끈 기기에서는 이것을 한 번도 쓰지 않는다. 그래도 `late` 로
  /// 미뤄 두면 안 된다. 그러면 dispose 에서 처음 만들어지는데, 그 시점에는
  /// element 가 이미 비활성이라 Ticker 가 조상을 찾다가 죽는다.
  late final AnimationController _controller;

  /// 밑줄이 있으면 글씨를 먼저 다 쓰고 나서 긋는다. 둘이 겹치면 무엇이
  /// 그려지는지 읽히지 않는다.
  late final Animation<double> _write;

  late final Animation<double> _line;

  Timer? _startTimer;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _write = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0.0,
        widget.underline ? 0.72 : 1.0,
        curve: AppMotion.standard,
      ),
    );
    _line = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 1.0, curve: AppMotion.enter),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handled) return;
    _handled = true;

    // 기기 설정에서 움직임을 끈 사용자에게는 그릴 것이 없다. 그래도 다음
    // 화면으로 넘어가는 쪽이 이 콜백을 기다리고 있으므로 불러 주어야 한다.
    if (AppMotion.isReduced(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCompleted?.call();
      });
      return;
    }

    if (widget.delay == Duration.zero) {
      _start();
      return;
    }
    _startTimer = Timer(widget.delay, _start);
  }

  void _start() {
    if (!mounted) return;
    _controller.forward().whenComplete(() {
      if (mounted) widget.onCompleted?.call();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = HandWriteText(
      text: widget.text,
      color: widget.color,
      fontSize: widget.fontSize,
      fontWeight: widget.fontWeight,
    );

    if (AppMotion.isReduced(context)) return text;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final written = _write.value;
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            _mask(written, text),
            if (widget.underline)
              Positioned.fill(
                child: CustomPaint(
                  painter: _UnderlinePainter(
                    color: widget.color,
                    progress: _line.value,
                    strokeWidth: widget.fontSize * 0.06,
                  ),
                ),
              ),
            if (widget.penTip && written > 0 && written < 1)
              Positioned.fill(child: _pen(written)),
          ],
        );
      },
    );
  }

  /// 완성된 글씨 위에 가리개를 덮고 왼쪽부터 걷는다.
  ///
  /// [BlendMode.dstIn] 은 아래 그림의 투명도를 이 그라데이션의 투명도로
  /// 바꾼다. 흰 부분은 글씨가 남고 투명한 부분은 지워진다. 경계를 딱
  /// 떨어뜨리면 종이를 자른 것처럼 보여서 [_softEdge] 만큼 흐리게 둔다.
  Widget _mask(double progress, Widget child) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final edge = progress.clamp(0.0, 1.0);
        final soft = (edge - _softEdge).clamp(0.0, 1.0);
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Colors.white,
            Colors.white,
            Colors.transparent,
            Colors.transparent,
          ],
          stops: [0.0, soft, edge, 1.0],
        ).createShader(bounds);
      },
      child: child,
    );
  }

  /// 걷히는 경계에 얹는 펜촉이다. 글씨 아래쪽을 따라가야 방금 그은 자리처럼
  /// 보여서 세로로는 조금 내려 둔다.
  Widget _pen(double progress) {
    return Align(
      alignment: Alignment(progress * 2 - 1, 0.55),
      child: Container(
        width: widget.fontSize * 0.16,
        height: widget.fontSize * 0.16,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// 가리개 경계를 흐리는 폭. 글씨 폭에 대한 비율이다.
  static const double _softEdge = 0.06;
}

/// 문구 아래에 왼쪽부터 그어지는 선이다.
class _UnderlinePainter extends CustomPainter {
  final Color color;

  /// 0 이면 아직 아무것도 안 그렸고 1 이면 끝까지 그었다.
  final double progress;
  final double strokeWidth;

  _UnderlinePainter({
    required this.color,
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // 손으로 그은 선처럼 보이도록 양 끝을 조금 들여 긋고 가운데를 아주 살짝
    // 내린다. 자로 잰 직선은 손글씨 옆에서 튄다.
    final left = size.width * 0.02;
    final right = size.width * 0.98;
    final y = size.height * 0.92;
    final end = left + (right - left) * progress.clamp(0.0, 1.0);

    final path = Path()
      ..moveTo(left, y)
      ..quadraticBezierTo((left + end) / 2, y + strokeWidth * 0.9, end, y);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
