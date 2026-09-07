import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Provider/TutorialProvider.dart';
import 'package:ono/Screen/Tutorial/TutorialOverlay.dart';
import 'package:ono/Screen/Tutorial/TutorialStep.dart';
import 'package:ono/Screen/Tutorial/TutorialStorage.dart';
import 'package:ono/Screen/Tutorial/TutorialTargets.dart';

import '../../helpers/helpers.dart';

/// 튜토리얼 카드가 기기 하단 내비게이션을 침범하지 않는지 본다.
///
/// 갤럭시에서 `이전` / `다음` 이 하단 뒤로 가기·홈·앱 전환 영역과 겹쳐서
/// 눌리지 않는다는 제보가 있었다(이슈 #172). 카드는 `top` 만 정해 놓고
/// 높이는 짐작한 값(230)으로 자리를 잡는데, 글자 크기를 키운 기기에서는
/// 실제 카드가 그보다 훨씬 커져서 아래로 삐져나온다.
class _NoopTutorialStorage extends TutorialStorage {
  @override
  Future<bool> isCompleted(int userId) async => false;

  @override
  Future<void> markCompleted(int userId) async {}
}

/// 갤럭시처럼 하단에 시스템 영역이 있는 기기를 흉내 낸다.
///
/// [systemBottom] 은 3버튼 내비게이션 영역이고, [textScale] 은 사용자가
/// 설정에서 키운 글자 크기다. 삼성 기기는 기본 글자가 크고, 접근성에서 더
/// 키우는 사용자도 많다.
Widget _galaxyHarness(
  TutorialTargets targets, {
  required double systemBottom,
  required double textScale,
}) {
  return Builder(
    builder: (context) {
      final base = MediaQuery.of(context);
      return MediaQuery(
        data: base.copyWith(
          padding: EdgeInsets.only(top: 24, bottom: systemBottom),
          viewPadding: EdgeInsets.only(top: 24, bottom: systemBottom),
          systemGestureInsets: EdgeInsets.only(bottom: systemBottom),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Stack(
          children: [TutorialOverlay(targets: targets)],
        ),
      );
    },
  );
}

/// 제스처 내비게이션 기기. padding 은 작지만 화면 아래에서 쓸어 올리는
/// 영역(systemGestureInsets)이 넓다.
Widget _gestureNavHarness(
  TutorialTargets targets, {
  required double gestureBottom,
  required double textScale,
}) {
  return Builder(
    builder: (context) {
      final base = MediaQuery.of(context);
      return MediaQuery(
        data: base.copyWith(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
          systemGestureInsets: EdgeInsets.only(bottom: gestureBottom),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Stack(
          children: [TutorialOverlay(targets: targets)],
        ),
      );
    },
  );
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

  /// 갤럭시 S 계열 세로. 3버튼 내비게이션 48dp.
  const galaxy = Size(360, 800);
  const smallGalaxy = Size(320, 640);
  const systemBottom = 48.0;

  Future<void> pumpStep(
    WidgetTester tester, {
    required double textScale,
    Size surfaceSize = galaxy,
  }) async {
    provider.showReplayIntro(1);
    provider.start();

    await pumpOnoWidget(
      tester,
      _galaxyHarness(
        targets,
        systemBottom: systemBottom,
        textScale: textScale,
      ),
      tutorialProvider: provider,
      surfaceSize: surfaceSize,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 250));
  }

  /// 버튼이 시스템 내비게이션 영역 위에 온전히 있는지 본다.
  void expectAboveSystemBar(
    WidgetTester tester,
    String label, {
    required Size surfaceSize,
  }) {
    final rect = tester.getRect(find.text(label));
    expect(
      rect.bottom,
      lessThanOrEqualTo(surfaceSize.height - systemBottom),
      reason: '$label 버튼이 하단 내비게이션 영역($systemBottom dp)을 침범했다',
    );
  }

  testWidgets('기본 글자 크기에서 다음 버튼이 내비게이션 위에 있다', (tester) async {
    await pumpStep(tester, textScale: 1.0);

    expectAboveSystemBar(tester, '다음', surfaceSize: galaxy);
    expectAboveSystemBar(tester, '건너뛰기', surfaceSize: galaxy);

    await exitRunning(tester, provider);
  });

  testWidgets('글자 크기를 키워도 다음 버튼이 내비게이션 위에 있다', (tester) async {
    // 이게 이슈 #172 의 상황이다. 카드가 짐작한 높이보다 커지면서 버튼이
    // 하단 내비게이션 영역으로 내려앉았다.
    await pumpStep(tester, textScale: 1.5);

    expectAboveSystemBar(tester, '다음', surfaceSize: galaxy);
    expectAboveSystemBar(tester, '건너뛰기', surfaceSize: galaxy);

    await exitRunning(tester, provider);
  });

  testWidgets('작은 폰에서 글자를 크게 해도 버튼이 화면 안에 있다', (tester) async {
    await pumpStep(tester, textScale: 1.5, surfaceSize: smallGalaxy);

    expectAboveSystemBar(tester, '다음', surfaceSize: smallGalaxy);
    expectAboveSystemBar(tester, '건너뛰기', surfaceSize: smallGalaxy);

    await exitRunning(tester, provider);
  });

  testWidgets('태블릿에서도 버튼이 내비게이션 위에 있다', (tester) async {
    await pumpStep(tester, textScale: 1.3, surfaceSize: OnoSurface.tablet);

    expectAboveSystemBar(tester, '다음', surfaceSize: OnoSurface.tablet);
    expectAboveSystemBar(tester, '건너뛰기', surfaceSize: OnoSurface.tablet);

    await exitRunning(tester, provider);
  });

  testWidgets('제스처 내비게이션에서 인트로 버튼이 제스처 영역을 피한다', (tester) async {
    // 제스처 내비게이션 기기는 padding.bottom 이 작게 잡히는 대신
    // systemGestureInsets.bottom 이 크다. SafeArea 는 padding 만 보므로
    // 그것만 믿으면 버튼이 화면 아래에서 쓸어 올리는 영역에 걸린다.
    provider.showReplayIntro(1);

    await pumpOnoWidget(
      tester,
      _gestureNavHarness(targets, gestureBottom: systemBottom, textScale: 2.0),
      tutorialProvider: provider,
      surfaceSize: smallGalaxy,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 250));

    expectAboveSystemBar(tester, '시작하기', surfaceSize: smallGalaxy);
    expectAboveSystemBar(tester, '건너뛰기', surfaceSize: smallGalaxy);

    await exitRunning(tester, provider);
  });

  testWidgets('제스처 내비게이션에서 종료 카드 버튼이 제스처 영역을 피한다', (tester) async {
    provider.showReplayIntro(1);
    provider.start();
    for (var i = 0; i < tutorialSteps.length; i++) {
      provider.next();
    }

    await pumpOnoWidget(
      tester,
      _gestureNavHarness(targets, gestureBottom: systemBottom, textScale: 2.0),
      tutorialProvider: provider,
      surfaceSize: smallGalaxy,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(provider.isOutro, isTrue);
    expectAboveSystemBar(tester, '완료', surfaceSize: smallGalaxy);

    await exitRunning(tester, provider);
  });
}
