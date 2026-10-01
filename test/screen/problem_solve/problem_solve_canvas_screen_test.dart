import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemSolve/Canvas/InkPainters.dart';
import 'package:ono/Screen/ProblemSolve/ProblemSolveCanvasScreen.dart';

import '../../helpers/helpers.dart';

Future<void> _pumpCanvas(WidgetTester tester, {int imageCount = 1}) async {
  await pumpOnoWidget(
    tester,
    ProblemSolveCanvasScreen(
      problemId: 1,
      problemImageUrls: [
        for (var i = 0; i < imageCount; i++) 'https://test.ono.local/p$i.png',
      ],
      onRefresh: () {},
    ),
    surfaceSize: OnoSurface.phone,
    settle: false,
  );
  await tester.pump(const Duration(milliseconds: 500));
}

Rect _canvasArea(WidgetTester tester) =>
    tester.getRect(find.byType(InteractiveViewer));

Future<void> _drawLine(
  WidgetTester tester,
  Offset from, {
  PointerDeviceKind kind = PointerDeviceKind.stylus,
  int steps = 10,
}) async {
  final gesture = await tester.startGesture(from, kind: kind);
  for (var i = 1; i <= steps; i++) {
    await gesture.moveTo(from + Offset(i * 8.0, i * 3.0));
    await tester.pump();
  }
  await gesture.up();
  await tester.pump();
}

/// 확정된 획 수. 확정 층이 그리는 획을 화면 상태에서 직접 읽을 수 없어서,
/// 되돌리기 버튼이 켜져 있는지와 되돌린 횟수로 센다.
bool _canUndo(WidgetTester tester) =>
    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo))
        .onPressed !=
    null;

bool _canRedo(WidgetTester tester) =>
    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.redo))
        .onPressed !=
    null;

void main() {
  setUpOnoWidgetTest();

  testWidgets('펜을 움직이는 동안 확정된 획 층은 다시 그리지 않는다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      final area = _canvasArea(tester);
      // 획을 몇 개 미리 그려 둔다.
      for (var i = 0; i < 3; i++) {
        await _drawLine(tester, area.topLeft + Offset(30, 40.0 + i * 30));
      }

      final gesture = await tester.startGesture(
        area.center,
        kind: PointerDeviceKind.stylus,
      );
      await tester.pump();
      final before = CommittedInkPainter.paintCount;
      for (var i = 0; i < 30; i++) {
        await gesture.moveBy(const Offset(3, 1));
        await tester.pump();
      }
      final during = CommittedInkPainter.paintCount - before;
      await gesture.up();
      await tester.pump();

      expect(during, 0);
      // 손을 떼면 확정 층이 한 번 다시 그린다.
      expect(CommittedInkPainter.paintCount - before, greaterThan(0));
    });
  });

  testWidgets('펜으로 쓰는 중에 손바닥이 닿아도 획이 끊기지 않는다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      final area = _canvasArea(tester);

      final pen = await tester.startGesture(
        area.topLeft + const Offset(40, 60),
        kind: PointerDeviceKind.stylus,
      );
      for (var i = 0; i < 5; i++) {
        await pen.moveBy(const Offset(6, 2));
        await tester.pump();
      }
      // 손바닥이 닿고 움직인다.
      final palm = await tester.startGesture(
        area.bottomRight - const Offset(60, 60),
        kind: PointerDeviceKind.touch,
      );
      await palm.moveBy(const Offset(-20, -10));
      for (var i = 0; i < 5; i++) {
        await pen.moveBy(const Offset(6, 2));
        await tester.pump();
      }
      await pen.up();
      await palm.up();
      await tester.pump();

      // 획은 하나만 생겼다. 되돌리기 한 번이면 비고, 손바닥 자국은 없다.
      expect(_canUndo(tester), isTrue);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
      await tester.pump();
      expect(_canUndo(tester), isFalse);
      // 손바닥 때문에 화면이 움직이지도 않았다.
      final viewer =
          tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(viewer.transformationController!.value, Matrix4.identity());

      // 펜이 감지돼 손가락 필기를 막았다는 안내가 한 번 뜬다.
      expect(find.text('펜이 감지돼서 손가락은 확대와 이동에만 써요'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  testWidgets('펜을 안 쓰면 손가락으로 쓴다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      final area = _canvasArea(tester);

      await _drawLine(tester, area.topLeft + const Offset(40, 60),
          kind: PointerDeviceKind.touch);

      expect(_canUndo(tester), isTrue);
    });
  });

  testWidgets('펜을 쓴 뒤 손가락 하나로 밀면 쓰지 않고 화면을 옮긴다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      final area = _canvasArea(tester);
      await _drawLine(tester, area.topLeft + const Offset(40, 60));
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
      await tester.pump();
      expect(_canUndo(tester), isFalse);

      await _drawLine(tester, area.center, kind: PointerDeviceKind.touch);

      // 획은 안 생기고 화면이 옮겨졌다.
      expect(_canUndo(tester), isFalse);
      final viewer =
          tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(
          viewer.transformationController!.value.getTranslation().x, isNot(0));
      await tester.pump(const Duration(seconds: 5));
    });
  });

  testWidgets('두 손가락으로 벌리면 펜 도구 그대로 확대된다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      final center = _canvasArea(tester).center;

      final a = await tester.startGesture(center - const Offset(40, 0),
          kind: PointerDeviceKind.touch);
      final b = await tester.startGesture(center + const Offset(40, 0),
          kind: PointerDeviceKind.touch);
      for (var i = 0; i < 10; i++) {
        await a.moveBy(const Offset(-6, 0));
        await b.moveBy(const Offset(6, 0));
        await tester.pump();
      }
      await a.up();
      await b.up();
      await tester.pump();

      final viewer =
          tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(),
          greaterThan(1.5));
      // 확대하는 동안 첫 손가락이 그은 선은 남지 않았다.
      expect(_canUndo(tester), isFalse);
    });
  });

  testWidgets('되돌린 것을 다시 실행할 수 있고, 전체 지우기도 되돌릴 수 있다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      final area = _canvasArea(tester);
      await _drawLine(tester, area.topLeft + const Offset(40, 60));

      expect(_canRedo(tester), isFalse);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
      await tester.pump();
      expect(_canRedo(tester), isTrue);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.redo));
      await tester.pump();
      expect(_canUndo(tester), isTrue);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
      await tester.pump();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
      await tester.pump();
      // 전체 지우기를 되돌려서 획이 돌아왔다.
      expect(_canUndo(tester), isTrue);
    });
  });

  testWidgets('캡처 크기는 캔버스의 두 배로 고치기 전과 같다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      final area = _canvasArea(tester);
      await _drawLine(tester, area.topLeft + const Offset(40, 60));

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find
            .descendant(
              of: find.byType(InteractiveViewer),
              matching: find.byType(RepaintBoundary),
            )
            .first,
      );
      final image =
          await tester.runAsync(() => boundary.toImage(pixelRatio: 2));

      expect(image!.width, (area.width * 2).round());
      expect(image.height, (area.height * 2).round());
      image.dispose();
    });
  });
}
