import 'package:flutter/material.dart';

class HandWriteText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;

  const HandWriteText({
    super.key,
    required this.text,
    this.color = Colors.green,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.bold,
    this.fontFamily = 'HandWrite',
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
      ),
    );
  }
}
