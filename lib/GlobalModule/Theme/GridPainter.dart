import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Color gridColor;
  final double step;    // 격자 무늬 간격
  final double strokeWidth;   // 격자무늬 두께

  GridPainter({required this.gridColor, this.step = 15.0, this.strokeWidth = 0.7});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withOpacity(0.15) // 격자무늬 색상과 불투명도
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth; // 격자무늬 두께 조정

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