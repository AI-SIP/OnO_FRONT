import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemRegister/Widget/AiAnalysisToggle.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  Future<void> pumpToggle(WidgetTester tester, ValueNotifier<bool> value,
      {Size? surfaceSize}) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<bool>(
            valueListenable: value,
            builder: (context, enabled, _) => AiAnalysisToggle(
              value: enabled,
              color: Colors.pink,
              onChanged: (next) => value.value = next,
            ),
          ),
        ),
      ),
      surfaceSize: surfaceSize ?? OnoSurface.phone,
    );
  }

  testWidgets('줄을 누르면 켜고 끄고, 설명도 바뀐다', (tester) async {
    final value = ValueNotifier(true);
    await pumpToggle(tester, value);

    expect(find.text('등록하면 풀이 방향과 주의할 점을 정리해 드려요'), findsOneWidget);

    await tester.tap(find.text('AI 분석'));
    await tester.pumpAndSettle();

    expect(value.value, isFalse);
    expect(find.text('분석하지 않아요. 문제 상세에서 따로 분석할 수 있어요'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(value.value, isTrue);
  });

  testWidgets('좁은 폰에서도 넘치지 않는다', (tester) async {
    await pumpToggle(tester, ValueNotifier(false),
        surfaceSize: OnoSurface.smallPhone);

    expect(tester.takeException(), isNull);
  });
}
