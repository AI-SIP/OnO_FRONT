import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Dialog/ConfirmDialog.dart';

import '../../helpers/helpers.dart';

/// 공용 확인 창이 확정과 취소를 돌려주는지 본다.
void main() {
  setUpOnoWidgetTest();

  Future<Future<bool>> open(WidgetTester tester) async {
    late Future<bool> result;
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => result = showConfirmDialog(
            context,
            title: '삭제할까요?',
            message: '되돌릴 수 있어요.',
            confirmLabel: '삭제하기',
            destructive: true,
          ),
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('확정 버튼은 동사로 적고 누르면 true 다', (tester) async {
    final result = await open(tester);

    expect(find.text('삭제할까요?'), findsOneWidget);
    expect(find.text('되돌릴 수 있어요.'), findsOneWidget);
    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('취소하면 false 다', (tester) async {
    final result = await open(tester);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
  });
}
