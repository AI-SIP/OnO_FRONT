import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemSolve/Canvas/InkController.dart';
import 'package:ono/Screen/ProblemSolve/Canvas/InkInputRouter.dart';
import 'package:ono/Screen/ProblemSolve/Canvas/InkPage.dart';
import 'package:ono/Screen/ProblemSolve/Canvas/InkStroke.dart';

const _rect = Rect.fromLTWH(0, 0, 400, 400);

InkStroke _stroke(List<Offset> points, {InkKind kind = InkKind.pen}) {
  final stroke = InkStroke(kind: kind, color: Colors.black, width: 4);
  for (final p in points) {
    stroke.addPoint(p, 1, _rect, force: true);
  }
  return stroke;
}

void main() {
  group('InkStroke', () {
    test('화면 기준 0.75px 보다 가까운 점은 버린다', () {
      final stroke =
          InkStroke(kind: InkKind.pen, color: Colors.black, width: 4);
      stroke.addPoint(const Offset(0.5, 0.5), 1, _rect);
      // 400px 캔버스에서 0.001 은 0.4px 라 버린다.
      expect(stroke.addPoint(const Offset(0.501, 0.5), 1, _rect), isFalse);
      // 0.01 은 4px 라 남긴다.
      expect(stroke.addPoint(const Offset(0.51, 0.5), 1, _rect), isTrue);
      expect(stroke.length, 2);
    });

    test('경계 상자로 먼 획은 획 지우개에 걸리지 않는다', () {
      final stroke = _stroke([const Offset(0.1, 0.1), const Offset(0.2, 0.1)]);

      expect(stroke.hitTest(const Offset(60, 40), 7, _rect), isTrue);
      expect(stroke.hitTest(const Offset(300, 300), 7, _rect), isFalse);
    });

    test('부분 지우개 획은 획 지우개 대상이 아니다', () {
      final eraser = _stroke([const Offset(0.1, 0.1), const Offset(0.2, 0.1)],
          kind: InkKind.pixelEraser);

      expect(eraser.hitTest(const Offset(60, 40), 7, _rect), isFalse);
    });

    test('직선 보정은 시작점과 끝점만 남긴다', () {
      final stroke = _stroke([
        const Offset(0.1, 0.1),
        const Offset(0.2, 0.3),
        const Offset(0.3, 0.1),
      ]);

      stroke.straighten();

      expect(stroke.points, [const Offset(0.1, 0.1), const Offset(0.3, 0.1)]);
    });

    test('거의 곧게 그은 획만 직선 보정 대상이다', () {
      // 살짝 떨리며 곧게 그은 선
      final line = _stroke([
        const Offset(0.1, 0.5),
        const Offset(0.3, 0.505),
        const Offset(0.5, 0.497),
        const Offset(0.7, 0.5),
      ]);
      // 숫자 2 처럼 꺾인 획
      final two = _stroke([
        const Offset(0.10, 0.40),
        const Offset(0.14, 0.37),
        const Offset(0.18, 0.38),
        const Offset(0.19, 0.42),
        const Offset(0.16, 0.48),
        const Offset(0.10, 0.54),
        const Offset(0.21, 0.54),
      ]);

      expect(line.isRoughlyStraight(_rect), isTrue);
      expect(two.isRoughlyStraight(_rect), isFalse);
    });

    test('곡선 경로는 첫 점에서 시작해 마지막 점에서 끝난다', () {
      final stroke = _stroke([
        const Offset(0.1, 0.1),
        const Offset(0.2, 0.3),
        const Offset(0.3, 0.1),
        const Offset(0.4, 0.3),
      ]);
      Offset at(int i) => Offset(stroke.points[i].dx * _rect.width,
          stroke.points[i].dy * _rect.height);

      final bounds = stroke.smoothPath(at).getBounds();

      expect(bounds.left, closeTo(40, 0.01));
      expect(bounds.right, closeTo(160, 0.01));
    });
  });

  group('InkPage 되돌리기와 다시 실행', () {
    test('획 지우개로 지운 뒤 되돌리면 지운 획이 원래 자리로 돌아온다', () {
      // 고치기 전에는 여기서 엉뚱한 획(c)이 지워졌다.
      final page = InkPage();
      final a = _stroke([const Offset(0.1, 0.1)]);
      final b = _stroke([const Offset(0.5, 0.5)]);
      final c = _stroke([const Offset(0.9, 0.9)]);
      page
        ..add(a)
        ..add(b)
        ..add(c);

      page.eraseWhere((s) => s == b);
      page.commitErase();
      expect(page.strokes, [a, c]);

      page.undo();
      expect(page.strokes, [a, b, c]);

      page.redo();
      expect(page.strokes, [a, c]);
    });

    test('한 번 문지르는 동안 지운 여러 획은 되돌리기 한 번에 돌아온다', () {
      final page = InkPage();
      final strokes = [
        for (var i = 0; i < 5; i++) _stroke([Offset(i / 10, 0.5)]),
      ];
      strokes.forEach(page.add);

      page.eraseWhere((s) => s == strokes[1]);
      page.eraseWhere((s) => s == strokes[3]);
      page.eraseWhere((s) => s == strokes[0]);
      page.commitErase();
      expect(page.strokes, [strokes[2], strokes[4]]);

      page.undo();
      expect(page.strokes, strokes);
    });

    test('전체 지우기도 되돌릴 수 있다', () {
      final page = InkPage();
      final a = _stroke([const Offset(0.1, 0.1)]);
      page.add(a);

      page.clear();
      expect(page.isEmpty, isTrue);

      page.undo();
      expect(page.strokes, [a]);
    });

    test('새로 그리면 다시 실행 기록은 사라진다', () {
      final page = InkPage();
      page.add(_stroke([const Offset(0.1, 0.1)]));
      page.undo();
      expect(page.canRedo, isTrue);

      page.add(_stroke([const Offset(0.2, 0.2)]));

      expect(page.canRedo, isFalse);
    });
  });

  group('InkController', () {
    test('펜이 움직일 때는 확정 알림이 울리지 않는다', () {
      final controller = InkController(pageCount: 1);
      var committed = 0;
      var live = 0;
      controller.committed.addListener(() => committed++);
      controller.live.addListener(() => live++);

      controller.beginStroke(
        InkStroke(kind: InkKind.pen, color: Colors.black, width: 4),
        const Offset(0.1, 0.1),
        1,
        _rect,
      );
      for (var i = 1; i <= 20; i++) {
        controller.extendStroke(Offset(0.1 + i / 100, 0.1), 1, _rect);
      }

      expect(committed, 0);
      expect(live, greaterThan(20));

      controller.endStroke();
      expect(committed, 1);
      expect(controller.page.strokes, hasLength(1));
      controller.dispose();
    });

    test('확정된 획이 그대로면 녹화한 그림을 다시 쓴다', () {
      final controller = InkController(pageCount: 1);
      controller.page.add(_stroke([const Offset(0.1, 0.1)]));
      const size = Size(400, 400);

      final first = controller.pictureFor(controller.page, _rect, size);
      final second = controller.pictureFor(controller.page, _rect, size);
      expect(identical(first, second), isTrue);

      controller.page.add(_stroke([const Offset(0.2, 0.2)]));
      final third = controller.pictureFor(controller.page, _rect, size);
      expect(identical(first, third), isFalse);
      controller.dispose();
    });
  });

  test('제출할 때 문제 이미지는 모두, 연습장은 필기가 있는 것만 캡처한다', () {
    // 문제 이미지 2장, 연습장 3장 중 두 번째만 썼다.
    final controller = InkController(pageCount: 2 + 5);
    controller.pages[3].add(_stroke([const Offset(0.5, 0.5)]));
    // 지우개 획만 있는 연습장은 쓴 게 아니다.
    controller.pages[4]
        .add(_stroke([const Offset(0.5, 0.5)], kind: InkKind.pixelEraser));

    expect(
        controller.pagesToCapture(imageCount: 2, scratchCount: 3), [0, 1, 3]);
    controller.dispose();
  });

  group('InkInputRouter', () {
    const touch = PointerDeviceKind.touch;
    const stylus = PointerDeviceKind.stylus;

    test('펜을 안 쓰면 손가락 하나로 쓴다', () {
      final router = InkInputRouter();

      expect(router.onDown(1, touch).role, InkPointerRole.draw);
    });

    test('손가락으로 쓰다가 두 번째 손가락이 닿으면 확대로 바뀌고 쓰던 획은 버린다', () {
      final router = InkInputRouter();
      router.onDown(1, touch);

      final second = router.onDown(2, touch);

      expect(second.role, InkPointerRole.transform);
      expect(second.cancelLiveStroke, isTrue);
      expect(router.isTransforming(1), isTrue);
    });

    test('펜으로 쓰는 중에 닿는 손바닥은 무시하고 펜 획은 이어진다', () {
      final router = InkInputRouter();
      expect(router.onDown(1, stylus).role, InkPointerRole.draw);

      final palm = router.onDown(2, touch);

      expect(palm.role, InkPointerRole.ignore);
      expect(palm.cancelLiveStroke, isFalse);
      expect(router.isDrawing(1), isTrue);
      expect(router.palmRejected, isTrue);
    });

    test('펜을 한 번 쓰면 그 뒤로 손가락 하나는 쓰지 않고 화면을 옮긴다', () {
      final router = InkInputRouter();
      router.onDown(1, stylus);
      router.onUp(1);

      expect(router.onDown(2, touch).role, InkPointerRole.transform);
      expect(router.stylusSeen, isTrue);
    });
  });

  group('InkTransformTracker', () {
    const viewport = Size(400, 400);

    test('두 손가락을 벌리면 확대되고 4배를 넘지 않는다', () {
      final tracker = InkTransformTracker();
      final start = Matrix4.identity();
      tracker.add(1, const Offset(150, 200), start);
      tracker.add(2, const Offset(250, 200), start);

      final twice = tracker.move(2, const Offset(350, 200), viewport)!;
      expect(twice.getMaxScaleOnAxis(), closeTo(2, 0.01));

      final huge = tracker.move(2, const Offset(2000, 200), viewport)!;
      expect(huge.getMaxScaleOnAxis(), closeTo(4, 0.01));
    });

    test('1배보다 작게 줄어들지 않는다', () {
      final tracker = InkTransformTracker();
      final start = Matrix4.identity();
      tracker.add(1, const Offset(100, 200), start);
      tracker.add(2, const Offset(300, 200), start);

      final small = tracker.move(2, const Offset(120, 200), viewport)!;

      expect(small.getMaxScaleOnAxis(), closeTo(1, 0.01));
    });

    test('한 손가락으로 옮기되 바깥 여백 80 을 넘지 않는다', () {
      final tracker = InkTransformTracker();
      tracker.add(1, const Offset(200, 200), Matrix4.identity());

      final moved = tracker.move(1, const Offset(400, 200), viewport)!;

      expect(moved.getTranslation().x, closeTo(80, 0.01));
    });
  });
}
