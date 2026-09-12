import 'package:flutter/material.dart';

class StandardText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final int? maxLines;

  /// 줄 높이. 기본 1.8 은 여러 줄 본문에 맞춘 값이다.
  ///
  /// 숫자 한 줄을 몇 개 쌓는 자리에서는 이 여백이 빈 줄처럼 끼어들어 간격을
  /// 눈으로 맞출 수 없게 만든다. 그런 곳에서만 1.2 쯤으로 좁히고 요소 사이
  /// 간격은 여백 위젯으로 준다.
  final double height;

  const StandardText({
    super.key,
    required this.text,
    this.color = Colors.black,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.bold,
    this.fontFamily = 'PretendardBold',
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.height = 1.8,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: getTextStyle(),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  TextStyle getTextStyle() {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      height: height,
    );
  }
}
