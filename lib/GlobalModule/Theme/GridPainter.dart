import 'dart:math';

import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Color gridColor;
  final double step;    // 격자 무늬 간격
  final double strokeWidth;   // 격자무늬 두께
  final bool isSpring;

  GridPainter({required this.gridColor, this.step = 15.0, this.strokeWidth = 0.7, this.isSpring = false});

  @override
  void paint(Canvas canvas, Size size) {
    // 격자 무늬 그리기
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if(isSpring){
      // 스프링 제본 그리기
      final springPaint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      double springRadius = 4.5; // 스프링 반지름
      double springSpacing = 20.0; // 스프링 간격

      // 왼쪽 가장자리에서 springRadius만큼 떨어진 곳에 스프링 그리기
      for (double y = springSpacing; y < size.height; y += springSpacing * 2) {
        canvas.drawCircle(Offset(springRadius*0.5, y), springRadius, springPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}