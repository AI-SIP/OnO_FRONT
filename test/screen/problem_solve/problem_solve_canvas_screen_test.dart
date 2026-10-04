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

      await tester.tap(find.byTooltip('이 페이지 지우기'));
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

  testWidgets('연습장으로 바꾸면 모눈 종이에 쓰고, 되돌리기는 연습장 쪽에 걸린다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      final area = _canvasArea(tester);
      await _drawLine(tester, area.topLeft + const Offset(40, 60));
      expect(find.text('1 / 1'), findsOneWidget);

      await tester.tap(find.text('연습장'));
      await tester.pump();
      expect(find.text('1 / 1'), findsOneWidget);
      // 연습장은 아직 비어서 되돌릴 게 없다.
      expect(_canUndo(tester), isFalse);

      await _drawLine(
          tester, _canvasArea(tester).topLeft + const Offset(40, 60));
      expect(_canUndo(tester), isTrue);

      await tester.tap(find.byTooltip('연습장 추가'));
      await tester.pump();
      expect(find.text('2 / 2'), findsOneWidget);
      expect(_canUndo(tester), isFalse);

      // 문제로 돌아오면 문제에 쓴 획이 그대로 있다.
      await tester.tap(find.text('문제'));
      await tester.pump();
      expect(_canUndo(tester), isTrue);
    });
  });

  testWidgets('연습장은 다섯 장까지 더할 수 있다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      await tester.tap(find.text('연습장'));
      await tester.pump();

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byTooltip('연습장 추가'), warnIfMissed: false);
        await tester.pump();
      }

      expect(find.text('5 / 5'), findsOneWidget);
      final add = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.add_box_outlined));
      expect(add.onPressed, isNull);
    });
  });

  testWidgets('그은 채로 잠깐 멈추면 곧은 선이 되고 끝점을 계속 옮길 수 있다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      final area = _canvasArea(tester);
      final pen = await tester.startGesture(area.topLeft + const Offset(40, 80),
          kind: PointerDeviceKind.stylus);
      // 살짝 떨리며 거의 곧게 긋는다. 구불구불한 획은 멈춰도 그대로 둔다.
      for (var i = 1; i <= 12; i++) {
        await pen.moveBy(Offset(10, i.isEven ? 1.5 : -1.5));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 600));
      // 직선이 된 뒤 더 움직이면 끝점만 따라온다.
      await pen.moveBy(const Offset(30, 0));
      await tester.pump();
      await pen.up();
      await tester.pump();

      expect(_canUndo(tester), isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('두 손가락 탭은 되돌리기, 세 손가락 탭은 다시 실행', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      final area = _canvasArea(tester);
      await _drawLine(tester, area.topLeft + const Offset(40, 60));
      expect(_canUndo(tester), isTrue);

      Future<void> tapWith(int fingers) async {
        final gestures = <TestGesture>[];
        for (var i = 0; i < fingers; i++) {
          gestures.add(await tester.startGesture(
              area.center + Offset(i * 30.0, 0),
              kind: PointerDeviceKind.touch));
        }
        await tester.pump(const Duration(milliseconds: 50));
        for (final g in gestures) {
          await g.up();
        }
        await tester.pump();
      }

      await tapWith(2);
      expect(_canUndo(tester), isFalse);
      expect(_canRedo(tester), isTrue);

      await tapWith(3);
      expect(_canUndo(tester), isTrue);
      expect(_canRedo(tester), isFalse);
    });
  });

  testWidgets('형광펜으로 그을 수 있다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      await tester.tap(find.text('형광펜'));
      await tester.pump();

      await _drawLine(
          tester, _canvasArea(tester).topLeft + const Offset(40, 60));

      expect(_canUndo(tester), isTrue);
    });
  });

  testWidgets('태블릿 가로에서는 문제와 연습장을 나란히 두고 마지막으로 쓴 쪽이 지금 페이지다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        ProblemSolveCanvasScreen(
          problemId: 1,
          problemImageUrls: const ['https://test.ono.local/p0.png'],
          onRefresh: () {},
        ),
        surfaceSize: const Size(1194, 834),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 500));

      final viewers = find.byType(InteractiveViewer);
      expect(viewers, findsNWidgets(2));
      // 위쪽 전환 버튼 대신 양쪽 머리에 이름이 있다.
      expect(find.text('문제'), findsOneWidget);
      expect(find.text('연습장'), findsOneWidget);

      final scratch = tester.getRect(viewers.at(1));
      await _drawLine(tester, scratch.topLeft + const Offset(40, 60));
      expect(_canUndo(tester), isTrue);

      // 문제 쪽을 손가락이 아니라 펜으로 한 번 찍으면 그쪽이 지금 페이지가 된다.
      final problem = tester.getRect(viewers.at(0));
      await _drawLine(tester, problem.topLeft + const Offset(40, 60), steps: 1);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
      await tester.pump();
      // 문제 쪽 획을 되돌렸다. 연습장 획은 남아 있어서 연습장을 다시 쓰면 되돌릴
      // 수 있다.
      expect(_canUndo(tester), isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('타이머는 앱바 가운데에 있다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);

      final screen = tester.getSize(find.byType(Scaffold)).width;

      // 아이콘과 숫자를 합친 묶음의 가운데가 화면 가운데에서 4px 안에 있다.
      final group = Rect.fromPoints(
        tester.getTopLeft(find.byIcon(Icons.pause_circle_outline)),
        tester.getBottomRight(find.text('00:00')),
      );
      expect((group.center.dx - screen / 2).abs(), lessThan(4));
    });
  });

  testWidgets('원래 크기 버튼은 확대했을 때만 보인다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpCanvas(tester);
      double opacity() => tester
          .widget<AnimatedOpacity>(find
              .ancestor(
                  of: find.text('원래 크기'),
                  matching: find.byType(AnimatedOpacity))
              .first)
          .opacity;
      expect(opacity(), 0);

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
      await tester.pumpAndSettle();
      expect(opacity(), 1);

      await tester.tap(find.text('원래 크기'));
      await tester.pumpAndSettle();
      expect(opacity(), 0);
      final viewer =
          tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(viewer.transformationController!.value, Matrix4.identity());
    });
  });
}
