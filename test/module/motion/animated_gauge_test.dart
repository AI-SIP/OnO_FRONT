// 게이지와 숫자 카운트업 테스트.
//
// "차오른다"는 것은 중간 프레임에 목표값이 아닌 값이 보인다는 뜻이다. 그래서
// pumpAndSettle 로 끝난 뒤만 보지 않고 중간 시점을 함께 확인한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/AnimatedCountText.dart';
import 'package:ono/Module/Motion/AnimatedGauge.dart';
import 'package:ono/Module/Motion/AppMotion.dart';

import '../../helpers/helpers.dart';

/// 가로 막대가 지금 차 있는 비율.
double _fillFactor(WidgetTester tester) {
  return tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor ??
      0.0;
}

/// 진행 원이 지금 차 있는 비율.
double _circleValue(WidgetTester tester) {
  return tester
          .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator))
          .value ??
      0.0;
}

void main() {
  setUpOnoWidgetTest();

  group('AnimatedLinearGauge', () {
    testWidgets('0 에서 시작해 목표값까지 차오른다', (tester) async {
      await pumpOnoWidget(
        tester,
        const Scaffold(
          body: AnimatedLinearGauge(value: 0.8, color: Colors.blue),
        ),
        settle: false,
      );

      expect(_fillFactor(tester), 0.0);

      await tester.pump(AppMotion.gauge ~/ 2);
      final midway = _fillFactor(tester);
      expect(midway, greaterThan(0.0));
      expect(midway, lessThan(0.8));

      await tester.pumpAndSettle();
      expect(_fillFactor(tester), closeTo(0.8, 0.001));
    });

    testWidgets('1 을 넘는 값은 1 로 잘린다', (tester) async {
      await pumpOnoWidget(
        tester,
        const Scaffold(
          body: AnimatedLinearGauge(value: 1.6, color: Colors.blue),
        ),
      );

      expect(_fillFactor(tester), closeTo(1.0, 0.001));
    });

    testWidgets('delay 동안은 비어 있다가 그 뒤에 차오른다', (tester) async {
      await pumpOnoWidget(
        tester,
        const Scaffold(
          body: AnimatedLinearGauge(
            value: 0.5,
            color: Colors.blue,
            delay: Duration(milliseconds: 300),
          ),
        ),
        settle: false,
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(_fillFactor(tester), 0.0, reason: '아직 시작할 때가 아니다');

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(_fillFactor(tester), closeTo(0.5, 0.001));
    });

    testWidgets('값이 바뀌면 있던 자리에서 이어서 움직인다', (tester) async {
      await pumpOnoWidget(
        tester,
        const Scaffold(
          body: AnimatedLinearGauge(value: 0.3, color: Colors.blue),
        ),
      );
      expect(_fillFactor(tester), closeTo(0.3, 0.001));

      await pumpOnoWidget(
        tester,
        const Scaffold(
          body: AnimatedLinearGauge(value: 0.9, color: Colors.blue),
        ),
        settle: false,
      );

      await tester.pump(AppMotion.gauge ~/ 2);
      final midway = _fillFactor(tester);
      expect(midway, greaterThan(0.3), reason: '0 으로 떨어졌다가 다시 오르면 안 된다');
      expect(midway, lessThan(0.9));

      await tester.pumpAndSettle();
      expect(_fillFactor(tester), closeTo(0.9, 0.001));
    });
  });

  group('AnimatedCircularGauge', () {
    testWidgets('0 에서 시작해 목표값까지 차오른다', (tester) async {
      await pumpOnoWidget(
        tester,
        const Scaffold(
          body: Center(
            child: AnimatedCircularGauge(
              value: 0.6,
              color: Colors.blue,
              size: 80,
            ),
          ),
        ),
        settle: false,
      );

      expect(_circleValue(tester), 0.0);

      await tester.pumpAndSettle();
      expect(_circleValue(tester), closeTo(0.6, 0.001));
    });

    testWidgets('가운데에 넣은 것이 함께 보인다', (tester) async {
      await pumpOnoWidget(
        tester,
        const Scaffold(
          body: Center(
            child: AnimatedCircularGauge(
              value: 0.5,
              color: Colors.blue,
              size: 80,
              child: Text('Lv.3'),
            ),
          ),
        ),
      );

      expect(find.text('Lv.3'), findsOneWidget);
    });
  });

  group('AnimatedCountText', () {
    testWidgets('0 에서 목표 숫자까지 올라간다', (tester) async {
      await pumpOnoWidget(
        tester,
        const Scaffold(body: Center(child: AnimatedCountText(value: 120))),
        settle: false,
      );

      expect(find.text('0'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('formatter 로 단위를 붙일 수 있다', (tester) async {
      await pumpOnoWidget(
        tester,
        Scaffold(
          body: Center(
            child: AnimatedCountText(
              value: 42,
              formatter: (value) => '${value.round()}일',
            ),
          ),
        ),
      );

      expect(find.text('42일'), findsOneWidget);
    });
  });
}
