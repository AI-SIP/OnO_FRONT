import 'package:flutter/material.dart';

/*
  화면에 격자무늬를 그려주는 클래스
 */

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.2) // 격자무늬 색상과 불투명도
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; // 격자무늬 두께 조정

    const double step = 20.0; // 격자무늬 간격

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
