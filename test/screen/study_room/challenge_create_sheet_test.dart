// ChallengeCreateSheet 위젯 테스트.
//
// 입력칸에 포커스를 준 뒤 시트 안의 다른 곳을 누르면 포커스가 풀리는지 본다(#189).
// 모바일 터치는 Flutter 기본값으로는 바깥을 눌러도 포커스가 유지된다.
// 바깥을 누를 때 칩 탭이 먹히지 않는 일이 없는지도 함께 본다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/StudyRoom/ChallengeCreateSheet.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  Future<void> pumpAndOpen(WidgetTester tester) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => ChallengeCreateSheet.show(context),
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  EditableText editableOf(WidgetTester tester, String hint) {
    final field = find.widgetWithText(TextField, hint);
    return tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
  }

  testWidgets('목표 값 입력칸에 포커스를 준 뒤 제목 라벨을 누르면 포커스가 풀린다', (tester) async {
    await pumpAndOpen(tester);

    await tester.tap(find.widgetWithText(TextField, '예: 10'));
    await tester.pump();
    expect(editableOf(tester, '예: 10').focusNode.hasFocus, isTrue);

    await tester.tap(find.text('새 챌린지 만들기'));
    await tester.pump();
    expect(editableOf(tester, '예: 10').focusNode.hasFocus, isFalse);
  });

  testWidgets('제목 입력칸에 포커스를 준 뒤 칩을 누르면 포커스가 풀리고 칩도 한 번에 선택된다', (tester) async {
    await pumpAndOpen(tester);

    const titleHint = '예: 이번 주 문제 10개 등록하기';
    await tester.tap(find.widgetWithText(TextField, titleHint));
    await tester.pump();
    expect(editableOf(tester, titleHint).focusNode.hasFocus, isTrue);

    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();
    expect(editableOf(tester, titleHint).focusNode.hasFocus, isFalse);
    // '직접 입력' 이 선택되면 집계 일수 입력칸이 나타난다.
    expect(find.widgetWithText(TextField, '예: 5'), findsOneWidget);
  });

  testWidgets('입력칸끼리 옮겨 누르면 포커스가 바로 다음 칸으로 넘어간다', (tester) async {
    await pumpAndOpen(tester);

    const titleHint = '예: 이번 주 문제 10개 등록하기';
    await tester.tap(find.widgetWithText(TextField, titleHint));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextField, '예: 10'));
    await tester.pump();

    expect(editableOf(tester, titleHint).focusNode.hasFocus, isFalse);
    expect(editableOf(tester, '예: 10').focusNode.hasFocus, isTrue);
  });
}
