import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/StepProgressBar.dart';
import 'package:ono/Provider/TutorialProvider.dart';
import 'package:ono/Screen/Tutorial/TutorialOverlay.dart';
import 'package:ono/Screen/Tutorial/TutorialStep.dart';
import 'package:ono/Screen/Tutorial/TutorialStorage.dart';
import 'package:ono/Screen/Tutorial/TutorialTargets.dart';

import '../../helpers/helpers.dart';

/// 단계가 넘어간 것이 눈에 보이는지 잠근다.
///
/// 예전에는 카드를 통째로 바꿔 끼우면서 제자리에서 흐려졌다 나타나기만 했다.
/// 안에 있던 진행 막대도 매번 새로 만들어져서 이전 칸에서 이어지는 대신 0
/// 에서 다시 찼다. 그래서 화면이 넘어갔다는 것도 어디까지 왔는지도 안 보였다.
class _NoopTutorialStorage extends TutorialStorage {
  @override
  Future<bool> isCompleted(int userId) async => false;

  @override
  Future<void> markCompleted(int userId) async {}
}

Widget _harness(TutorialTargets targets) {
  return Stack(children: [TutorialOverlay(targets: targets)]);
}

Future<void> exitRunning(WidgetTester tester, TutorialProvider provider) async {
  if (provider.status != TutorialStatus.idle) {
    await provider.skip();
    await tester.pump();
  }
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpOnoWidgetTest();

  late TutorialTargets targets;
  late TutorialProvider provider;

  setUp(() {
    targets = TutorialTargets();
    provider = TutorialProvider(storage: _NoopTutorialStorage());
  });

  Future<void> pumpFirstStep(WidgetTester tester) async {
    provider.showReplayIntro(1);
    provider.start();
    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
      settle: false,
    );
    // 첫 화면의 막대가 다 찰 때까지 기다린다. 여기서부터 이어져야 한다.
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// 진행 막대가 지금 얼마나 차 있는지.
  double filledRatio(WidgetTester tester) {
    final box = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byType(StepProgressBar),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    return box.widthFactor ?? 0;
  }

  /// 글이 지금 놓여 있는 왼쪽 좌표.
  double titleLeft(WidgetTester tester, int stepIndex) {
    return tester.getRect(find.text(tutorialSteps[stepIndex].title)).left;
  }

  testWidgets('진행 막대가 0 으로 돌아가지 않고 이전 칸에서 이어서 찬다', (tester) async {
    await pumpFirstStep(tester);

    final firstStep = 1 / tutorialSteps.length;
    expect(filledRatio(tester), closeTo(firstStep, 0.001));

    await tester.tap(find.text('다음'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // 이 순간이 예전에 0 으로 떨어지던 자리다.
    expect(
      filledRatio(tester),
      greaterThanOrEqualTo(firstStep),
      reason: '막대가 이전 칸에서 이어지지 않고 처음부터 다시 찬다',
    );

    await tester.pump(const Duration(milliseconds: 600));
    expect(filledRatio(tester), closeTo(2 / tutorialSteps.length, 0.001));

    await exitRunning(tester, provider);
  });

  testWidgets('다음을 누르면 새 글이 오른쪽에서 들어오고 옛 글은 왼쪽으로 빠진다', (tester) async {
    await pumpFirstStep(tester);

    await tester.tap(find.text('다음'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final incoming = titleLeft(tester, 1);
    final outgoing = titleLeft(tester, 0);

    await tester.pump(const Duration(milliseconds: 600));
    final settled = titleLeft(tester, 1);

    expect(incoming, greaterThan(settled + 4),
        reason: '새 글이 제자리 오른쪽에서 들어오지 않는다');
    expect(outgoing, lessThan(settled - 4), reason: '옛 글이 왼쪽으로 빠지지 않는다');

    await exitRunning(tester, provider);
  });

  testWidgets('이전을 누르면 반대로 움직인다', (tester) async {
    await pumpFirstStep(tester);

    await tester.tap(find.text('다음'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('이전'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final incoming = titleLeft(tester, 0);
    final outgoing = titleLeft(tester, 1);

    await tester.pump(const Duration(milliseconds: 600));
    final settled = titleLeft(tester, 0);

    expect(incoming, lessThan(settled - 4), reason: '되돌아갈 때 글이 왼쪽에서 들어오지 않는다');
    expect(outgoing, greaterThan(settled + 4),
        reason: '되돌아갈 때 옛 글이 오른쪽으로 빠지지 않는다');

    // 막대도 같이 되돌아온다.
    expect(filledRatio(tester), closeTo(1 / tutorialSteps.length, 0.001));

    await exitRunning(tester, provider);
  });
}
