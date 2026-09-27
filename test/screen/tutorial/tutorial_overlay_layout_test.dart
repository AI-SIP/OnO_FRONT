import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Provider/TutorialProvider.dart';
import 'package:ono/Screen/Tutorial/TutorialOverlay.dart';
import 'package:ono/Screen/Tutorial/TutorialStep.dart';
import 'package:ono/Screen/Tutorial/TutorialStorage.dart';
import 'package:ono/Screen/Tutorial/TutorialTargets.dart';

import '../../helpers/helpers.dart';

/// 튜토리얼 안내 카드의 자리와 강조 영역을 잠근다(이슈 #201).
///
/// 세 가지가 문제였다. 카드 높이를 짐작값(폰 230, 태블릿 310에 글자 배율)으로
/// 잡아서 설명이 긴 단계는 카드 안에서 스크롤해야 끝까지 보였고, 2/7
/// `오답노트 작성 시작` 단계는 카드가 설명 중인 + 추가 버튼을 덮었고, 4/7
/// `레벨과 성장` 단계는 강조 사각형이 하단 탭 바까지 감쌌다.
class _NoopTutorialStorage extends TutorialStorage {
  @override
  Future<bool> isCompleted(int userId) async => false;

  @override
  Future<void> markCompleted(int userId) async {}
}

/// 3버튼 내비게이션 영역. 갤럭시 S 계열이 48dp 다.
const double _systemBottom = 48.0;

/// 상태 바.
const double _safeTop = 24.0;

/// 하단 탭 바. main.dart 의 BottomNavigationBar 가 이 높이를 쓴다.
const double _navBar = kBottomNavigationBarHeight;

typedef _Surface = ({String name, Size size});

const _Surface _smallPhone = (name: '320dp 폰', size: OnoSurface.smallPhone);
const _Surface _phone = (name: '390dp 폰', size: OnoSurface.phone);
const _Surface _tablet = (name: '태블릿', size: OnoSurface.tablet);

/// 가로로 돌린 폰. 앱이 방향을 잠그지 않으므로 이 모양도 나온다.
/// 세로 여유가 320 밖에 없어서 카드가 쓸 수 있는 띠가 가장 좁다.
const _Surface _landscapePhone = (name: '가로 폰', size: Size(844, 390));

/// 카드가 들어가도 되는 띠의 아래 끝. 여기부터 아래는 탭 바와 시스템 영역이다.
double _bandBottom(Size surface) =>
    surface.height - _systemBottom - _navBar - 12;

