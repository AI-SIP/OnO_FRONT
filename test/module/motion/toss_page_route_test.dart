// TossPageRoute 테스트.
//
// 이 라우트를 만든 목적이 둘이라 그 둘을 본다. 플랫폼과 상관없이 같은 전환을
// 쓰는 것, 그리고 화면 가장자리를 끌어 뒤로 가는 제스처를 잃지 않는 것이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/AppMotion.dart';
import 'package:ono/Module/Motion/TossPageRoute.dart';

import '../../helpers/helpers.dart';

class _FirstScreen extends StatelessWidget {
  const _FirstScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push<void>(
            context,
            TossPageRoute<void>(builder: (_) => const _SecondScreen()),
          ),
          child: const Text('열기'),
        ),
      ),
    );
  }
}

class _SecondScreen extends StatelessWidget {
  const _SecondScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('둘째 화면')));
  }
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('push 하면 다음 화면이 열리고 pop 하면 돌아온다', (tester) async {
    await pumpOnoWidget(tester, const _FirstScreen());

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('둘째 화면'), findsOneWidget);

    final context = tester.element(find.text('둘째 화면'));
    Navigator.pop(context);
    await tester.pumpAndSettle();
    expect(find.text('열기'), findsOneWidget);
  });

  testWidgets('전환 시간이 AppMotion.page 다', (tester) async {
    // Cupertino 기본값 500ms 를 그대로 쓰면 앱 전체가 느리게 느껴진다.
    final route = TossPageRoute<void>(builder: (_) => const _SecondScreen());
    expect(route.transitionDuration, AppMotion.page);
  });

  testWidgets('전환 중간에는 아직 다 그려지지 않는다', (tester) async {
    await pumpOnoWidget(tester, const _FirstScreen());

    await tester.tap(find.text('열기'));
    await tester.pump();
    await tester.pump(AppMotion.page ~/ 2);

    // 전환이 진행 중이면 두 화면이 함께 있다. 즉시 교체되는 것이 아니다.
    expect(find.text('둘째 화면'), findsOneWidget);
    expect(find.text('열기'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('열기'), findsNothing);
  });

  testWidgets('화면 왼쪽 가장자리를 끌면 뒤로 간다', (tester) async {
    // MaterialPageRoute 를 대신하면서 이것을 잃으면 iOS 사용자가 바로 느낀다.
    await pumpOnoWidget(tester, const _FirstScreen());

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('둘째 화면'), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(5, 400));
    await gesture.moveBy(const Offset(300, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('둘째 화면'), findsNothing);
    expect(find.text('열기'), findsOneWidget);
  });
}
