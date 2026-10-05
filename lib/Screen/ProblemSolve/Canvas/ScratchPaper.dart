import 'package:flutter/material.dart';

/// 연습장 종이. 흰 바탕에 옅은 모눈이다.
///
/// 제출할 때 필기와 함께 캡처돼서 복습 기록의 풀이 이미지로 남는다.
class ScratchPaper extends StatelessWidget {
  const ScratchPaper({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(painter: _GridPainter(), child: SizedBox.expand()),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  static const double _cell = 20;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final line = Paint()
      ..color = const Color(0xFFEEF1F4)
      ..strokeWidth = 1;
    for (var x = _cell; x < size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = _cell; y < size.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
