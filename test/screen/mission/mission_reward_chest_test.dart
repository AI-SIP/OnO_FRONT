// 보상 상자 연출 테스트.
//
// 이 연출에서 중요한 것은 모양이 아니라 **순서**다. 상자가 열리기 전에 보상이
// 먼저 보이면 상자를 여는 의미가 없다. 그래서 마지막 프레임만 보지 않고
// 조금씩 흘려보내며 무엇이 언제 처음 나타나는지를 적어 잠근다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Screen/Mission/MissionRewardCelebration.dart';
import 'package:ono/Screen/Mission/MissionRewardChest.dart';

import '../../helpers/helpers.dart';

/// 지금 화면에 그려진 상자 프레임들.
Set<String> _drawnFrames(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => (image.image as AssetImage).assetName)
      .where((name) => name.startsWith('assets/Reward/'))
      .toSet();
}

/// 보상 액수가 지금 얼마나 또렷한지. 0 이면 아직 안 보이는 것이다.
double _amountOpacity(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byKey(missionRewardAmountKey),
    matching: find.byType(Opacity),
  );
  return tester.widgetList<Opacity>(finder).first.opacity;
}

void main() {
  setUpOnoWidgetTest();

  group('상자가 움직이는 값', () {
    test('예비 동작이 끝나는 지점과 튀어오름이 시작되는 지점이 이어진다', () {
      // 여기가 어긋나면 열리는 순간에 상자가 한 프레임 튄다.
      const openAt = MissionChestTiming.openAt;

      expect(missionChestSquash(openAt - 0.001), closeTo(-1, 0.01));
      expect(missionChestSquash(openAt), closeTo(-1, 0.01));
    });

    test('눌림도 흔들림도 끝에서는 0 으로 잦아든다', () {
      expect(missionChestSquash(0), 0);
      expect(missionChestSquash(1), 0);
      expect(missionChestTilt(0), 0);
      // 흔들림은 열리는 순간에 정확히 멈춰야 한다. 기울어진 채로 열리면 안 된다.
      expect(missionChestTilt(MissionChestTiming.openAt), 0);
      expect(missionChestHop(1), 0);
    });

    test('상자가 열리기 전에는 안의 것이 보이지 않는다', () {
      expect(missionChestContentAt(0).opacity, 0);
      expect(missionChestContentAt(MissionChestTiming.openAt).opacity, 0);
      // 열린 뒤에야 떠오르기 시작한다.
      expect(
        missionChestContentAt(MissionChestTiming.contentStart + 0.05).opacity,
        greaterThan(0),
      );
      expect(missionChestContentAt(1).opacity, 1);
    });

    test('떠오르는 것은 상자 안에서 출발해 위로 올라간다', () {
      final start = missionChestContentAt(MissionChestTiming.contentStart);
      final end = missionChestContentAt(1);

      expect(start.dy, greaterThan(end.dy), reason: '아래에서 위로 올라와야 한다');
      expect(end.scale, 1);
    });
  });

  group('보상 상자 연출', () {
    /// 보상 카드를 띄운다. [reduceMotion] 을 끄면 연출이 도는 중간을 볼 수 있다.
    Future<void> pumpCelebration(
      WidgetTester tester, {
      bool reduceMotion = true,
      bool levelUpFollows = false,
    }) async {
      if (reduceMotion) disableAnimationsForTest(tester);

      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showMissionRewardCelebration(
                  context,
                  missionTitle: '오답 3개 등록하기',
                  rewardType: MissionRewardType.xp,
                  amount: 10,
                  levelUpFollows: levelUpFollows,
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
        settle: false,
      );
      await tester.pump();
      await tester.tap(find.text('열기'));
      // 연출이 도는 도중을 봐야 해서 끝까지 흘려보내지 않는다.
      await tester.pump();
    }

    testWidgets('닫힘 → 열림 → 내용물 등장 순서로 상자가 열린다', (tester) async {
      await pumpCelebration(tester, reduceMotion: false);

      // 연출은 한순간에 지나가서 마지막 프레임만 보면 열린 상자뿐이다.
      // 조금씩 흘려보내며 각 프레임이 처음 나온 때를 적어 둔다.
      final firstSeen = <String, int>{};
      var amountSeenAt = -1;
      for (var elapsed = 0; elapsed <= 900; elapsed += 30) {
        for (final name in _drawnFrames(tester)) {
          firstSeen.putIfAbsent(name, () => elapsed);
        }
        if (amountSeenAt < 0 && _amountOpacity(tester) > 0) {
          amountSeenAt = elapsed;
        }
        await tester.pump(const Duration(milliseconds: 30));
      }

      expect(
        firstSeen[MissionChestFrame.closed],
        0,
        reason: '연출은 닫힌 상자에서 시작한다',
      );
      expect(
        firstSeen.keys,
        containsAll([MissionChestFrame.open, MissionChestFrame.reveal]),
      );
      expect(
        firstSeen[MissionChestFrame.closed]!,
        lessThan(firstSeen[MissionChestFrame.open]!),
        reason: '닫힌 상자를 보여 주는 구간이 있어야 열림이 산다',
      );
      expect(
        firstSeen[MissionChestFrame.open]!,
        lessThan(firstSeen[MissionChestFrame.reveal]!),
        reason: '열리자마자 별이 떠 있으면 여는 순간이 정점이 되지 못한다',
      );

      // 보상 액수는 상자가 열린 뒤에 떠오른다. 먼저 뜨면 상자를 여는 의미가 없다.
      expect(amountSeenAt, greaterThan(0));
      expect(
        amountSeenAt,
        greaterThan(firstSeen[MissionChestFrame.open]!),
        reason: '상자가 열리기 전에 보상 액수가 보였다',
      );
    });

    testWidgets('연출을 끈 기기에서는 열린 상자와 보상을 바로 보여 준다', (tester) async {
      await pumpCelebration(tester);

      expect(_drawnFrames(tester), {MissionChestFrame.reveal});
      expect(find.text('+10 XP'), findsOneWidget);
      expect(find.text('오답 3개 등록하기'), findsOneWidget);
    });

    /// [total] 만큼을 잘게 나눠 흘려 보낸다.
    ///
    /// 한 번에 크게 건너뛰면 라우트가 물러나는 구간이 한 프레임에 뭉개져서
    /// "언제 사라졌는가"를 재는 데 쓸 수 없다.
    Future<void> pumpSteps(WidgetTester tester, int total) async {
      for (var elapsed = 0; elapsed < total; elapsed += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('레벨업이 뒤따르면 상자 카드가 더 일찍 물러난다', (tester) async {
      await pumpCelebration(tester, reduceMotion: false, levelUpFollows: true);

      await pumpSteps(tester, 900);
      expect(
        find.byKey(missionRewardCelebrationKey),
        findsOneWidget,
        reason: '상자가 열리는 도중에 카드가 사라지면 안 된다',
      );

      await pumpSteps(tester, 500);
      expect(
        find.byKey(missionRewardCelebrationKey),
        findsNothing,
        reason: '레벨업 화면이 뒤에 붙는데 상자까지 오래 머물면 전체가 늘어진다',
      );

      await tester.pumpAndSettle();
    });

    testWidgets('레벨업이 없으면 열린 상자를 조금 더 보여 준다', (tester) async {
      await pumpCelebration(tester, reduceMotion: false);
      await pumpSteps(tester, 1300);

      expect(
        find.byKey(missionRewardCelebrationKey),
        findsOneWidget,
        reason: '뒤에 아무것도 없으면 열린 상자를 조금 더 보고 갈 수 있어야 한다',
      );

      await tester.pumpAndSettle();
    });

    for (final size in [OnoSurface.smallPhone, OnoSurface.tablet]) {
      testWidgets('${size.width.toInt()}dp 에서 넘치지 않는다', (tester) async {
        disableAnimationsForTest(tester);

        await pumpOnoWidget(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.6)),
              child: Builder(
                builder: (inner) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => showMissionRewardCelebration(
                        inner,
                        missionTitle: '오답을 세 개 등록하고 복습까지 마치기',
                        rewardType: MissionRewardType.xp,
                        amount: 100,
                        levelUpFollows: false,
                      ),
                      child: const Text('열기'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          surfaceSize: size,
          settle: false,
        );
        await tester.pump();
        await tester.tap(find.text('열기'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason: '${size.width.toInt()}dp 글자 1.6배에서 넘쳤다',
        );
        expect(find.byKey(missionRewardCelebrationKey), findsOneWidget);

        await tester.pumpAndSettle();
      });
    }
  });
}
