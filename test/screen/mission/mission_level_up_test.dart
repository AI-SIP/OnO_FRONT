// 레벨업 연출 테스트.
//
// 개구리 그림은 더 이상 레벨에 따라 바뀌지 않는다. 그래서 성장은 이번에 열린
// 치장을 개구리에 직접 입혀서만 보인다. 여기서 잠그는 것은 두 가지다.
// 하나는 "무엇이 몇 개 열렸는지"를 세는 계산이고, 다른 하나는 그것이 개구리에
// 실제로 얹히는지다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticItemModel.dart';
import 'package:ono/Model/Cosmetic/CosmeticLoadoutModel.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Screen/Mission/MissionLevelUp.dart';

import '../../helpers/helpers.dart';

/// 테스트에서 쓰는 아이템 한 건.
CosmeticItemModel _item(
  String itemKey,
  String slot, {
  String? nameKo,
  String imageUrl = '',
  int? level,
}) {
  return CosmeticItemModel(
    itemKey: itemKey,
    slot: slot,
    nameKo: nameKo ?? itemKey,
    imageUrl: imageUrl.isEmpty ? 'assets/Cosmetic/$itemKey.png' : imageUrl,
    requiredLevel: level,
    setId: null,
    conflictsWith: const [],
    owned: level != null,
  );
}

/// 층 한 장.
CosmeticLayerModel _layer(String? itemKey, int order, {String? slot}) {
  return CosmeticLayerModel(
    imageUrl: itemKey == null
        ? CosmeticLoadoutModel.defaultBaseImageUrl
        : 'assets/Cosmetic/$itemKey.png',
    layerOrder: order,
    slot: slot,
    itemKey: itemKey,
  );
}

/// 칸마다 걸려 있는 아이템 키들. 순서가 곧 겹쳐 그리는 순서다.
List<List<String?>> _keysOf(List<List<CosmeticLayerModel>> stages) {
  return [
    for (final stage in stages) [for (final layer in stage) layer.itemKey],
  ];
}

