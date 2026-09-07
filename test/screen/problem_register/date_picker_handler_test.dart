import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemRegister/Widget/DatePickerHandler.dart';

import '../../helpers/helpers.dart';

Widget _wrap(Widget child) => Scaffold(body: child);

void main() {
  setUpOnoWidgetTest();

  testWidgets('기본 타이틀과 초기 연월이 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerHandler(
        initialDate: DateTime(2026, 3, 15),
        onDateSelected: (_) {},
      )),
    );

    expect(find.text('푼 날짜 선택'), findsOneWidget);
    expect(find.text('2026.03'), findsOneWidget);
  });

  testWidgets('title 을 넘기면 그 문구가 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerHandler(
        initialDate: DateTime(2026, 3, 15),
        onDateSelected: (_) {},
        title: '날짜를 골라주세요',
      )),
    );

    expect(find.text('날짜를 골라주세요'), findsOneWidget);
  });

  testWidgets('날짜를 탭하면 onDateSelected 가 그 날짜로 불린다', (tester) async {
    DateTime? selected;
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerHandler(
        initialDate: DateTime(2026, 3, 15),
        onDateSelected: (d) => selected = d,
      )),
    );

    await tester.tap(find.text('10'));
    await tester.pump();

    expect(selected, DateTime(2026, 3, 10));
  });

  testWidgets('lastDate 이후 달로는 다음 버튼이 비활성화된다', (tester) async {
    final last = DateTime(2026, 3, 15);
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerHandler(
        initialDate: last,
        onDateSelected: (_) {},
        lastDate: last,
      )),
    );

    final nextButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(nextButton.onPressed, isNull);
  });

  testWidgets('firstDate 이전 달로는 이전 버튼이 비활성화된다', (tester) async {
    final first = DateTime(2026, 3, 1);
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerHandler(
        initialDate: DateTime(2026, 3, 15),
        onDateSelected: (_) {},
        firstDate: first,
      )),
    );

    final prevButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left),
    );
    expect(prevButton.onPressed, isNull);
  });

  testWidgets('다음 버튼을 탭하면 다음 달로 넘어간다', (tester) async {
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerHandler(
        initialDate: DateTime(2026, 3, 15),
        onDateSelected: (_) {},
        lastDate: DateTime(2026, 12, 31),
      )),
    );

    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right));
    await tester.pump();

    expect(find.text('2026.04'), findsOneWidget);
  });

  testWidgets('lastDate(오늘) 보다 미래인 날짜는 탭해도 선택되지 않는다', (tester) async {
    final today = DateTime.now();
    DateTime? selected;
    // 오늘이 말일이 아니라면 내일 날짜는 선택 불가능해야 한다.
    if (DateTime(today.year, today.month + 1, 0).day == today.day) {
      return; // 말일이면 "내일"이 다음 달이라 이 케이스를 건너뛴다.
    }

    await pumpOnoWidget(
      tester,
      _wrap(DatePickerHandler(
        initialDate: today,
        onDateSelected: (d) => selected = d,
      )),
    );

    await tester.tap(find.text('${today.day + 1}'));
    await tester.pump();

    expect(selected, isNull);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerHandler(
        initialDate: DateTime(2026, 3, 15),
        onDateSelected: (_) {},
      )),
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
