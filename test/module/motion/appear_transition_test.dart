// AppearTransition 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/AppMotion.dart';
import 'package:ono/Module/Motion/AppearTransition.dart';

import '../../helpers/helpers.dart';

/// [text] 를 감싸고 있는 Opacity 의 현재 값.
double _opacityOf(WidgetTester tester, String text) {
  final opacity = tester.widget<Opacity>(
    find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first,
  );
  return opacity.opacity;
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('투명한 상태에서 시작해 다 보일 때까지 나타난다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(body: AppearTransition(child: Text('결과'))),
      settle: false,
    );

    expect(_opacityOf(tester, '결과'), 0.0);

    await tester.pump(AppMotion.slow ~/ 2);
    final midway = _opacityOf(tester, '결과');
    expect(midway, greaterThan(0.0));
    expect(midway, lessThan(1.0));

    await tester.pumpAndSettle();
    expect(_opacityOf(tester, '결과'), 1.0);
  });

  testWidgets('delay 동안은 보이지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: AppearTransition(
          delay: Duration(milliseconds: 200),
          child: Text('결과'),
        ),
      ),
      settle: false,
    );

    await tester.pump(const Duration(milliseconds: 150));
    expect(_opacityOf(tester, '결과'), 0.0);

    await tester.pumpAndSettle();
    expect(_opacityOf(tester, '결과'), 1.0);
  });

  testWidgets('enabled 가 false 면 감싸지 않고 그대로 그린다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: AppearTransition(enabled: false, child: Text('결과')),
      ),
    );

    expect(find.text('결과'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('결과'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  group('stagger', () {
    testWidgets('항목마다 지연이 한 칸씩 늘어난다', (tester) async {
      final wrapped = AppearTransition.stagger(
        const [Text('하나'), Text('둘'), Text('셋')],
        interval: const Duration(milliseconds: 50),
      );

      final delays = wrapped
          .map((widget) => (widget as AppearTransition).delay.inMilliseconds)
          .toList();

      expect(delays, [0, 50, 100]);
    });

    testWidgets('maxStaggered 를 넘으면 더 밀리지 않는다', (tester) async {
      // 항목이 많을 때 끝까지 지연을 매기면 마지막 것이 한참 뒤에 나타난다.
      final wrapped = AppearTransition.stagger(
        List<Widget>.generate(6, (i) => Text('$i')),
        interval: const Duration(milliseconds: 50),
        maxStaggered: 3,
      );

      final delays = wrapped
          .map((widget) => (widget as AppearTransition).delay.inMilliseconds)
          .toList();

      expect(delays, [0, 50, 100, 150, 150, 150]);
    });

    testWidgets('감싼 항목이 모두 화면에 그려진다', (tester) async {
      await pumpOnoWidget(
        tester,
        Scaffold(
          body: Column(
            children: AppearTransition.stagger(
              const [Text('하나'), Text('둘'), Text('셋')],
            ),
          ),
        ),
      );

      expect(find.text('하나'), findsOneWidget);
      expect(find.text('둘'), findsOneWidget);
      expect(find.text('셋'), findsOneWidget);
    });
  });
}