void main() {
  setUpOnoWidgetTest();

  group('이번에 열린 치장', () {
    List<CosmeticItemModel> unlockedAt(int level) => switch (level) {
          3 => [_item('bg_spring', 'BACKGROUND', level: 3)],
          4 => [_item('glasses_round', 'FACE', level: 4)],
          _ => const [],
        };

    test('오른 구간의 것을 레벨 순서대로 모은다', () {
      final unlocked = missionUnlocksBetween(2, 4, unlockedAt);

      expect(
        unlocked.map((item) => item.itemKey),
        ['bg_spring', 'glasses_round'],
      );
    });

    test('오르기 전 레벨의 것은 세지 않는다', () {
      // Lv.3 에서 Lv.4 로 오르면 Lv.3 의 것은 이미 가지고 있던 것이다.
      expect(
        missionUnlocksBetween(3, 4, unlockedAt).map((item) => item.itemKey),
        ['glasses_round'],
      );
    });

    test('열린 것이 없는 구간은 빈 목록이다', () {
      expect(missionUnlocksBetween(4, 5, unlockedAt), isEmpty);
    });

    test('레벨이 오르지 않았으면 빈 목록이다', () {
      expect(missionUnlocksBetween(5, 5, unlockedAt), isEmpty);
      expect(missionUnlocksBetween(5, 3, unlockedAt), isEmpty);
    });

    test('더미 카탈로그에서 Lv.14 → Lv.15 는 학사 세트 세 개다', () {
      final provider = CosmeticProvider();
      final unlocked = missionUnlocksBetween(14, 15, provider.unlockedAt);

      expect(
        unlocked.map((item) => item.itemKey),
        containsAll(['hat_graduate', 'outfit_graduate', 'prop_diploma']),
      );
      expect(unlocked, hasLength(3));
    });
  });

  group('입혀 가는 중간 차림', () {
    test('열린 것이 없으면 오르기 전 차림 한 칸뿐이다', () {
      final before = [_layer(null, 300)];

      final stages = missionUnlockStages(
        before: before,
        after: before,
        unlocked: const [],
      );

      expect(stages, hasLength(1));
      expect(_keysOf(stages), [
        [null]
      ]);
    });

    test('아이템 수만큼 칸이 늘고 하나씩 더 걸린다', () {
      final base = _layer(null, 300);
      final hat = _layer('hat_beanie', 700, slot: 'HEAD');
      final bag = _layer('bag_mini_backpack', 450, slot: 'BAG');

      final stages = missionUnlockStages(
        before: [base],
        after: [bag, base, hat],
        unlocked: [
          _item('hat_beanie', 'HEAD', level: 6),
          _item('bag_mini_backpack', 'BAG', level: 8),
        ],
      );

      expect(_keysOf(stages), [
        [null],
        [null, 'hat_beanie'],
        // 가방은 층이 개구리보다 뒤라 앞에 끼워 넣지 않고 뒤에 깐다.
        [null, 'bag_mini_backpack', 'hat_beanie'],
      ]);
    });

    test('마지막 칸은 오른 뒤의 차림과 같다', () {
      final provider = CosmeticProvider();
      final after = provider.layersAtLevel(15);

      final stages = missionUnlockStages(
        before: provider.layersAtLevel(14),
        after: after,
        unlocked: missionUnlocksBetween(14, 15, provider.unlockedAt),
      );

      expect(
        _keysOf(stages).last,
        [for (final layer in after) layer.itemKey],
      );
    });

    test('같은 자리에 있던 것은 내린다', () {
      // Lv.14 의 왕관이 Lv.15 의 학사모로 바뀐다. 둘이 같이 걸리면 안 된다.
      final provider = CosmeticProvider();
      final stages = missionUnlockStages(
        before: provider.layersAtLevel(14),
        after: provider.layersAtLevel(15),
        unlocked: missionUnlocksBetween(14, 15, provider.unlockedAt),
      );

      expect(_keysOf(stages).first, contains('hat_crown'));
      for (final keys in _keysOf(stages)) {
        expect(
          keys.contains('hat_crown') && keys.contains('hat_graduate'),
          isFalse,
          reason: '왕관과 학사모가 같이 걸렸다: $keys',
        );
      }
      expect(_keysOf(stages).last, contains('hat_graduate'));
      expect(_keysOf(stages).last, isNot(contains('hat_crown')));
    });

    test('그림이 없는 아이템도 칸은 차지한다', () {
      // 이름표와 칸이 하나씩 짝을 이뤄야 화면이 둘을 같이 넘길 수 있다.
      final base = _layer(null, 300);
      final stages = missionUnlockStages(
        before: [base],
        after: [base],
        unlocked: [
          const CosmeticItemModel(
            itemKey: 'nothing',
            slot: 'HEAD',
            nameKo: '그림 없음',
            imageUrl: '',
            requiredLevel: 6,
            setId: null,
            conflictsWith: [],
            owned: true,
          ),
        ],
      );

      expect(stages, hasLength(2));
      expect(_keysOf(stages), [
        [null],
        [null]
      ]);
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
      expect(missionLevelPhraseOf(2), missionLevelPhrases[2]);
      expect(missionLevelPhraseOf(7), missionLevelPhrases[7]);
      expect(missionLevelPhraseOf(15), '최고 레벨이에요');
    });

    test('문구가 겹치지 않는다', () {
      expect(
        missionLevelPhrases.values.toSet(),
        hasLength(missionLevelPhrases.length),
      );
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

    /// 지금 화면에 그려진 개구리 층의 그림들.
    Set<String> drawnLayers(WidgetTester tester) {
      return tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as AssetImage).assetName)
          .where((name) => name.startsWith('assets/Cosmetic/'))
          .toSet();
    }

    testWidgets('레벨과 문구를 보여 준다', (tester) async {
      await pumpLevelUp(tester, level: 7, previousLevel: 6);

      expect(find.text('Lv.6'), findsOneWidget);
      expect(find.text(missionLevelPhraseOf(7)), findsOneWidget);
      expect(find.text('계속하기'), findsOneWidget);
    });

    testWidgets('열린 치장의 이름을 보여 준다', (tester) async {
      // Lv.14 → Lv.15 는 학사 세트 셋이 한꺼번에 열린다. 가장 화려한 경우다.
      await pumpLevelUp(tester, level: 15, previousLevel: 14);

      expect(find.text('개구리가 바로 입어 봤어요'), findsOneWidget);
      expect(find.text('학사모'), findsOneWidget);
      expect(find.text('학사복'), findsOneWidget);
      expect(find.text('졸업장'), findsOneWidget);
    });

    testWidgets('연출을 끈 기기에서는 다 입은 개구리를 바로 보여 준다', (tester) async {
      await pumpLevelUp(tester, level: 15, previousLevel: 14);

      final drawn = drawnLayers(tester);
      expect(drawn, contains('assets/Cosmetic/hat_graduate.png'));
      expect(drawn, contains('assets/Cosmetic/outfit_graduate.png'));
      expect(drawn, contains('assets/Cosmetic/prop_diploma.png'));
      // 자리를 내준 왕관은 남아 있으면 안 된다.
      expect(drawn, isNot(contains('assets/Cosmetic/hat_crown.png')));
    });

    testWidgets('열린 것이 하나씩 차례로 개구리에 얹힌다', (tester) async {
      await pumpLevelUp(
        tester,
        level: 15,
        previousLevel: 14,
        reduceMotion: false,
        settle: false,
      );

      // 연출은 한순간에 지나가서 마지막 프레임만 보면 다 입은 모습뿐이다.
      // 조금씩 흘려보내며 각 그림이 처음 나온 때를 적어 둔다.
      final firstSeen = <String, int>{};
      for (var elapsed = 0; elapsed <= 2400; elapsed += 60) {
        for (final name in drawnLayers(tester)) {
          firstSeen.putIfAbsent(name, () => elapsed);
        }
        await tester.pump(const Duration(milliseconds: 60));
      }

      // 오르기 전 차림이 먼저 보인다.
      expect(firstSeen['assets/Cosmetic/hat_crown.png'], 0);

      const graduate = 'assets/Cosmetic/hat_graduate.png';
      const outfit = 'assets/Cosmetic/outfit_graduate.png';
      const diploma = 'assets/Cosmetic/prop_diploma.png';
      expect(firstSeen.keys, containsAll([graduate, outfit, diploma]));

      // 셋이 한꺼번에 나타나지 않고 열린 순서대로 하나씩 얹힌다.
      expect(
        firstSeen[graduate]!,
        lessThan(firstSeen[outfit]!),
        reason: '학사모와 학사복이 같이 나타났다',
      );
      expect(
        firstSeen[outfit]!,
        lessThan(firstSeen[diploma]!),
        reason: '학사복과 졸업장이 같이 나타났다',
      );

      await tester.pumpAndSettle();
      final settled = drawnLayers(tester);
      expect(settled, containsAll([graduate, outfit, diploma]));
      expect(settled, isNot(contains('assets/Cosmetic/hat_crown.png')));
    });

    testWidgets('열린 것이 없으면 이름표 대신 레벨 게이지를 둔다', (tester) async {
      final provider = CosmeticProvider();
      // 더미 카탈로그에는 Lv.15 위로 열리는 것이 없다. 게이지 양 끝 글자가
      // 레벨 줄의 글자와 겹치지 않도록 카탈로그 밖 레벨로 올린다.
      expect(missionUnlocksBetween(16, 17, provider.unlockedAt), isEmpty);

      await pumpLevelUp(tester, level: 17, previousLevel: 16);

      expect(find.text('개구리가 바로 입어 봤어요'), findsNothing);
      // 게이지는 Lv.1 에서 카탈로그의 마지막 레벨까지를 눈금으로 쓴다.
      expect(find.text('Lv.1'), findsOneWidget);
      expect(find.text('Lv.${provider.maxLevel}'), findsOneWidget);
    });

    testWidgets('해금된 테마가 있으면 색과 이름을 보여 준다', (tester) async {
      await pumpLevelUp(tester, level: 6, previousLevel: 5, unlocked: [8]);

      expect(find.text('새 테마가 열렸어요'), findsOneWidget);
      expect(find.text('라이트그린'), findsOneWidget);
      expect(find.text('바로 적용해보기'), findsOneWidget);
    });

    for (final size in [OnoSurface.smallPhone, OnoSurface.tablet]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          '${size.width.toInt()}dp 글자 ${scale}배에서 넘치지 않는다',
          (tester) async {
            disableAnimationsForTest(tester);
            await pumpOnoWidget(
              tester,
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: Builder(
                    builder: (inner) => Scaffold(
                      body: Center(
                        child: TextButton(
                          onPressed: () => showMissionLevelUp(
                            inner,
                            // 치장 셋과 테마 둘이 한꺼번에 열리는, 가장 긴 경우다.
                            level: 15,
                            previousLevel: 14,
                            unlockedThemeIndexes: const [8, 9],
                          ),
                          child: const Text('열기'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              surfaceSize: size,
            );
            await tester.tap(find.text('열기'));
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason: '${size.width.toInt()}dp × $scale 에서 넘쳤다',
            );
            expect(find.text('계속하기'), findsOneWidget);
            expect(find.text('개구리가 바로 입어 봤어요'), findsOneWidget);
            expect(find.text('새 테마가 열렸어요'), findsOneWidget);
          },
        );
      }
    }

    testWidgets('해금된 테마가 없으면 그 자리는 통째로 없다', (tester) async {
      await pumpLevelUp(tester, level: 6, previousLevel: 5);

      expect(find.text('새 테마가 열렸어요'), findsNothing);
      expect(find.text('바로 적용해보기'), findsNothing);
    });
  });
}
