import 'package:flutter/material.dart';

import 'HandWriteText.dart';

class UnderlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final String fontFamily;
  final FontWeight fontWeight;

  const UnderlinedText({
    super.key,
    required this.text,

    this.fontSize = 20,
    this.color = Colors.black,
    this.fontFamily = 'HandWrite',
    this.fontWeight = FontWeight.bold,
  });


  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        decoration: TextDecoration.underline,
        decorationColor: Colors.red.withOpacity(0.7), // 밑줄 색상 설정
        decorationThickness: 3.0, // 밑줄 두께 설정
      ),
    );
  }
}
