import 'package:flutter/material.dart';

class StandardText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  //final FontWeight fontWeight;
  final String fontFamily;

  const StandardText({
    super.key,
    required this.text,
    this.color = Colors.green,
    this.fontSize = 16.0,
    //this.fontWeight = FontWeight.bold,
    this.fontFamily = 'StandardFont',
  });

  @override
  Widget build(BuildContext context) {

    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: fontFamily,
        //fontWeight: fontWeight,
      ),
    );
  }
}
