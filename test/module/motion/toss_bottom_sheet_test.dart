// showTossSheet 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/TossBottomSheet.dart';

import '../../helpers/helpers.dart';

/// 시트를 여는 버튼 하나만 있는 화면. [onResult] 로 닫힌 결과를 받는다.
Widget _opener({
  bool showHandle = true,
  bool enableDrag = true,
  ValueChanged<String?>? onResult,
}) {
  return Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await showTossSheet<String>(
              context: context,
              showHandle: showHandle,
              enableDrag: enableDrag,
              builder: (sheetContext) => SizedBox(
                height: 200,
                child: Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext, '확인'),
                    child: const Text('시트 내용'),
                  ),
                ),
              ),
            );
            onResult?.call(result);
          },
          child: const Text('시트 열기'),
        ),
      ),
    ),
  );
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('시트가 열리고 손잡이가 함께 뜬다', (tester) async {
    await pumpOnoWidget(tester, _opener());

    await tester.tap(find.text('시트 열기'));
    await tester.pumpAndSettle();

    expect(find.text('시트 내용'), findsOneWidget);
    expect(find.byType(TossSheetHandle), findsOneWidget);
  });

  testWidgets('showHandle 이 false 면 손잡이가 없다', (tester) async {
    await pumpOnoWidget(tester, _opener(showHandle: false));

    await tester.tap(find.text('시트 열기'));
    await tester.pumpAndSettle();

    expect(find.text('시트 내용'), findsOneWidget);
    expect(find.byType(TossSheetHandle), findsNothing);
  });

  testWidgets('시트 안에서 pop 한 값이 그대로 돌아온다', (tester) async {
    String? received;
    await pumpOnoWidget(tester, _opener(onResult: (value) => received = value));

    await tester.tap(find.text('시트 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시트 내용'));
    await tester.pumpAndSettle();

    expect(received, '확인');
    expect(find.text('시트 내용'), findsNothing);
  });

  testWidgets('아래로 끌면 닫힌다', (tester) async {
    await pumpOnoWidget(tester, _opener());

    await tester.tap(find.text('시트 열기'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('시트 내용'), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(find.text('시트 내용'), findsNothing);
  });

  testWidgets('enableDrag 가 false 면 끌어도 안 닫힌다', (tester) async {
    await pumpOnoWidget(tester, _opener(enableDrag: false));

    await tester.tap(find.text('시트 열기'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('시트 내용'), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(find.text('시트 내용'), findsOneWidget);
  });
}
