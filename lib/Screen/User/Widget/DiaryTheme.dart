import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 학습 달력 일기장의 종이, 잉크, 손글씨 재료.
///
/// 홈 화면 위젯(iOS `WidgetTheme.swift`, Android `WidgetInk.kt`)과 같은 식에서
/// 출발했지만, 앱 안에서는 **읽기 쉬운 것이 먼저**라 몇 값을 바꿨다. 크라프트지
/// 책상과 누런 종이는 화면이 칙칙해 보여서 밝은 바탕과 거의 흰 종이로 두고,
/// 잉크는 흰 종이 위에서 4.5:1 대비가 나오도록 조금 더 진하게 쓴다.
class DiaryPaper {
  const DiaryPaper._();

  /// 거의 흰 종이. 순백이면 화면 바탕과 구분이 안 돼 아주 살짝만 데운다.
  static const Color paper = Color(0xFFFFFEFA);

  /// 화면 바탕. 흰색 위에 테마 색을 아주 옅게 깔아 종이 카드가 떠 보이게 한다.
  static Color deskOf(Color theme) =>
      Color.alphaBlend(theme.withValues(alpha: 0.055), Colors.white);

  /// 복습한 문제 줄마다 긋는 밑줄.
  static const Color rule = Color(0xFFF1E9D8);

  /// 장 안에서 칸을 나누는 점선.
  static const Color dashed = Color(0xFFE6DAC3);

  /// 비어 있는 자리의 점선 원.
  static const Color emptyDot = Color(0xFFE3D7C0);

  /// 일요일만 붉은 잉크. 테마와 상관없이 고정이다.
  /// 시안 값 hsl(8, 50%, 52%) 는 흰 종이 위 대비가 4.4 라서 밝기만 0.47 로 내렸다.
  static const Color sunday = Color(0xFFB44C3C); // hsl(8, 50%, 47%)

  static const String handFont = 'HandWrite';

  static const double radius = 20;
}

/// 테마 색 하나에서 뽑은 잉크 색들.
///
/// 글씨를 검정과 회색으로 쓰면 파스텔 테마 위에서 따로 논다. 테마가 24가지라
/// 색을 고정할 수도 없어서, 테마 색의 색상(hue)은 그대로 두고 채도와 밝기만
/// 내려 "그 테마 색 잉크로 쓴 글씨" 처럼 보이게 한다. 식은 위젯과 같다.
@immutable
class DiaryInk {
  final Color theme;

  /// 본문. hue 유지, 채도 ≤ 0.5, 밝기 0.30 (종이 위 대비 4.5:1 이상).
  final Color ink;

  /// 보조. hue 유지, 채도 ≤ 0.35, 밝기 0.45 이하 (종이 위 대비 4.5:1 이상).
  final Color soft;

  /// 흐림. 지난달, 다음 달, 미래 날짜 숫자. 보조를 채도 ≤ 0.30 으로 낮추고
  /// 알파 0.4.
  final Color faint;

  const DiaryInk._({
    required this.theme,
    required this.ink,
    required this.soft,
    required this.faint,
  });

  factory DiaryInk.of(Color theme) {
    final hsl = HSLColor.fromColor(theme.withValues(alpha: 1));

    // 초록, 노랑처럼 원래 밝게 보이는 색상은 같은 밝기여도 흰 종이 위에서 대비가
    // 모자란다. 4.5:1 이 나올 때까지 밝기를 조금씩 내린다.
    Color pick(double maxSaturation, double lightness) {
      final saturation = math.min(hsl.saturation, maxSaturation);
      var l = lightness;
      while (true) {
        final color = HSLColor.fromAHSL(1, hsl.hue, saturation, l).toColor();
        if (l <= 0.15 || _contrast(color, DiaryPaper.paper) >= 4.5) {
          return color;
        }
        l -= 0.01;
      }
    }

    return DiaryInk._(
      theme: theme,
      ink: pick(0.5, 0.30),
      soft: pick(0.35, 0.45),
      faint: HSLColor.fromAHSL(
        1,
        hsl.hue,
        math.min(hsl.saturation, 0.30),
        0.45,
      ).toColor().withValues(alpha: 0.4),
    );
  }

  /// 공부한 날 동그라미. level 1~3 을 테마 색 30%, 55%, 85% 로 칠한다.
  Color levelFill(int level) => switch (level) {
        1 => theme.withValues(alpha: 0.30),
        2 => theme.withValues(alpha: 0.55),
        3 => theme.withValues(alpha: 0.85),
        _ => Colors.transparent,
      };

