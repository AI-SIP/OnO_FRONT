import 'package:flutter/material.dart';

import '../Text/StandardText.dart';
import 'AnimatedGauge.dart';
import 'AppMotion.dart';

/// 0 에서 [value] 까지 올라가는 숫자다.
///
/// 학습 리포트나 스트릭처럼 "얼마나 했는지"를 보여주는 숫자에 쓴다. 값이
/// 나중에 바뀌면 그때 있던 숫자에서 이어서 올라간다.
///
/// ```dart
/// AnimatedCountText(value: userInfo.totalProblemCount, fontSize: 20)
/// ```
///
/// 자릿수가 바뀔 때 글자 폭이 변해서 옆 요소가 흔들릴 수 있다. 흔들리면 안
/// 되는 자리에서는 [minWidth] 로 자리를 미리 잡아 둔다.
class AnimatedCountText extends StatelessWidget {
  /// 도달할 숫자.
  final num value;

  /// 숫자를 글자로 바꾸는 방법. 기본은 소수점 없는 정수다.
  /// 천 단위 쉼표나 단위를 붙이려면 여기서 만든다.
  final String Function(num value)? formatter;

  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;
  final TextAlign textAlign;

  /// 글자가 차지할 최소 너비.
  final double? minWidth;

  final Duration duration;
  final Curve curve;
  final Duration delay;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.formatter,
    this.color = Colors.black,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.bold,
    this.fontFamily = 'PretendardBold',
    this.textAlign = TextAlign.start,
    this.minWidth,
    this.duration = AppMotion.gauge,
    this.curve = AppMotion.emphasized,
    this.delay = Duration.zero,
  });

  String _format(num current) {
    if (formatter != null) return formatter!(current);
    return current.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGaugeValue(
      value: value.toDouble(),
      duration: duration,
      curve: curve,
      delay: delay,
      builder: (context, current) {
        final text = StandardText(
          text: _format(current),
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          textAlign: textAlign,
        );

        if (minWidth == null) return text;
        return SizedBox(width: minWidth, child: text);
      },
    );
  }
}
