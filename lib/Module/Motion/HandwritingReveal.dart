import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../Text/HandWriteText.dart';
import 'AppMotion.dart';

/// 손글씨 문구를 연필이 지나가며 적는다.
///
/// 그동안 스플래시는 `animated_text_kit` 의 타자기 효과로 글자를 한 자씩
/// 찍었는데, 손글씨 글씨체에 타자기 효과를 얹으면 글씨를 쓰는 것이 아니라
/// 자판을 두드리는 것처럼 보였다.
///
/// 여기서는 완성된 문구를 [ShaderMask] 로 가려 두고 가리개를 왼쪽에서
/// 오른쪽으로 걷으면서, 걷히는 자리에 연필을 얹어 같이 움직인다. 가리개만
/// 걷으면 글씨가 저절로 돋아나는 것처럼 보이고, 연필이 있어야 무언가가
/// 지나가면서 적는 것으로 읽힌다.
///
/// ```dart
/// HandwritingReveal(
///   text: '"나만의 진정한 오답노트, OnO"',
///   fontSize: 28,
///   color: Colors.white,
///   pencil: true,
///   onCompleted: () => _writingDone.complete(),
/// )
/// ```
///
/// 획을 실제 순서대로 그으려면 글자마다 획의 중심선 좌표가 있어야 한다.
/// 폰트에서 뽑을 수 있는 것은 글자의 바깥 윤곽이라 그것을 따라 그리면 글씨를
/// 쓰는 것이 아니라 테두리를 덧그리는 모양이 된다. 한글 획순 데이터를 문구마다
/// 따로 만들지 않는 한 여기까지가 한계다.
///
/// 한 줄짜리 문구를 전제로 한다. 가리개가 가로로만 움직이므로 두 줄을 넣으면
/// 두 줄이 같이 드러나서 적는 것처럼 보이지 않는다.
class HandwritingReveal extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;

  /// 문구가 다 써지기까지 걸리는 시간. [underline] 을 켜면 밑줄을 긋는
  /// 시간까지 포함한 값이다.
  ///
  /// 손으로 쓰는 속도에 맞춰야 한다. 짧게 잡으면 글씨가 써지는 것이 아니라
  /// 가리개가 스쳐 지나간 것처럼 보인다. 열몇 자짜리 문구에 1.5초 정도가
  /// 적당하고, 문구가 길어지면 같이 늘려야 한다.
  final Duration duration;

  /// 시작을 미루는 시간. 위에 있는 그림이 자리를 잡은 뒤에 쓰기 시작하도록
  /// 늦출 때 쓴다.
  final Duration delay;

  /// 적는 자리에 연필을 얹을지.
  final bool pencil;

  /// 문구를 다 쓴 뒤 아래에 선을 한 번 그을지.
  final bool underline;

  /// 밑줄 색. 주지 않으면 글씨와 같은 색으로 긋는다.
  ///
  /// 공책에 중요한 줄을 다른 색으로 밑줄 치는 것처럼, 글씨와 다른 색을 쓸 수
  /// 있게 열어 둔다.
  final Color? underlineColor;

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
    this.duration = const Duration(milliseconds: 1500),
    this.delay = Duration.zero,
    this.pencil = false,
    this.underline = false,
    this.underlineColor,
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

    // 쓰는 구간은 [AppMotion] 의 커브를 쓰지 않고 등속으로 둔다. 글자 단위
    // 리듬은 아래 [_strokeOf] 에서 따로 만든다. 여기에 가속까지 붙으면 두
    // 리듬이 겹쳐서 속도가 들쭉날쭉해 보인다.
    _write = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0.0,
        widget.underline ? 0.78 : 1.0,
        curve: Curves.linear,
      ),
    );

    _line = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.78, 1.0, curve: AppMotion.enter),
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
        final stroke = _strokeOf(_write.value);
        return Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            _mask(stroke.progress, text),
            if (widget.underline)
              Positioned.fill(
                child: CustomPaint(
                  painter: _UnderlinePainter(
                    color: widget.underlineColor ?? widget.color,
                    progress: _line.value,
                    strokeWidth: widget.fontSize * 0.06,
                  ),
                ),
              ),
            if (widget.pencil && stroke.progress > 0 && stroke.progress < 1)
              Positioned.fill(child: _pencil(stroke)),
          ],
        );
      },
    );
  }

  /// 글자 하나를 긋고 잠깐 멈추는 리듬을 만든다.
  ///
  /// 가리개를 등속으로 밀면 글씨가 일정한 속도로 자라나기만 해서, 사람이 손을
  /// 움직이는 것이 아니라 무언가가 미끄러지는 것처럼 보인다. 사람은 글자
  /// 하나를 긋고 다음 글자로 넘어가기 전에 손을 아주 잠깐 뗀다. 그 리듬을
  /// 흉내 낸다.
  ///
  /// 글자를 긋는 동안에는 연필이 가로로만 가지 않는다. 획을 따라 위아래로
  /// 오르내리고 몸통도 같이 기운다. 옆으로만 미끄러지면 자를 대고 줄을 긋는
  /// 것처럼 보인다.
  ///
  /// [_StrokeState.lift] 는 글자와 글자 사이에서 1 에 가까워진다. 연필을 그만큼
  /// 종이에서 띄운다.
  _StrokeState _strokeOf(double raw) {
    final t = raw.clamp(0.0, 1.0);
    final count = widget.text.length;
    if (count <= 1 || t >= 1.0) {
      return const _StrokeState(progress: 1, lift: 0, bob: 0, tilt: 0);
    }

    final scaled = t * count;
    final index = scaled.floor().clamp(0, count - 1);
    final local = (scaled - index).clamp(0.0, 1.0);

    // 한 글자에 주어진 시간의 앞 %_drawRatio 동안 긋고 나머지는 멈춘다.
    final drawn = (local / _drawRatio).clamp(0.0, 1.0);
    final lift =
        local <= _drawRatio ? 0.0 : (local - _drawRatio) / (1 - _drawRatio);

    // 한 글자를 긋는 동안 위아래로 두 번 오르내린다. 획을 두어 개 긋는 셈이다.
    // 글자 사이에서 손을 뗄 때는 흔들림을 멎게 한다.
    final settle = 1 - lift;
    final bob = sin(drawn * pi * 2) * settle;
    final tilt = sin(drawn * pi * 2 + pi / 3) * settle;

    return _StrokeState(
      progress: (index + Curves.easeInOut.transform(drawn)) / count,
      lift: lift,
      bob: bob,
      tilt: tilt,
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

  /// 적는 자리에 얹는 연필이다.
  ///
  /// 그림의 심이 왼쪽 아래 모서리에 있고 몸통이 오른쪽 위로 뻗어 있다. 그래서
  /// 그림 상자를 오른쪽 위로 밀어 두면 심 끝이 글씨가 끝나는 자리에 닿는다.
  Widget _pencil(_StrokeState stroke) {
    final size = widget.fontSize * 1.7;

    final pencil = SvgPicture.asset(
      _pencilAsset,
      width: size,
      height: size,
    );

    return Align(
      alignment: Alignment(stroke.progress * 2 - 1, 1.0),
      child: Transform.translate(
        // 상자 가운데를 기준으로 그려지므로, 심 끝(상자의 왼쪽 아래)이 글씨
        // 끝에 오도록 오른쪽 위로 민다. 획을 긋는 동안에는 [bob] 만큼
        // 오르내리고, 글자와 글자 사이에서는 [lift] 만큼 종이에서 뗀다.
        offset: Offset(
          size * 0.46,
          -size * 0.44 - stroke.lift * size * 0.13 + stroke.bob * size * 0.05,
        ),
        child: Transform.rotate(
          // 심 끝을 축으로 몸통만 기운다. 가운데를 축으로 돌리면 심이 글씨에서
          // 떨어진다.
          angle: stroke.tilt * 0.07,
          alignment: const Alignment(-0.9, 0.9),
          child: pencil,
        ),
      ),
    );
  }

  /// 적는 연필 그림.
  ///
  /// 심이 왼쪽 아래에 오도록 기울어져 있어야 한다. 다른 그림으로 바꾸면
  /// [_pencil] 의 미는 거리도 같이 맞춰야 심 끝이 글씨에서 떨어지지 않는다.
  static const String _pencilAsset = 'assets/Icon/PencilWriting.svg';

  /// 한 글자에 주어진 시간 중 실제로 긋는 데 쓰는 비율. 나머지는 손을 떼는
  /// 사이다.
  static const double _drawRatio = 0.72;

  /// 가리개 경계를 흐리는 폭. 글씨 폭에 대한 비율이다.
  ///
  /// 넓게 두면 글자가 서서히 밝아지는 것처럼 보여서 적는 느낌이 죽는다. 잉크가
  /// 번지는 정도만 남긴다.
  static const double _softEdge = 0.025;
}

/// 지금 어디까지 그었고 연필이 어떻게 움직이고 있는지.
class _StrokeState {
  /// 글씨가 드러난 비율.
  final double progress;

  /// 글자 사이에서 연필을 종이에서 뗀 정도. 0 이면 닿아 있다.
  final double lift;

  /// 획을 따라 오르내리는 정도. -1 에서 1 사이다.
  final double bob;

  /// 몸통이 기우는 정도. -1 에서 1 사이다.
  final double tilt;

  const _StrokeState({
    required this.progress,
    required this.lift,
    required this.bob,
    required this.tilt,
  });
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
