import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemRegister/Widget/DatePickerWidget.dart';

import '../../helpers/helpers.dart';

Widget _wrap(Widget child) => Scaffold(body: child);

void main() {
  setUpOnoWidgetTest();

  testWidgets('선택된 날짜가 "년 월 일" 형식으로 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerWidget(
        selectedDate: DateTime(2026, 3, 5),
        onDateChanged: (_) {},
      )),
    );

    expect(find.text('푼 날짜'), findsOneWidget);
    expect(find.text('2026년 3월 5일'), findsOneWidget);
  });

  testWidgets('탭하면 날짜 선택 바텀시트가 뜬다', (tester) async {
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerWidget(
        selectedDate: DateTime(2026, 3, 5),
        onDateChanged: (_) {},
      )),
    );

    await tester.tap(find.text('2026년 3월 5일'));
    await tester.pumpAndSettle();

    expect(find.text('푼 날짜 선택'), findsOneWidget);
  });

  testWidgets('바텀시트에서 날짜를 고르면 onDateChanged 가 불리고 시트가 닫힌다', (tester) async {
    DateTime? changed;
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerWidget(
        selectedDate: DateTime(2026, 3, 5),
        onDateChanged: (d) => changed = d,
      )),
    );

    await tester.tap(find.text('2026년 3월 5일'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();

    expect(changed, DateTime(2026, 3, 12));
    // 시트가 닫혀 날짜 그리드가 더 이상 없어야 한다.
    expect(find.text('푼 날짜 선택'), findsNothing);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerWidget(
        selectedDate: DateTime(2026, 3, 5),
        onDateChanged: (_) {},
      )),
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
