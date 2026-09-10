// HandwritingReveal 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/HandwritingReveal.dart';

import '../../helpers/helpers.dart';

const _phrase = '"나만의 진정한 오답노트, OnO"';
const _duration = Duration(milliseconds: 600);

void main() {
  setUpOnoWidgetTest();

  testWidgets('다 써질 때까지는 onCompleted 가 불리지 않는다', (tester) async {
    var completed = false;

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Center(
          child: HandwritingReveal(
            text: _phrase,
            color: Colors.black,
            duration: _duration,
            onCompleted: () => completed = true,
          ),
        ),
      ),
      settle: false,
    );

    // 가리개가 덮여 있는 동안에도 글자 자체는 트리에 있다. 지워지는 것이
    // 아니라 가려지는 방식이라서다.
    expect(find.text(_phrase), findsOneWidget);
    expect(find.byType(ShaderMask), findsOneWidget);

    await tester.pump(_duration ~/ 2);
    expect(completed, isFalse);

    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('동작 줄이기를 켜면 가리개 없이 그리고 onCompleted 는 그대로 불린다', (tester) async {
    // 이 콜백을 스플래시가 기다리고 있어서, 움직임을 끈 기기에서 안 불리면
    // 첫 화면에서 넘어가지 못하고 멈춘다.
    disableAnimationsForTest(tester);
    var completed = false;

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Center(
          child: HandwritingReveal(
            text: _phrase,
            color: Colors.black,
            duration: _duration,
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );

    expect(find.text(_phrase), findsOneWidget);
    expect(find.byType(ShaderMask), findsNothing);
    expect(completed, isTrue);
  });

  testWidgets('동작 줄이기에서는 delay 를 줘도 기다리지 않는다', (tester) async {
    disableAnimationsForTest(tester);
    var completed = false;

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Center(
          child: HandwritingReveal(
            text: _phrase,
            color: Colors.black,
            delay: const Duration(seconds: 3),
            duration: _duration,
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );

    expect(completed, isTrue);
  });

  testWidgets('delay 가 지나기 전에는 쓰기 시작하지 않는다', (tester) async {
    var completed = false;

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Center(
          child: HandwritingReveal(
            text: _phrase,
            color: Colors.black,
            delay: const Duration(milliseconds: 300),
            duration: _duration,
            onCompleted: () => completed = true,
          ),
        ),
      ),
      settle: false,
    );

    // delay + duration 이 지나야 끝난다. duration 만 지난 시점에는 아직이다.
    await tester.pump(_duration);
    expect(completed, isFalse);

    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('밑줄을 켜면 글씨를 다 쓴 뒤에 그어진다', (tester) async {
    var completed = false;

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Center(
          child: HandwritingReveal(
            text: _phrase,
            color: Colors.black,
            duration: _duration,
            underline: true,
            onCompleted: () => completed = true,
          ),
        ),
      ),
      settle: false,
    );

    // 밑줄까지 포함해서 duration 안에 끝나야 한다. 글씨가 끝나는 시점에
    // 콜백이 불리면 밑줄이 그어지기 전에 화면이 넘어간다.
    await tester.pump(const Duration(milliseconds: 450));
    expect(completed, isFalse);

    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('연필을 켜면 다 쓴 뒤에는 남지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Center(
          child: HandwritingReveal(
            text: _phrase,
            color: Colors.black,
            duration: _duration,
            pencil: true,
          ),
        ),
      ),
      settle: false,
    );

    await tester.pump(_duration ~/ 2);
    final midway = tester.widgetList<Align>(find.byType(Align)).length;

    await tester.pumpAndSettle();
    final after = tester.widgetList<Align>(find.byType(Align)).length;

    expect(after, lessThan(midway));
  });
}
