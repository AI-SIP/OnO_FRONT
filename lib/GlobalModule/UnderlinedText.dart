import 'package:flutter/material.dart';

class UnderlinedText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const UnderlinedText({Key? key, required this.text, this.style = const TextStyle(fontSize: 20, fontFamily: 'font1')}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: style,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            color: Colors.red.withOpacity(0.5), // 밑줄 색상 및 투명도 조절
          ),
        ),
      ],
    );
  }
}