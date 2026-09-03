// GoalSetDialog 위젯 테스트.
//
// 주간 목표 입력값 검증(빈 값/0/숫자 아닌 문자/길이 제한)과, 취소·저장
// 시 pop 되는 값을 본다. showDialog 로 직접 띄워서 반환값을 받는다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/StudyRoom/Widget/GoalSetDialog.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  Future<void> pumpAndOpen(
    WidgetTester tester, {
    int? currentGoal,
  }) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => GoalSetDialog.show(
            context,
            ThemeHandler(),
            currentGoal: currentGoal,
          ),
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('currentGoal 이 없으면 입력칸이 비어 있다', (tester) async {
    await pumpAndOpen(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '');
  });

  testWidgets('currentGoal 이 있으면 입력칸에 그 값이 채워진다', (tester) async {
    await pumpAndOpen(tester, currentGoal: 15);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '15');
  });

  testWidgets('취소를 누르면 null 로 닫힌다', (tester) async {
    int? result = -1; // sentinel
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await GoalSetDialog.show(context, ThemeHandler());
          },
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('빈 값으로 저장을 누르면 다이얼로그가 닫히지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => GoalSetDialog.show(context, ThemeHandler()),
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(GoalSetDialog), findsOneWidget);
  });

  testWidgets('0을 입력하고 저장을 누르면 다이얼로그가 닫히지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => GoalSetDialog.show(context, ThemeHandler()),
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(GoalSetDialog), findsOneWidget);
  });

  testWidgets('유효한 값을 입력하고 저장을 누르면 그 값으로 닫힌다', (tester) async {
    int? result;
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await GoalSetDialog.show(context, ThemeHandler());
          },
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '7');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(result, 7);
  });

  testWidgets('숫자가 아닌 문자는 입력되지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => GoalSetDialog.show(context, ThemeHandler()),
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'abc12');
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '12');
  });

  testWidgets('4자리 이상 입력하면 3자리로 잘린다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => GoalSetDialog.show(context, ThemeHandler()),
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, 3);
  });
}
