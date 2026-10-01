// 필기 화면이 획이 많아질수록 느려지는지 재는 벤치마크다.
//
// 실기기 프로파일 모드 측정을 대신하지는 못한다. 테스트 환경은 래스터를 하지
// 않아서 빌드, 레이아웃, 그리기 기록 시간만 잰다. 그래도 같은 조건에서 고치기
// 전과 뒤를 비교하는 데는 쓸 수 있어서 둔다. (#295)
//
// 평소 CI 에서는 건너뛰고, 직접 잴 때만 돌린다.
//   flutter test test/screen/problem_solve/canvas_ink_benchmark_test.dart \
//     --dart-define=CANVAS_BENCH=true
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemSolve/ProblemSolveCanvasScreen.dart';

import '../../helpers/helpers.dart';

const _run = bool.fromEnvironment('CANVAS_BENCH');

void main() {
  setUpOnoWidgetTest();

  for (final strokeCount in [0, 200, 800]) {
    testWidgets('획 $strokeCount개가 있을 때 펜을 300프레임 움직이는 시간', (tester) async {
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          ProblemSolveCanvasScreen(
            problemId: 1,
            problemImageUrls: const ['https://test.ono.local/p.png'],
            onRefresh: () {},
          ),
          surfaceSize: OnoSurface.phone,
          settle: false,
        );
        await tester.pump(const Duration(milliseconds: 500));

        final area = tester.getRect(find.byType(InteractiveViewer));
        final origin = area.topLeft + const Offset(20, 20);
        final width = area.width - 40;
        final height = area.height - 40;

        // 미리 획을 채운다. 획 하나에 점 20개.
        for (var s = 0; s < strokeCount; s++) {
          final y = origin.dy + (s * 7) % height;
          final gesture = await tester.startGesture(
            Offset(origin.dx, y),
            kind: PointerDeviceKind.stylus,
          );
          for (var p = 1; p < 20; p++) {
            await gesture.moveTo(Offset(origin.dx + width * p / 20, y + p));
          }
          await gesture.up();
        }
        await tester.pump();

        // 재는 구간. 펜을 300번 움직이고 매번 한 프레임 그린다.
        final gesture = await tester.startGesture(
          origin + Offset(width / 2, height / 2),
          kind: PointerDeviceKind.stylus,
        );
        final watch = Stopwatch()..start();
        for (var i = 0; i < 300; i++) {
          await gesture.moveBy(Offset(i.isEven ? 1.5 : -1, 0.8));
          await tester.pump(const Duration(milliseconds: 8));
        }
        watch.stop();
        await gesture.up();

        // ignore: avoid_print
        print('CANVAS_BENCH strokes=$strokeCount '
            'total=${watch.elapsedMilliseconds}ms '
            'perFrame=${(watch.elapsedMicroseconds / 300 / 1000).toStringAsFixed(2)}ms');
      });
    }, skip: !_run);
  }
}
