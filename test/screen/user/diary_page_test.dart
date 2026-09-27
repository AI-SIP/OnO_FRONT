// 학습 달력 일기장 한 쪽 테스트.
//
// 2차 QA: 저장해도 같은 입력칸이 그대로 남아 일기를 쓴 느낌이 없었다. 쓴 날은
// 읽는 쪽으로 바뀌고, 고쳐 쓰기를 눌러야 입력칸이 열려야 한다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/User/Widget/DiaryPage.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  Future<void> pumpDiary(
    WidgetTester tester, {
    String? savedText = '',
    Future<bool> Function(String text)? onSave,
    Size surfaceSize = OnoSurface.phone,
    double textScale = 1.0,
    bool animate = false,
  }) async {
    if (!animate) disableAnimationsForTest(tester);
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _Host(
                initialText: savedText,
                onSave: onSave ?? (_) async => true,
              ),
            ),
          ),
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('안 쓴 날은 일기 쓰기 버튼만 있고 입력칸은 닫혀 있다', (tester) async {
    await pumpDiary(tester);

    expect(find.text('9월 25일'), findsOneWidget);
    expect(find.byKey(DiaryPage.writeButtonKey), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(DiaryPage.stampKey), findsNothing);
  });

  testWidgets('쓰고 저장하면 입력칸이 닫히고 적은 글과 도장이 남는다', (tester) async {
    final saved = <String>[];
    await pumpDiary(tester, onSave: (text) async {
      saved.add(text);
      return true;
    });

    await tester.tap(find.byKey(DiaryPage.writeButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  오늘은 함수를 복습했다  ');
    await tester.tap(find.byKey(DiaryPage.saveButtonKey));
    await tester.pumpAndSettle();

    expect(saved, ['오늘은 함수를 복습했다']);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('오늘은 함수를 복습했다'), findsOneWidget);
    expect(find.byKey(DiaryPage.stampKey), findsOneWidget);
    expect(find.byKey(DiaryPage.editButtonKey), findsOneWidget);
  });

  testWidgets('움직임을 켠 채로 저장해도 오류 없이 도장까지 찍힌다', (tester) async {
    await pumpDiary(tester, animate: true);

    await tester.tap(find.byKey(DiaryPage.writeButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '움직이는 일기');
    await tester.tap(find.byKey(DiaryPage.saveButtonKey));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('움직이는 일기'), findsOneWidget);
    expect(find.byKey(DiaryPage.stampKey), findsOneWidget);
  });

  testWidgets('쓴 날은 읽는 쪽으로 열리고 고쳐 쓰기를 누르면 적은 글이 입력칸에 담긴다', (tester) async {
    await pumpDiary(tester, savedText: '어제 쓴 일기');

    expect(find.byType(TextField), findsNothing);
    expect(find.text('어제 쓴 일기'), findsOneWidget);

    await tester.tap(find.byKey(DiaryPage.editButtonKey));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '어제 쓴 일기');
  });

  testWidgets('고친 것이 없으면 저장하지 않고 읽는 쪽으로 돌아간다', (tester) async {
    var calls = 0;
    await pumpDiary(tester, savedText: '그대로', onSave: (_) async {
      calls++;
      return true;
    });

    await tester.tap(find.byKey(DiaryPage.editButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryPage.saveButtonKey));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('그대로'), findsOneWidget);
  });

  testWidgets('취소하면 고치던 글을 버리고 저장된 글로 돌아간다', (tester) async {
    await pumpDiary(tester, savedText: '원래 글');

    await tester.tap(find.byKey(DiaryPage.editButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '고치던 글');
    await tester.tap(find.byKey(DiaryPage.cancelButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('원래 글'), findsOneWidget);
    expect(find.text('고치던 글'), findsNothing);
  });

  testWidgets('모두 지우고 저장하면 빈 쪽으로 돌아간다', (tester) async {
    final saved = <String>[];
    await pumpDiary(tester, savedText: '지울 글', onSave: (text) async {
      saved.add(text);
      return true;
    });

    await tester.tap(find.byKey(DiaryPage.editButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.byKey(DiaryPage.saveButtonKey));
    await tester.pumpAndSettle();

    expect(saved, ['']);
    expect(find.byKey(DiaryPage.writeButtonKey), findsOneWidget);
  });

  testWidgets('저장에 실패하면 쓰던 글을 그대로 둔 채 입력칸에 머문다', (tester) async {
    await pumpDiary(tester, onSave: (_) async => false);

    await tester.tap(find.byKey(DiaryPage.writeButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '날아가면 안 되는 글');
    await tester.tap(find.byKey(DiaryPage.saveButtonKey));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '날아가면 안 되는 글');
  });

  testWidgets('저장하는 동안 다시 눌러도 한 번만 저장한다', (tester) async {
    final gate = Completer<bool>();
    var calls = 0;
    await pumpDiary(tester, onSave: (_) {
      calls++;
      return gate.future;
    });

    await tester.tap(find.byKey(DiaryPage.writeButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '한 번만');
    await tester.tap(find.byKey(DiaryPage.saveButtonKey));
    await tester.pump();
    await tester.tap(find.byKey(DiaryPage.saveButtonKey), warnIfMissed: false);
    await tester.pump();

    expect(calls, 1);
    gate.complete(true);
    await tester.pumpAndSettle();
  });

  testWidgets('불러오는 중에는 빈 쪽을 잠깐 보여 주지 않는다', (tester) async {
    await pumpDiary(tester, savedText: null);

    expect(find.byKey(DiaryPage.writeButtonKey), findsNothing);
    expect(find.text('9월 25일'), findsNothing);
  });

  for (final (name, size, scale) in [
    ('작은 폰', OnoSurface.smallPhone, 1.0),
    ('태블릿', OnoSurface.tablet, 1.0),
    ('글자를 크게 키운 작은 폰', OnoSurface.smallPhone, 1.6),
  ]) {
    testWidgets('$name 에서 300자를 가득 써도 넘치지 않는다', (tester) async {
      await pumpDiary(
        tester,
        savedText: '가나다라마바사 ' * 37,
        surfaceSize: size,
        textScale: scale,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(DiaryPage.editButtonKey));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

/// 바깥 화면처럼 저장이 끝나면 새 글을 내려 준다.
class _Host extends StatefulWidget {
  final String? initialText;
  final Future<bool> Function(String text) onSave;

  const _Host({required this.initialText, required this.onSave});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String? _text = widget.initialText;

  @override
  Widget build(BuildContext context) {
    return DiaryPage(
      savedText: _text,
      date: DateTime(2026, 9, 25),
      weekdayName: '목요일',
      frogLayers: const [],
      primaryColor: Colors.green,
      onSave: (text) async {
        final ok = await widget.onSave(text);
        if (ok) setState(() => _text = text);
        return ok;
      },
    );
  }
}