  /// 칠한 동그라미 위 숫자 색.
  ///
  /// 블랙, 딥인디고 같은 진한 테마는 55%, 85% 로 칠한 칸이 잉크와 거의 같은
  /// 색이 돼 숫자가 묻힌다. 종이 위에 칠한 실제 색과 잉크의 대비가 3:1 도
  /// 안 되고 흰색이 더 잘 읽히면 그 칸만 흰 숫자로 쓴다. 위젯과 같은 규칙이다.
  Color numberOn(int level) {
    final fill = levelFill(level);
    if (fill.a == 0) return ink;
    final cell = Color.alphaBlend(fill, DiaryPaper.paper);
    final inkContrast = _contrast(cell, ink);
    if (inkContrast < 3 && _contrast(cell, Colors.white) > inkContrast) {
      return Colors.white;
    }
    return ink;
  }

  /// 마스킹테이프. 명세서 값(32%)이다.
  Color get tape => theme.withValues(alpha: 0.32);

  /// 형광펜 띠. 기본은 테마 색 40% 다.
  ///
  /// 블랙, 딥인디고처럼 진한 테마는 40% 띠가 잉크 글씨와 비슷한 색이 돼 글씨가
  /// 묻힌다. 띠 위에서도 잉크가 4.5:1 로 읽힐 때까지 띠를 옅게 한다.
  Color get highlight {
    for (var alpha = 0.40; alpha > 0.1; alpha -= 0.05) {
      final band = theme.withValues(alpha: alpha);
      if (_contrast(Color.alphaBlend(band, DiaryPaper.paper), ink) >= 4.5) {
        return band;
      }
    }
    return theme.withValues(alpha: 0.1);
  }

  /// 종이 테두리. 누런 선보다 테마 색을 옅게 두른 쪽이 흰 바탕에서 깨끗하다.
  Color get edge => theme.withValues(alpha: 0.18);

  /// 화면 바탕.
  Color get desk => DiaryPaper.deskOf(theme);

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  @override
  bool operator ==(Object other) => other is DiaryInk && other.theme == theme;

  @override
  int get hashCode => theme.hashCode;
}

