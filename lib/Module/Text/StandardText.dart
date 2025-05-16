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
      height: 1.8,
    );
  }
}
