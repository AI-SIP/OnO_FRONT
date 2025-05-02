import 'package:flutter/material.dart';

class StandardThinText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;

  const StandardThinText({
    super.key,
    required this.text,
    this.color = Colors.black,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.bold,
    //this.fontFamily = 'StandardFont',
    this.fontFamily = 'PretendardThin',
  });

  @override
  Widget build(BuildContext context) {

    return Text(
      text,
      style: getTextStyle(),
    );
  }

  TextStyle getTextStyle() {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      height: 1.7,
    );
  }
}
