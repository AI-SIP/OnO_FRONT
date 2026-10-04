import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Dialog/UnsavedChangesScope.dart';

import '../../helpers/helpers.dart';

/// 쓰던 내용이 있을 때 뒤로 가면 묻고, 없으면 그냥 나가는지 본다.
void main() {
  setUpOnoWidgetTest();

  Future<void> pumpHost(WidgetTester tester, Widget Function() page) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => page())),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  Widget body() => Scaffold(
        appBar: AppBar(),
        body: const Text('작성 화면'),
      );

  testWidgets('쓴 것이 없으면 묻지 않고 나간다', (tester) async {
    final changed = ValueNotifier(false);
    await pumpHost(
      tester,
      () => UnsavedChangesScope(
          hasChanges: changed, source: 'test', child: body()),
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('작성 화면'), findsNothing);
    expect(find.text('작성을 그만둘까요?'), findsNothing);
  });

  testWidgets('쓴 것이 있으면 묻고, 계속 쓰기를 고르면 남는다', (tester) async {
    final changed = ValueNotifier(true);
    await pumpHost(
      tester,
      () => UnsavedChangesScope(
          hasChanges: changed, source: 'test', child: body()),
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('작성을 그만둘까요?'), findsOneWidget);

    await tester.tap(find.text('계속 쓰기'));
    await tester.pumpAndSettle();
    expect(find.text('작성 화면'), findsOneWidget);
  });

  testWidgets('나가기를 고르면 화면을 닫는다', (tester) async {
    final changed = ValueNotifier(true);
    await pumpHost(
      tester,
      () => UnsavedChangesScope(
          hasChanges: changed, source: 'test', child: body()),
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나가기'));
    await tester.pumpAndSettle();

    expect(find.text('작성 화면'), findsNothing);
  });

  testWidgets('나가려는 순간에 확인하는 방식도 같은 규칙을 따른다', (tester) async {
    var inked = false;
    await pumpHost(
      tester,
      () => UnsavedChangesScope.check(
          checkChanges: () => inked, source: 'test', child: body()),
    );

    inked = true;
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('작성을 그만둘까요?'), findsOneWidget);

    await tester.tap(find.text('계속 쓰기'));
    await tester.pumpAndSettle();
    inked = false;
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('작성 화면'), findsNothing);
  });
}
