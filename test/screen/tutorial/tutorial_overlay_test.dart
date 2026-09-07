import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Provider/TutorialProvider.dart';
import 'package:ono/Screen/Tutorial/TutorialOverlay.dart';
import 'package:ono/Screen/Tutorial/TutorialStep.dart';
import 'package:ono/Screen/Tutorial/TutorialStorage.dart';
import 'package:ono/Screen/Tutorial/TutorialTargets.dart';

import '../../helpers/helpers.dart';

/// 아무 것도 하지 않는 TutorialStorage.
///
/// TutorialProvider 의 기본 생성자는 진짜 TutorialStorage() 를 만들고, 이건
/// SharedPreferences 플랫폼 채널을 탄다. 이 파일의 테스트는 전부
/// TutorialLaunchSource.settingsReplay 경로(showReplayIntro)로 시작해서
/// _markCompletedIfAuto 가 항상 조기 반환하므로 원래도 storage 를 건드리지
/// 않지만, 앞으로 코드가 바뀌어도 실제 채널을 타지 않도록 아예 no-op 으로
/// 바꿔 끼운다.
class _NoopTutorialStorage extends TutorialStorage {
  @override
  Future<bool> isCompleted(int userId) async => false;

  @override
  Future<void> markCompleted(int userId) async {}
}

/// 테스트 대상 화면. Positioned.fill 을 쓰는 TutorialOverlay 는 Stack 조상이
/// 있어야 하고, [target] 을 넘기면 그 GlobalKey 를 가진 실제 위젯을 함께
/// 배치해 하이라이트 대상 탐색(_updateTargetRect)까지 그려 본다.
Widget _harness(TutorialTargets targets, {GlobalKey? target}) {
  return Stack(
    children: [
      if (target != null)
        Positioned(
          left: 20,
          top: 120,
          child: SizedBox(key: target, width: 120, height: 48),
        ),
      TutorialOverlay(targets: targets),
    ],
  );
}

