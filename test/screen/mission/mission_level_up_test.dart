// 레벨업 연출 테스트.
//
// 진화는 그림이 실제로 바뀔 때만 보여 준다. 지금 개구리 에셋이 홀수 여덟
// 장이라 레벨이 올라도 그림이 그대로인 구간이 있는데, 그때 같은 그림 두 장을
// 놓고 "바뀌었다"고 하면 안 된다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/Mission/MissionLevelUp.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  group('개구리 그림', () {
    test('레벨이 오르면 그 레벨의 그림을 준다', () {
      expect(
        FrogCharacter.assetPathOf(1),
        'assets/FrogCharacter/FROG_LEVEL1.png',
      );
      expect(
        FrogCharacter.assetPathOf(9),
        'assets/FrogCharacter/FROG_LEVEL9.png',
      );
      expect(
        FrogCharacter.assetPathOf(15),
        'assets/FrogCharacter/FROG_LEVEL15.png',
      );
      // 표를 벗어난 값도 그림은 있어야 한다.
      expect(
        FrogCharacter.assetPathOf(0),
        'assets/FrogCharacter/FROG_LEVEL1.png',
      );
      expect(
        FrogCharacter.assetPathOf(99),
        'assets/FrogCharacter/FROG_LEVEL15.png',
      );
    });

    test('그림이 실제로 바뀌는 구간만 진화로 본다', () {
      // 에셋이 홀수 여덟 장이라 짝수 레벨로 오를 때는 그림이 그대로다.
      expect(FrogCharacter.evolvesBetween(2, 3), isTrue);
      expect(FrogCharacter.evolvesBetween(7, 8), isFalse);
      expect(FrogCharacter.evolvesBetween(8, 9), isTrue);
      expect(FrogCharacter.evolvesBetween(14, 15), isTrue);
      expect(FrogCharacter.evolvesBetween(15, 15), isFalse);
    });
  });

  group('해금된 테마', () {
    test('새로 열린 것만 골라낸다', () {
      expect(newlyUnlockedThemeIndexes({0, 1}, {0, 1, 8, 9}), [8, 9]);
      expect(newlyUnlockedThemeIndexes({0, 1}, {0, 1}), isEmpty);
    });

    test('테마 수를 넘는 번호는 버린다', () {
      expect(newlyUnlockedThemeIndexes(const {}, {0, 999}), [0]);
    });
  });

  group('레벨 문구', () {
    test('레벨마다 다른 말을 한다', () {
      expect(missionLevelPhraseOf(2), '이제 막 시작이에요');
      expect(missionLevelPhraseOf(7), '이제 능숙해졌어요');
      expect(missionLevelPhraseOf(15), '최고 레벨이에요');
    });

    test('표를 벗어나면 양 끝 문구로 떨어진다', () {
      expect(missionLevelPhraseOf(1), missionLevelPhraseOf(2));
      expect(missionLevelPhraseOf(99), missionLevelPhraseOf(15));
    });
  });

  group('화면', () {
    Future<void> pumpLevelUp(
      WidgetTester tester, {
      required int level,
      int? previousLevel,
      List<int> unlocked = const [],
      bool reduceMotion = true,
      bool settle = true,
    }) async {
      if (reduceMotion) disableAnimationsForTest(tester);
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showMissionLevelUp(
                  context,
                  level: level,
                  previousLevel: previousLevel,
                  unlockedThemeIndexes: unlocked,
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        // 연출이 도는 도중을 봐야 해서 끝까지 흘려보내지 않는다.
        await tester.pump();
      }
    }

    testWidgets('레벨과 문구를 보여 준다', (tester) async {
      await pumpLevelUp(tester, level: 7, previousLevel: 6);

      expect(find.text('Lv.6'), findsOneWidget);
      expect(find.text(missionLevelPhraseOf(7)), findsOneWidget);
      expect(find.text('계속하기'), findsOneWidget);
    });

    /// 지금 화면에 그려진 개구리 그림들.
    Set<String> drawnFrogs(WidgetTester tester) {
      return tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as AssetImage).assetName)
          .toSet();
    }

    testWidgets('그림이 바뀌는 레벨업은 이전 개구리에서 새 개구리로 넘어간다', (tester) async {
      await pumpLevelUp(
        tester,
        level: 9,
        previousLevel: 8,
        reduceMotion: false,
        settle: false,
      );

      // 진화는 한순간에 지나가서 마지막 프레임만 보면 새 개구리뿐이다.
      // 연출이 도는 동안 나온 그림을 모아서 본다.
      final seen = <String>{...drawnFrogs(tester)};
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        seen.addAll(drawnFrogs(tester));
      }

      expect(seen.contains(FrogCharacter.assetPathOf(8)), isTrue);
      expect(seen.contains(FrogCharacter.assetPathOf(9)), isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('그림이 그대로면 한 장만 그린다', (tester) async {
      // Lv.7 → Lv.8 은 그림이 같다. 진화한 척하지 않는다.
      await pumpLevelUp(
        tester,
        level: 8,
        previousLevel: 7,
        reduceMotion: false,
        settle: false,
      );

      final seen = <String>{...drawnFrogs(tester)};
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        seen.addAll(drawnFrogs(tester));
      }

      expect(seen, {FrogCharacter.assetPathOf(8)});

      await tester.pumpAndSettle();
    });

    testWidgets('연출을 끈 기기에서는 지금 개구리만 그린다', (tester) async {
      await pumpLevelUp(tester, level: 9, previousLevel: 8);

      expect(drawnFrogs(tester), {FrogCharacter.assetPathOf(9)});
    });

    testWidgets('해금된 테마가 있으면 색과 이름을 보여 준다', (tester) async {
      await pumpLevelUp(tester, level: 6, previousLevel: 5, unlocked: [8]);

      expect(find.text('새 테마가 열렸어요'), findsOneWidget);
      expect(find.text('라이트그린'), findsOneWidget);
      expect(find.text('바로 적용해보기'), findsOneWidget);
    });

    testWidgets('해금된 테마가 없으면 그 자리는 통째로 없다', (tester) async {
      await pumpLevelUp(tester, level: 6, previousLevel: 5);

      expect(find.text('새 테마가 열렸어요'), findsNothing);
      expect(find.text('바로 적용해보기'), findsNothing);
    });
  });
}
