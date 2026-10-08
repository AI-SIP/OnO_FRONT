import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Util/PhantomTapGuard.dart';

/// 버튼을 누르면 바텀시트가 뜨는 화면.
Widget _launcher() => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const SizedBox(height: 200, child: Text('시트')),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('가드가 없으면 (0, 0) 터치에 시트가 닫힌다 (iPadOS 26 증상 재현)', (tester) async {
    await tester.pumpWidget(_launcher());
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('시트'), findsOneWidget);

    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text('시트'), findsNothing);
  });

  group('가드를 걸면', () {
    setUp(() => GestureBinding.instance.pointerRouter
        .addGlobalRoute(PhantomTapGuard.absorb));
    tearDown(() => GestureBinding.instance.pointerRouter
        .removeGlobalRoute(PhantomTapGuard.absorb));

    testWidgets('(0, 0) 터치를 버려서 시트가 남는다', (tester) async {
      await tester.pumpWidget(_launcher());
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.text('시트'), findsOneWidget);
    });

    testWidgets('진짜 바깥 탭은 그대로 시트를 닫는다', (tester) async {
      await tester.pumpWidget(_launcher());
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('시트'), findsNothing);
    });
  });
}
