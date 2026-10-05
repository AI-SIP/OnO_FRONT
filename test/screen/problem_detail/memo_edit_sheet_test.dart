import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemDetail/Widget/MemoEditSheet.dart';

import '../../helpers/helpers.dart';

/// 상세의 메모 시트. 서버가 빈 메모를 받으면 지우므로 비운 채로도 저장할 수 있다.
void main() {
  setUpOnoWidgetTest();

  Future<String?> open(WidgetTester tester, String initialMemo,
      Future<void> Function() interact) async {
    String? result = 'unset';
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showMemoEditSheet(context,
                initialMemo: initialMemo, color: Colors.green);
          },
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await interact();
    return result;
  }

  ElevatedButton saveButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '저장'));

  testWidgets('원래 메모를 비우면 저장할 수 있고 빈 글을 돌려준다', (tester) async {
    final result = await open(tester, '분모 실수', () async {
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(saveButton(tester).onPressed, isNotNull);
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
    });

    expect(result, '');
  });

  testWidgets('메모가 없던 문제는 빈 채로 저장할 수 없다', (tester) async {
    await open(tester, '', () async {
      expect(saveButton(tester).onPressed, isNull);
    });
  });

  testWidgets('그대로면 저장할 수 없다', (tester) async {
    await open(tester, '분모 실수', () async {
      expect(saveButton(tester).onPressed, isNull);
    });
  });
}