/// [targetRect] 자리에 대상 위젯을 놓고 오버레이를 띄운다.
///
/// 대상을 안 넘기면 GlobalKey 가 풀리지 않아 오버레이의 `_targetRect` 가 null
/// 로 남는다. 카드가 기본 자리(화면 아래)에 앉는 경우가 그것이다.
Widget _harness(
  TutorialTargets targets, {
  GlobalKey? target,
  Rect? targetRect,
  double textScale = 1.0,
}) {
  return Builder(
    builder: (context) {
      final base = MediaQuery.of(context);
      return MediaQuery(
        data: base.copyWith(
          padding: const EdgeInsets.only(top: _safeTop, bottom: _systemBottom),
          viewPadding:
              const EdgeInsets.only(top: _safeTop, bottom: _systemBottom),
          systemGestureInsets: const EdgeInsets.only(bottom: _systemBottom),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Stack(
          children: [
            if (target != null && targetRect != null)
              Positioned.fromRect(
                rect: targetRect,
                child: SizedBox(key: target),
              ),
            TutorialOverlay(targets: targets),
          ],
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

  /// [stepIndex] 단계까지 진행한 상태로 오버레이를 띄운다.
  Future<void> pumpStep(
    WidgetTester tester, {
    required int stepIndex,
    required Size surfaceSize,
    double textScale = 1.0,
    GlobalKey? target,
    Rect? targetRect,
  }) async {
    provider.showReplayIntro(1);
    provider.start();
    for (var i = 0; i < stepIndex; i++) {
      provider.next();
    }

    await pumpOnoWidget(
      tester,
      _harness(
        targets,
        target: target,
        targetRect: targetRect,
        textScale: textScale,
      ),
      tutorialProvider: provider,
      surfaceSize: surfaceSize,
      settle: false,
    );
    // _updateTargetRect 가 addPostFrameCallback + Future.delayed(280ms) 로
    // 대상 위치를 찾는다. 카드 전환(AnimatedSwitcher)까지 끝날 만큼 흘린다.
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// 안내 카드의 네모. 단계가 바뀌어도 카드는 같은 key 를 달고 있다.
  Rect cardRect(WidgetTester tester) {
    return tester.getRect(find.byKey(tutorialStepCardKey));
  }

  /// 카드 안에서 더 스크롤해야 하는 양. 0 이면 설명이 한 번에 다 보인다.
  double leftToScroll(WidgetTester tester) {
    final scrollable = find.descendant(
      of: find.byType(TutorialOverlay),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    return tester.state<ScrollableState>(scrollable).position.maxScrollExtent;
  }

  /// 강조 사각형. 단계가 바뀔 때 테두리가 3에서 6까지 두꺼워졌다 돌아온다.
  Finder highlightFinder() {
    return find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      if (decoration is! BoxDecoration) return false;
      final border = decoration.border;
      if (border is! Border) return false;
      return border.top.width >= 3 && border.top.width <= 6;
    });
  }

  /// 카드가 상태 바와 탭 바 사이에 온전히 들어 있는지 본다.
  void expectCardInsideBand(
    WidgetTester tester,
    int stepIndex, {
    required Size surface,
  }) {
    final card = cardRect(tester);
    final where = '${stepIndex + 1}/${tutorialSteps.length} '
        '`${tutorialSteps[stepIndex].title}`';
    expect(card.top, greaterThanOrEqualTo(_safeTop),
        reason: '$where 카드가 상태 바 위로 올라갔다');
    expect(card.bottom, lessThanOrEqualTo(_bandBottom(surface)),
        reason: '$where 카드가 하단 탭 바를 침범했다');

    final lastStep = stepIndex == tutorialSteps.length - 1;
    for (final label in <String>['건너뛰기', lastStep ? '마무리' : '다음']) {
      expect(
        tester.getRect(find.text(label)).bottom,
        lessThanOrEqualTo(surface.height - _systemBottom),
        reason: '$where $label 버튼이 하단 내비게이션 영역을 침범했다',
      );
    }
  }

  group('설명이 스크롤 없이 한 번에 보인다', () {
    // 글자 1배에서 가장 긴 단계가 폰 320dp 에서 392, 태블릿에서 341 이다.
    // 카드가 쓸 수 있는 띠는 320x640 에서도 488 이라 전부 들어가야 한다.
    // 1.6배는 320x640 만 물리적으로 모자라고(가장 긴 단계가 658), 그건 아래
    // 그룹에서 따로 본다.
    for (final (surface, textScale) in <(_Surface, double)>[
      (_smallPhone, 1.0),
      (_phone, 1.0),
      (_phone, 1.6),
      (_tablet, 1.0),
      (_tablet, 1.6),
    ]) {
      testWidgets('${surface.name} 글자 $textScale 배 — 일곱 단계 전부', (tester) async {
        for (var index = 0; index < tutorialSteps.length; index++) {
          provider = TutorialProvider(storage: _NoopTutorialStorage());
          await pumpStep(
            tester,
            stepIndex: index,
            surfaceSize: surface.size,
            textScale: textScale,
          );

          expect(find.text(tutorialSteps[index].description), findsOneWidget);
          expect(
            leftToScroll(tester),
            0,
            reason: '${index + 1}/${tutorialSteps.length} '
                '`${tutorialSteps[index].title}` 설명이 카드 밖으로 넘쳐서 '
                '스크롤해야 끝까지 보인다',
          );
          expectCardInsideBand(tester, index, surface: surface.size);

          await exitRunning(tester, provider);
        }
      });
    }
  });

  group('세로 여유가 모자라는 화면에서도', () {
    // 가로로 돌린 폰은 카드가 쓸 수 있는 띠가 230 뿐이다. 스크롤은
    // 어쩔 수 없고, 카드가 화면 밖으로 나가지 않는 것만 잠근다.
    testWidgets('가로 폰 — 카드가 화면 안에 있다', (tester) async {
      for (var index = 0; index < tutorialSteps.length; index++) {
        provider = TutorialProvider(storage: _NoopTutorialStorage());
        await pumpStep(
          tester,
          stepIndex: index,
          surfaceSize: _landscapePhone.size,
        );

        expectCardInsideBand(tester, index, surface: _landscapePhone.size);

        await exitRunning(tester, provider);
      }
    });
  });

  group('320dp 화면에 글자를 1.6배로 키우면', () {
    // 이 조합은 가장 긴 단계가 658 인데 카드가 쓸 수 있는 띠가 488 이라
    // 어떻게 해도 안 들어간다. 카드 안에서 스크롤하는 것까지는 받아들이고,
    // 대신 카드가 화면 밖으로 나가지 않는 것만 잠근다.
    testWidgets('스크롤은 남지만 카드가 화면 안에 있다', (tester) async {
      for (var index = 0; index < tutorialSteps.length; index++) {
        provider = TutorialProvider(storage: _NoopTutorialStorage());
        await pumpStep(
          tester,
          stepIndex: index,
          surfaceSize: _smallPhone.size,
          textScale: 1.6,
        );

        expectCardInsideBand(tester, index, surface: _smallPhone.size);

        await exitRunning(tester, provider);
      }
    });
  });

  group('2/7 오답노트 작성 시작', () {
    /// + 추가 버튼은 FloatingActionButtonLocation.endFloat 이라 화면 오른쪽
    /// 아래, 하단 탭 바 바로 위에 앉는다.
    Rect fabRect(Size surface) {
      const fab = 56.0;
      final bottom = surface.height - _systemBottom - _navBar - 16;
      return Rect.fromLTWH(surface.width - 16 - fab, bottom - fab, fab, fab);
    }

    for (final (surface, textScale) in <(_Surface, double)>[
      (_smallPhone, 1.0),
      (_smallPhone, 1.6),
      (_phone, 1.0),
      (_phone, 1.6),
      (_tablet, 1.0),
    ]) {
      testWidgets('${surface.name} 글자 $textScale 배 — 카드가 + 추가 버튼을 덮지 않는다',
          (tester) async {
        final rect = fabRect(surface.size);

        await pumpStep(
          tester,
          stepIndex: 1,
          surfaceSize: surface.size,
          textScale: textScale,
          target: targets.directoryCreateFabKey,
          targetRect: rect,
        );

        expect(provider.currentStep.id, 'create_problem_note');
        // 대상이 화면 맨 아래에 있어서 아래쪽에는 카드가 들어갈 자리가 없다.
        // 카드는 대상 위로 올라와야 한다.
        expect(
          cardRect(tester).bottom,
          lessThanOrEqualTo(rect.top),
          reason: '카드가 + 추가 버튼 위로 올라오지 않아 설명 중인 버튼을 덮었다',
        );
        expectCardInsideBand(tester, 1, surface: surface.size);

        await exitRunning(tester, provider);
      });
    }
  });

  group('4/7 레벨과 성장', () {
    for (final surface in <_Surface>[_smallPhone, _phone, _tablet]) {
      testWidgets('${surface.name} — 강조 영역이 하단 탭 바를 덮지 않는다', (tester) async {
        // 이 단계의 대상 키는 화면 전체를 차지하는 _CharacterStage 에 붙어
        // 있다. 그래서 강조가 그대로 탭 바 위로 그려졌다.
        await pumpStep(
          tester,
          stepIndex: 3,
          surfaceSize: surface.size,
          target: targets.levelCardKey,
          targetRect: Offset.zero & surface.size,
        );

        expect(provider.currentStep.id, 'level');

        final highlight = highlightFinder();
        expect(highlight, findsOneWidget);
        final band = tester.getRect(highlight);
        expect(
          band.bottom,
          lessThanOrEqualTo(surface.size.height - _systemBottom - _navBar),
          reason: '강조 사각형이 하단 탭 바까지 감쌌다',
        );
        expect(
          band.top,
          greaterThanOrEqualTo(_safeTop),
          reason: '강조 사각형이 상태 바까지 올라갔다',
        );
        expect(leftToScroll(tester), 0);

        await exitRunning(tester, provider);
      });
    }
  });
}