/// 손글씨 글씨 한 줄. 화면 전체가 `HandWrite` 라 매번 같은 스타일을 적지 않게
/// 모았다. 글자 크기 설정(`textScaler`)은 [Text] 가 그대로 따른다.
class HandText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final double height;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;

  const HandText(
    this.text, {
    super.key,
    required this.size,
    required this.color,
    this.height = 1.35,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.decoration,
  });

  static TextStyle style({
    required double size,
    required Color color,
    double height = 1.35,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontFamily: DiaryPaper.handFont,
        fontSize: size,
        height: height,
        color: color,
        decoration: decoration,
        decorationColor: color,
      );

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style(
        size: size,
        color: color,
        height: height,
        decoration: decoration,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 형광펜을 그은 글씨. 글자 아래쪽 45% 높이에만 띠를 칠한다.
///
/// 배경을 통째로 칠하면 라벨 스티커처럼 보여서, 손으로 밑줄 긋듯 아래쪽에만
/// 띠를 둔다. 문장 안에 끼울 때는 [WidgetSpan] 으로 감싼다.
class Highlighted extends StatelessWidget {
  final Widget child;
  final Color color;

  const Highlighted({super.key, required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HighlightPainter(color),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: child,
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final Color color;

  const _HighlightPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.55, size.width, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => old.color != color;
}

/// 종이 위쪽에 붙인 마스킹테이프 한 조각.
class MaskingTape extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  /// 라디안. 똑바로 붙이면 인쇄물처럼 보여서 살짝 기울인다.
  final double angle;

  const MaskingTape({
    super.key,
    required this.color,
    this.width = 76,
    this.height = 18,
    this.angle = -3 * math.pi / 180,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// 책상 위에 놓인 일기장 종이 한 장.
class DiarySheet extends StatelessWidget {
  final Widget child;

  /// 주면 위쪽 가운데에 테이프를 붙인다.
  final Color? tapeColor;

  final EdgeInsetsGeometry padding;

  /// 테두리 색. 보통 [DiaryInk.edge] 를 넘긴다.
  final Color edgeColor;

  const DiarySheet({
    super.key,
    required this.child,
    required this.edgeColor,
    this.tapeColor,
    // 손글씨는 획이 가늘어 글자끼리 몰려 보이기 쉬워서 안쪽 여백을 넉넉히 둔다.
    this.padding = const EdgeInsets.fromLTRB(22, 26, 22, 24),
  });

  @override
  Widget build(BuildContext context) {
    final tape = tapeColor;
    return Stack(
      clipBehavior: Clip.none,
      // 부모가 높이를 정해 준 자리(가로 태블릿 마이페이지의 나란한 카드)에서도
      // 종이가 그 높이를 그대로 받게 한다. loose 면 종이가 내용만큼 줄어든다.
      fit: StackFit.passthrough,
      children: [
        Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: DiaryPaper.paper,
            borderRadius: BorderRadius.circular(DiaryPaper.radius),
            border: Border.all(color: edgeColor),
            boxShadow: [
              BoxShadow(
                color: edgeColor.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
        if (tape != null)
          Positioned(
            top: -8,
            left: 0,
            right: 0,
            child: Center(child: MaskingTape(color: tape)),
          ),
      ],
    );
  }
}

/// 가로 점선. 장 안에서 칸을 나눈다.
class DashedLine extends StatelessWidget {
  final Color color;
  final double thickness;

  const DashedLine({
    super.key,
    this.color = DiaryPaper.dashed,
    this.thickness = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thickness,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(color, thickness)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double thickness;

  const _DashedLinePainter(this.color, this.thickness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness;
    const dash = 5.0;
    const gap = 4.0;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) =>
      old.color != color || old.thickness != thickness;
}

/// 점선 원 테두리. 고른 날 칸과 기분이 비어 있는 자리에 쓴다.
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  /// 한 바퀴에 끊어 그릴 조각 수.
  final int dashes;

  const DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    this.dashes = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - strokeWidth / 2,
    );
    final step = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * step, step * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashes != dashes;
}

/// 잉크로 그린 작은 선그림들. 시안의 SVG(24 x 24 viewBox)를 그대로 옮겼다.
/// 머티리얼 아이콘은 굵기와 모양이 손글씨와 어울리지 않아서 쓰지 않는다.
enum InkGlyph { chevronLeft, chevronRight, check, pencil, plus }

class InkIcon extends StatelessWidget {
  final InkGlyph glyph;
  final double size;
  final Color color;

  /// 24 기준 선 굵기.
  final double strokeWidth;

  const InkIcon(
    this.glyph, {
    super.key,
    required this.size,
    required this.color,
    this.strokeWidth = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _InkGlyphPainter(glyph, color, strokeWidth),
      ),
    );
  }
}

class _InkGlyphPainter extends CustomPainter {
  final InkGlyph glyph;
  final Color color;
  final double strokeWidth;

  const _InkGlyphPainter(this.glyph, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (glyph) {
      case InkGlyph.chevronLeft:
        canvas.drawPath(
          Path()
            ..moveTo(15, 5)
            ..lineTo(8, 12)
            ..lineTo(15, 19),
          stroke,
        );
      case InkGlyph.chevronRight:
        canvas.drawPath(
          Path()
            ..moveTo(9, 5)
            ..lineTo(16, 12)
            ..lineTo(9, 19),
          stroke,
        );
      case InkGlyph.check:
        canvas.drawPath(
          Path()
            ..moveTo(4, 12)
            ..lineTo(9, 17)
            ..lineTo(20, 6),
          stroke,
        );
      case InkGlyph.plus:
        canvas.drawLine(const Offset(12, 5), const Offset(12, 19), stroke);
        canvas.drawLine(const Offset(5, 12), const Offset(19, 12), stroke);
      case InkGlyph.pencil:
        // 연필 몸통 안은 종이 색으로 채워서, 칸의 칠 위에 얹혀도 선이 또렷하다.
        final body = Path()
          ..moveTo(4, 20)
          ..lineTo(5, 16)
          ..lineTo(16, 5)
          ..lineTo(19, 8)
          ..lineTo(8, 19)
          ..close();
        canvas.drawPath(body, Paint()..color = DiaryPaper.paper);
        canvas.drawPath(body, stroke);
        canvas.drawLine(const Offset(14, 7), const Offset(17, 10), stroke);
    }
  }

  @override
  bool shouldRepaint(_InkGlyphPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
