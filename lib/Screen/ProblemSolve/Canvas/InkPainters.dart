import 'package:flutter/material.dart';

import 'InkController.dart';
import 'InkPage.dart';

/// 확정된 획을 그린다.
///
/// 획은 [InkController.pictureFor] 가 그림 한 장으로 녹화해 둔 것을 다시
/// 그리기만 한다. 펜이 움직일 때는 다시 그리지 않고, 부분 지우개로 문지르는
/// 중일 때만 그 지우개 획을 같은 레이어에 겹쳐 그린다.
class CommittedInkPainter extends CustomPainter {
  final InkController controller;
  final InkPage page;
  final Rect imageRect;

  /// 캡처 화면에 함께 찍히는 그리기 영역 테두리. 고치기 전과 같다.
  final bool drawBorder;

  CommittedInkPainter({
    required this.controller,
    required this.page,
    required this.imageRect,
    this.drawBorder = true,
  }) : super(
          repaint: Listenable.merge([
            controller.committed,
            controller.liveEraser,
          ]),
        );

  /// 테스트에서 펜을 움직이는 동안 이 층이 다시 그려지지 않는지 센다.
  @visibleForTesting
  static int paintCount = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paintCount++;
    if (drawBorder) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final picture = controller.pictureFor(page, imageRect, size);
    final live = controller.liveStroke;
    if (live != null && live.isEraser && controller.page == page) {
      canvas.saveLayer(Offset.zero & size, Paint());
      canvas.drawPicture(picture);
      live.paint(canvas, imageRect);
      canvas.restore();
    } else {
      canvas.drawPicture(picture);
    }
  }

  @override
  bool shouldRepaint(covariant CommittedInkPainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.controller != controller ||
        oldDelegate.drawBorder != drawBorder;
  }
}

/// 지금 긋고 있는 펜이나 형광펜 획 하나만 그린다. 펜이 움직일 때 이 층만
/// 다시 그린다.
class LiveInkPainter extends CustomPainter {
  final InkController controller;
  final InkPage page;
  final Rect imageRect;

  LiveInkPainter({
    required this.controller,
    required this.page,
    required this.imageRect,
  }) : super(repaint: controller.live);

  @override
  void paint(Canvas canvas, Size size) {
    final live = controller.liveStroke;
    if (live == null || live.isEraser || controller.page != page) return;
    live.paint(canvas, imageRect);
  }

  @override
  bool shouldRepaint(covariant LiveInkPainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.controller != controller;
  }
}
