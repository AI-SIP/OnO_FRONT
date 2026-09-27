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

  // 가로로 둔 폰은 시트가 폭 640 까지 넓어져 네모 칸이 커지는데 높이는 390 이
  // 안 된다. 칸을 폭으로만 잡으면 3주차 이후가 시트 밖으로 밀려 누를 수 없었다.
  // 2026년 5월은 1일이 금요일이라 여섯 줄까지 차는 달이다.
  for (final size in const [Size(844, 390), Size(640, 360)]) {
    testWidgets(
        '가로 폰(${size.width.toInt()}x${size.height.toInt()})에서도 마지막 주 날짜가 화면 안에 있고 고를 수 있다',
        (tester) async {
      DateTime? changed;
      await pumpOnoWidget(
        tester,
        _wrap(DatePickerWidget(
          selectedDate: DateTime(2026, 5, 5),
          onDateChanged: (d) => changed = d,
        )),
        surfaceSize: size,
      );

      await tester.tap(find.text('2026년 5월 5일'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final lastDay = find.text('31');
      expect(lastDay, findsOneWidget);
      final screen = Offset.zero & size;
      final rect = tester.getRect(lastDay);
      expect(screen.contains(rect.topLeft), isTrue, reason: '31일 위치: $rect');
      expect(screen.contains(rect.bottomRight), isTrue,
          reason: '31일 위치: $rect');
      // 달력이 스크롤로 밀려 있으면 화면 안이어도 눌리지 않는다. 달력 영역 안인지도 본다.
      final grid = tester.getRect(find.byType(GridView));
      expect(grid.contains(rect.topLeft), isTrue,
          reason: '달력: $grid, 31일: $rect');
      expect(grid.contains(rect.bottomRight), isTrue,
          reason: '달력: $grid, 31일: $rect');

      await tester.tap(lastDay);
      await tester.pumpAndSettle();

      expect(changed, DateTime(2026, 5, 31));
      expect(find.text('푼 날짜 선택'), findsNothing);
    });
  }

  testWidgets('세로 폰에서는 날짜 칸이 원래대로 정사각형이다', (tester) async {
    await pumpOnoWidget(
      tester,
      _wrap(DatePickerWidget(
        selectedDate: DateTime(2026, 5, 5),
        onDateChanged: (_) {},
      )),
    );

    await tester.tap(find.text('2026년 5월 5일'));
    await tester.pumpAndSettle();

    final cell = tester.getRect(find
        .ancestor(of: find.text('31'), matching: find.byType(Container))
        .first);
    expect(cell.width, closeTo(cell.height, 0.01));
  });
}
