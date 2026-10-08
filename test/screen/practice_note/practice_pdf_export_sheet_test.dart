import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/PracticeNote/PracticePdfExportSheet.dart';
import 'package:ono/Service/Pdf/PracticeWorksheetPdf.dart';

import '../../helpers/helpers.dart';

/// 시트를 띄우는 버튼 하나만 있는 화면. 누르면 시트 결과를 [onResult] 로 넘긴다.
Future<void> _pumpLauncher(
  WidgetTester tester, {
  required void Function(WorksheetOptions?) onResult,
}) async {
  await pumpOnoWidget(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => onResult(await showPracticePdfExportSheet(
              context,
              problemCount: 12,
              accentColor: Colors.pink,
            )),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('처음에는 두 문제에 정답지와 메모를 넣는다', (tester) async {
    WorksheetOptions? result;
    await _pumpLauncher(tester, onResult: (r) => result = r);

    // 12문제를 두 문제씩 6쪽, 정답지 6줄씩 2쪽.
    expect(find.text('A4 8쪽 · 다 만들면 공유 창이 열려요'), findsOneWidget);

    await tester.tap(find.text('PDF 만들기'));
    await tester.pumpAndSettle();

    expect(result!.layout, WorksheetLayout.two);
    expect(result!.withAnswers, isTrue);
    expect(result!.withMemo, isTrue);
  });

  testWidgets('네 문제를 고르면 쪽수가 줄어든다', (tester) async {
    WorksheetOptions? result;
    await _pumpLauncher(tester, onResult: (r) => result = r);

    await tester.tap(find.text('네 문제'));
    await tester.pumpAndSettle();
    expect(find.text('A4 5쪽 · 다 만들면 공유 창이 열려요'), findsOneWidget);

    await tester.tap(find.text('PDF 만들기'));
    await tester.pumpAndSettle();
    expect(result!.layout, WorksheetLayout.four);
  });

  testWidgets('정답지를 끄면 메모도 빠지고 메모 스위치를 못 누른다', (tester) async {
    WorksheetOptions? result;
    await _pumpLauncher(tester, onResult: (r) => result = r);

    await tester.tap(find.text('정답지 맨 뒤에 붙이기'));
    await tester.pumpAndSettle();
    expect(find.text('A4 6쪽 · 다 만들면 공유 창이 열려요'), findsOneWidget);

    final memoSwitch = tester.widget<Switch>(find.byType(Switch).last);
    expect(memoSwitch.value, isFalse);
    expect(memoSwitch.onChanged, isNull);

    await tester.tap(find.text('PDF 만들기'));
    await tester.pumpAndSettle();
    expect(result!.withAnswers, isFalse);
    expect(result!.withMemo, isFalse);
  });

  testWidgets('시트를 그냥 닫으면 null 이다', (tester) async {
    WorksheetOptions? result = const WorksheetOptions(
        layout: WorksheetLayout.two, withAnswers: true, withMemo: true);
    await _pumpLauncher(tester, onResult: (r) => result = r);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