/// running 상태에서 빠져나오며 밀린 타이머를 비운다.
///
/// TutorialOverlay.build() 는 status 가 running 인 동안 매 프레임
/// `addPostFrameCallback(_syncStep)` 를 조건 없이 다시 예약한다
/// (TutorialOverlay.dart:112-114). `_syncStep` 은 스텝이 그대로여도
/// `_updateTargetRect()` 를 다시 부르고, 그 안의 `await Future.delayed(...)` 가
/// 진짜 FakeAsync Timer 를 만든다. 그 결과 running 상태가 유지되는 한 이
/// Timer 생성이 프레임마다 되풀이돼서 `pumpAndSettle()` 이 이 상태에서는
/// 수렴하지 않고(또는 지나치게 이르게 멈춰서), running 상태로 테스트를
/// 끝내면 "A Timer is still pending" 으로 테스트가 깨진다. 실제 버그로
/// 보인다 — 최종 보고에 기록.
///
/// 그래서 이 파일의 테스트는 running 중 상호작용에는 `pumpAndSettle` 대신
/// 딱 한 프레임만 `pump()` 하고, 테스트를 끝내기 전에는 항상 이 함수로
/// idle 로 빠져나와(스텝이 바뀌지 않는 한 더는 재예약이 없다) 시계를 충분히
/// 흘려보내 이미 떠 있는 타이머를 전부 비운다.
Future<void> exitRunning(WidgetTester tester, TutorialProvider provider) async {
  if (provider.status != TutorialStatus.idle) {
    await provider.skip();
    await tester.pump();
  }
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// [buttonText] 버튼을 누르고, 스텝 카드를 감싼 AnimatedSwitcher(180ms)
/// 전환이 끝날 만큼만 pump 한다. pumpAndSettle 은 running 상태에서 절대
/// 수렴하지 않으므로(위 [exitRunning] 설명 참고) 쓰지 않는다. 이 정도
/// 플러시가 없으면 이전 스텝 카드의 텍스트·버튼이 새 카드와 함께 잠깐
/// 공존해 `findsOneWidget`/`findsNothing` 단언이나 `tap()` 의 대상 특정이
/// 깨진다.
Future<void> tapAndPump(WidgetTester tester, String buttonText) async {
  await tester.tap(find.text(buttonText));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  setUpOnoWidgetTest();

  late TutorialTargets targets;
  late TutorialProvider provider;

  setUp(() {
    targets = TutorialTargets();
    provider = TutorialProvider(storage: _NoopTutorialStorage());
  });

  testWidgets('idle 상태면 오버레이가 보이지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
    );

    expect(provider.isVisible, isFalse);
    expect(find.text('건너뛰기'), findsNothing);
    expect(find.text('시작하기'), findsNothing);
    expect(find.textContaining('OnO를 빠르게 둘러볼까요'), findsNothing);
  });

  testWidgets('intro 상태면 안내 카드와 시작·건너뛰기 버튼이 보인다', (tester) async {
    provider.showReplayIntro(1);

    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
    );

    expect(find.textContaining('OnO를 빠르게 둘러볼까요'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
    expect(provider.isIntro, isTrue);

    await exitRunning(tester, provider);
  });

  testWidgets('시작하기를 누르면 첫 번째 스텝 카드로 진행된다', (tester) async {
    provider.showReplayIntro(1);

    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
    );

    await tapAndPump(tester, '시작하기');

    expect(provider.isRunning, isTrue);
    expect(provider.currentStepIndex, 0);
    expect(find.text(tutorialSteps[0].title), findsOneWidget);
    expect(find.text(tutorialSteps[0].description), findsOneWidget);
    expect(find.text('1 / ${tutorialSteps.length}'), findsOneWidget);

    await exitRunning(tester, provider);
  });

  testWidgets('첫 번째 스텝에서는 이전 버튼이 보이지 않는다', (tester) async {
    provider.showReplayIntro(1);
    provider.start();

    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
      settle: false,
    );

    expect(find.text('이전'), findsNothing);
    expect(find.text('다음'), findsOneWidget);

    await exitRunning(tester, provider);
  });

  testWidgets('다음을 누르면 두 번째 스텝의 제목·설명으로 바뀌고 이전 버튼이 나타난다', (tester) async {
    provider.showReplayIntro(1);
    provider.start();

    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
      settle: false,
    );

    await tapAndPump(tester, '다음');

    expect(provider.currentStepIndex, 1);
    expect(find.text(tutorialSteps[1].title), findsOneWidget);
    expect(find.text(tutorialSteps[1].description), findsOneWidget);
    expect(find.text(tutorialSteps[0].title), findsNothing);
    expect(find.text('2 / ${tutorialSteps.length}'), findsOneWidget);
    expect(find.text('이전'), findsOneWidget);

    await exitRunning(tester, provider);
  });

  testWidgets('이전을 누르면 앞 스텝으로 되돌아간다', (tester) async {
    provider.showReplayIntro(1);
    provider.start();

    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
      settle: false,
    );

    await tapAndPump(tester, '다음');
    await tapAndPump(tester, '이전');

    expect(provider.currentStepIndex, 0);
    expect(find.text(tutorialSteps[0].title), findsOneWidget);
    expect(find.text('이전'), findsNothing);

    await exitRunning(tester, provider);
  });

  testWidgets('스텝 카드의 건너뛰기를 누르면 오버레이가 즉시 사라진다', (tester) async {
    provider.showReplayIntro(1);
    provider.start();

    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
      settle: false,
    );

    await tapAndPump(tester, '건너뛰기');

    expect(provider.isVisible, isFalse);
    expect(find.text(tutorialSteps[0].title), findsNothing);

    await exitRunning(tester, provider);
  });

  testWidgets('마지막 스텝에서는 다음 버튼이 마무리로 표시되고, 누르면 종료 카드로 전환된다', (tester) async {
    provider.showReplayIntro(1);
    provider.start();

    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
      settle: false,
    );

    // 마지막 스텝 직전까지 다음을 눌러 진행한다.
    for (var i = 0; i < tutorialSteps.length - 1; i++) {
      await tapAndPump(tester, '다음');
    }

    expect(provider.currentStepIndex, tutorialSteps.length - 1);
    expect(find.text('마무리'), findsOneWidget);
    expect(find.text('다음'), findsNothing);

    await tapAndPump(tester, '마무리');

    expect(provider.isOutro, isTrue);
    expect(find.textContaining('좋아요, 이제 OnO와 함께 시작해봐요'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);

    await exitRunning(tester, provider);
  });

  testWidgets('종료 카드에서 이전을 누르면 마지막 스텝으로 돌아간다', (tester) async {
    provider.showReplayIntro(1);
    provider.start();

    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
      settle: false,
    );

    for (var i = 0; i < tutorialSteps.length - 1; i++) {
      await tapAndPump(tester, '다음');
    }
    await tapAndPump(tester, '마무리');

    await tapAndPump(tester, '이전');

    expect(provider.isRunning, isTrue);
    expect(provider.currentStepIndex, tutorialSteps.length - 1);
    expect(find.text(tutorialSteps.last.title), findsOneWidget);

    await exitRunning(tester, provider);
  });

  testWidgets('종료 카드에서 완료를 누르면 오버레이가 사라진다', (tester) async {
    provider.showReplayIntro(1);
    provider.start();

    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
      settle: false,
    );

    for (var i = 0; i < tutorialSteps.length - 1; i++) {
      await tapAndPump(tester, '다음');
    }
    await tapAndPump(tester, '마무리');

    await tapAndPump(tester, '완료');

    expect(provider.isVisible, isFalse);
    expect(find.textContaining('좋아요, 이제 OnO와 함께 시작해봐요'), findsNothing);

    await exitRunning(tester, provider);
  });

  testWidgets('실제 타겟 위젯이 있으면 예외 없이 하이라이트를 그린다', (tester) async {
    provider.showReplayIntro(1);
    provider.start(); // 첫 스텝은 folderList 를 가리킨다.

    await pumpOnoWidget(
      tester,
      _harness(targets, target: targets.folderListKey),
      tutorialProvider: provider,
      settle: false,
    );
    // _updateTargetRect 는 addPostFrameCallback + Future.delayed(280ms) 로
    // 위치를 찾으므로, running 상태를 유지한 채로 시계를 충분히 흘려 반영시킨다.
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    // 타겟을 감싸는 강조 테두리(3px 보더) 컨테이너가 그려졌는지 확인한다.
    final highlight = find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      if (decoration is! BoxDecoration) return false;
      final border = decoration.border;
      return border is Border && border.top.width == 3;
    });
    expect(highlight, findsOneWidget);

    await exitRunning(tester, provider);
  });

  testWidgets('타겟 위젯이 없어도 예외 없이 스텝 카드를 그린다', (tester) async {
    provider.showReplayIntro(1);
    provider.start();

    await pumpOnoWidget(
      tester,
      _harness(targets), // target 없음 -> GlobalKey.currentContext 가 계속 null
      tutorialProvider: provider,
      settle: false,
    );

    expect(tester.takeException(), isNull);
    expect(find.text(tutorialSteps[0].title), findsOneWidget);

    await exitRunning(tester, provider);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    provider.showReplayIntro(1);
    provider.start();

    await pumpOnoWidget(
      tester,
      _harness(targets),
      tutorialProvider: provider,
      surfaceSize: OnoSurface.tablet,
      settle: false,
    );

    expect(tester.takeException(), isNull);
    expect(find.text(tutorialSteps[0].title), findsOneWidget);

    await tapAndPump(tester, '다음');

    expect(tester.takeException(), isNull);
    expect(find.text(tutorialSteps[1].title), findsOneWidget);

    await exitRunning(tester, provider);
  });
}
