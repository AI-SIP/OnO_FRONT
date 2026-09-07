// StepProgressBar 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/StepProgressBar.dart';

import '../../helpers/helpers.dart';

double _fillFactor(WidgetTester tester) {
  return tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor ??
      0.0;
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('현재 단계만큼 막대가 찬다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: StepProgressBar(
          currentStep: 1,
          totalSteps: 2,
          color: Colors.blue,
        ),
      ),
    );

    expect(_fillFactor(tester), closeTo(0.5, 0.001));
  });

  testWidgets('다음 단계로 넘어가면 있던 자리에서 이어서 움직인다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: StepProgressBar(
          currentStep: 1,
          totalSteps: 3,
          color: Colors.blue,
        ),
      ),
    );
    expect(_fillFactor(tester), closeTo(1 / 3, 0.001));

    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: StepProgressBar(
          currentStep: 2,
          totalSteps: 3,
          color: Colors.blue,
        ),
      ),
      settle: false,
    );

    await tester.pump(const Duration(milliseconds: 120));
    final midway = _fillFactor(tester);
    expect(midway, greaterThan(1 / 3));
    expect(midway, lessThan(2 / 3));

    await tester.pumpAndSettle();
    expect(_fillFactor(tester), closeTo(2 / 3, 0.001));
  });

  testWidgets('showLabel 이면 몇 번째인지 함께 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: StepProgressBar(
          currentStep: 2,
          totalSteps: 3,
          color: Colors.blue,
          showLabel: true,
        ),
      ),
    );

    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('totalSteps 가 0 이어도 깨지지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: StepProgressBar(
          currentStep: 0,
          totalSteps: 0,
          color: Colors.blue,
        ),
      ),
    );

    expect(_fillFactor(tester), 0.0);
  });
}
