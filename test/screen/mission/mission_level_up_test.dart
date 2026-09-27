// 해금 연출 테스트.
//
// 개구리 그림은 더 이상 레벨에 따라 바뀌지 않는다. 그래서 성장은 이번에 열린
// 치장을 개구리에 직접 입혀서만 보인다. 여기서 잠그는 것은 세 가지다.
// 서버가 준 해금을 앱이 그릴 수 있는 모습으로 맞추는 계산, 그것이 개구리에
// 실제로 얹히는지, 그리고 레벨이 오르지 않은 해금도 알리는지다 (#257).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticItemModel.dart';
import 'package:ono/Model/Cosmetic/CosmeticLoadoutModel.dart';
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Screen/Mission/MissionLevelUp.dart';

import '../../helpers/helpers.dart';

/// 서버가 내려준 해금 한 건.
CosmeticUnlockModel _unlock(
  String itemKey,
  String slot, {
  String? nameKo,
  String imageUrl = '',
}) {
  return CosmeticUnlockModel(
    itemKey: itemKey,
    slot: slot,
    nameKo: nameKo ?? itemKey,
    imageUrl: imageUrl.isEmpty ? 'assets/Cosmetic/$itemKey.png' : imageUrl,
  );
}

/// 카탈로그 아이템 한 건. 서버가 옷장으로 내려주는 모양이다.
CosmeticItemModel _item(
  String itemKey,
  String slot, {
  String? nameKo,
  String imageUrl = '',
  int level = 1,
}) {
  return CosmeticItemModel(
    itemKey: itemKey,
    slot: slot,
    nameKo: nameKo ?? itemKey,
    imageUrl: imageUrl.isEmpty ? 'assets/Cosmetic/$itemKey.png' : imageUrl,
    requiredLevel: level,
    setId: null,
    conflictsWith: const [],
    owned: true,
  );
}

/// 카탈로그 아이템을 서버가 내려준 해금 모양으로 옮긴다.
CosmeticUnlockModel _unlockOf(CosmeticItemModel item) => CosmeticUnlockModel(
      itemKey: item.itemKey,
      slot: item.slot,
      nameKo: item.nameKo,
      imageUrl: item.imageUrl,
    );

/// 그 총 학습 레벨에서 열리는 것들을 서버가 실어 준 셈 친다.
List<CosmeticUnlockModel> _unlocksAt(CosmeticProvider provider, int level) => [
      for (final item in provider.unlockedAtTotalStudyLevel(level))
        _unlockOf(item),
    ];

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

/// 총 학습 Lv.20 에서 한꺼번에 열리는 학사 세트. 가장 화려한 경우다.
const _graduateSet = ['hat_graduate', 'outfit_graduate', 'prop_diploma'];

void main() {
  setUpOnoWidgetTest();

  // 해금을 정하는 쪽은 서버다. 앱이 총 학습 레벨로 세면 능력치 기준으로 열린
  // 것이 빠지고, 레벨이 오르지 않은 해금은 아예 세어지지 않았다 (#257).
  group('서버가 준 해금 맞추기', () {
    final catalog = <String, CosmeticItemModel>{
      'bg_spring': _item('bg_spring', 'BACKGROUND', nameKo: '봄 들판'),
      'glasses_round': _item('glasses_round', 'FACE', nameKo: '동그란 안경'),
    };
    CosmeticItemModel? itemOf(String itemKey) => catalog[itemKey];

    test('카탈로그에 있으면 카탈로그의 이름과 그림으로 바꿔 놓는다', () {
      final unlocks = missionDrawableUnlocks(
        // 서버 값이 비어 있어도 카탈로그가 채워 준다.
        unlocks: [_unlock('bg_spring', '', nameKo: 'bg_spring', imageUrl: ' ')],
        hasCatalog: true,
        itemOf: itemOf,
      );

      expect(unlocks, hasLength(1));
      expect(unlocks.single.nameKo, '봄 들판');
      expect(unlocks.single.slot, 'BACKGROUND');
      expect(unlocks.single.imageUrl, 'assets/Cosmetic/bg_spring.png');
    });

    test('카탈로그에 없으면 그림만 비우고 이름은 남긴다', () {
      // 이 앱 버전에 그림이 없는 아이템이다. 개구리는 그대로 두고 이름만 알린다.
      final unlocks = missionDrawableUnlocks(
        unlocks: [_unlock('hat_alien', 'HEAD', nameKo: '외계 모자')],
        hasCatalog: true,
        itemOf: itemOf,
      );

      expect(unlocks, hasLength(1));
      expect(unlocks.single.nameKo, '외계 모자');
      expect(unlocks.single.imageUrl, isEmpty);
    });

    test('카탈로그를 아직 못 받았으면 서버 값을 그대로 믿는다', () {
      final unlocks = missionDrawableUnlocks(
        unlocks: [_unlock('hat_alien', 'HEAD', nameKo: '외계 모자')],
        hasCatalog: false,
        itemOf: (_) => null,
      );

      expect(unlocks.single.imageUrl, 'assets/Cosmetic/hat_alien.png');
    });

    test('서버가 준 순서를 지키고, 빈 목록은 빈 목록이다', () {
      final unlocks = missionDrawableUnlocks(
        unlocks: [
          _unlock('glasses_round', 'FACE'),
          _unlock('bg_spring', 'BACKGROUND'),
        ],
        hasCatalog: true,
        itemOf: itemOf,
      );

      expect(
        unlocks.map((unlock) => unlock.itemKey),
        ['glasses_round', 'bg_spring'],
      );
      expect(
        missionDrawableUnlocks(
          unlocks: const [],
          hasCatalog: true,
          itemOf: itemOf,
        ),
        isEmpty,
      );
    });

    test('서버 응답에서 읽어 낸 해금이 그대로 연출로 간다', () {
      // MissionClaimResultModel 이 버리던 값이다.
      final unlocks = CosmeticUnlockModel.listFrom([
        {
          'itemKey': 'glasses_round',
          'nameKo': '동그란 안경',
          'slot': 'FACE',
          'imageUrl': 'assets/Cosmetic/glasses_round.png',
        },
      ]);

      expect(
        missionDrawableUnlocks(
          unlocks: unlocks,
          hasCatalog: true,
          itemOf: itemOf,
        ).single.nameKo,
        '동그란 안경',
      );
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
          _unlock('hat_beanie', 'HEAD'),
          _unlock('bag_mini_backpack', 'BAG'),
        ],
      );

      expect(_keysOf(stages), [
        [null],
        [null, 'hat_beanie'],
        // 가방은 층이 개구리보다 뒤라 앞에 끼워 넣지 않고 뒤에 깐다.
        [null, 'bag_mini_backpack', 'hat_beanie'],
      ]);
    });

    test('마지막 칸은 오른 뒤의 차림과 같다', () async {
      final provider =
          await loadedCosmeticProvider(levels: CosmeticAbilityLevels.max);
      final after = provider.layersAtLevel(20);

      final stages = missionUnlockStages(
        before: provider.layersAtLevel(19),
        after: after,
        unlocked: _unlocksAt(provider, 20),
      );

      expect(
        _keysOf(stages).last,
        [for (final layer in after) layer.itemKey],
      );
    });

    test('같은 자리에 있던 것은 내린다', () async {
      // 총 학습 Lv.19 의 왕관이 Lv.20 의 학사모로 바뀐다. 둘이 같이 걸리면 안 된다.
      final provider =
          await loadedCosmeticProvider(levels: CosmeticAbilityLevels.max);
      final stages = missionUnlockStages(
        before: provider.layersAtLevel(19),
        after: provider.layersAtLevel(20),
        unlocked: _unlocksAt(provider, 20),
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
        unlocked: const [
          CosmeticUnlockModel(
            itemKey: 'nothing',
            slot: 'HEAD',
            nameKo: '그림 없음',
            imageUrl: '',
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
      expect(missionLevelPhraseOf(20), '최고 레벨이에요');
    });

    test('문구가 겹치지 않는다', () {
      expect(
        missionLevelPhrases.values.toSet(),
        hasLength(missionLevelPhrases.length),
      );
    });

    test('표를 벗어나면 양 끝 문구로 떨어진다', () {
      expect(missionLevelPhraseOf(1), missionLevelPhraseOf(2));
      expect(missionLevelPhraseOf(99), missionLevelPhraseOf(20));
    });
  });

  group('화면', () {
    Future<void> pumpLevelUp(
      WidgetTester tester, {
      required int level,
      int? previousLevel,
      List<int> unlocked = const [],
      // 서버가 이번에 열렸다고 알려 준 것들. 키를 주면 카탈로그에서 찾아 넘긴다.
      List<String> unlockedCosmetics = const [],
      bool reduceMotion = true,
      bool settle = true,
      Map<String, String> wearing = const {},
    }) async {
      if (reduceMotion) disableAnimationsForTest(tester);
      // 연출은 오르기 전 차림에서 시작한다. 그래서 프로바이더도 오르기 전
      // 레벨로 세운다. [wearing] 으로 그 위에 따로 걸칠 수 있다.
      final cosmetic = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.uniform(previousLevel ?? level),
      );
      for (final entry in wearing.entries) {
        await cosmetic.equip(entry.key, entry.value);
      }
      final serverUnlocks = [
        for (final key in unlockedCosmetics) _unlockOf(cosmetic.itemOf(key)!),
      ];
      await pumpOnoWidget(
        tester,
        cosmeticProvider: cosmetic,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showMissionLevelUp(
                  context,
                  level: level,
                  previousLevel: previousLevel,
                  unlockedThemeIndexes: unlocked,
                  unlockedCosmetics: serverUnlocks,
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
      // 총 학습 Lv.19 → Lv.20 은 학사 세트 셋이 한꺼번에 열린다. 가장 화려한 경우다.
      await pumpLevelUp(
        tester,
        level: 20,
        previousLevel: 19,
        unlockedCosmetics: _graduateSet,
      );

      expect(find.text('학사모'), findsOneWidget);
      expect(find.text('학사복'), findsOneWidget);
      expect(find.text('졸업장'), findsOneWidget);
    });

    testWidgets('연출을 끈 기기에서는 다 입은 개구리를 바로 보여 준다', (tester) async {
      await pumpLevelUp(
        tester,
        level: 20,
        previousLevel: 19,
        unlockedCosmetics: _graduateSet,
      );

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
        level: 20,
        previousLevel: 19,
        unlockedCosmetics: _graduateSet,
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
      final provider =
          await loadedCosmeticProvider(levels: CosmeticAbilityLevels.max);
      // 게이지 양 끝 글자가 레벨 줄의 글자와 겹치지 않도록 카탈로그 밖 레벨로
      // 올린다. 서버가 해금을 하나도 주지 않은 레벨업이다.
      await pumpLevelUp(tester, level: 22, previousLevel: 21);

      // 열린 것이 없으면 이름표도 없다. 카탈로그 밖 레벨이라 아무것도 안 열린다.
      expect(find.text('학사모'), findsNothing);
      // 게이지는 Lv.1 에서 카탈로그의 마지막 레벨까지를 눈금으로 쓴다.
      expect(find.text('Lv.1'), findsOneWidget);
      expect(find.text('Lv.${provider.maxTotalStudyLevel}'), findsOneWidget);
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
                            level: 20,
                            previousLevel: 19,
                            unlockedThemeIndexes: const [8, 9],
                            unlockedCosmetics: [
                              _unlock('hat_graduate', 'HEAD', nameKo: '학사모'),
                              _unlock('outfit_graduate', 'BODY', nameKo: '학사복'),
                              _unlock('prop_diploma', 'PROP', nameKo: '졸업장'),
                            ],
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
            expect(find.text('학사모'), findsOneWidget);
            expect(find.text('새 테마가 열렸어요'), findsOneWidget);
          },
        );
      }
    }

    // 해금이 능력치별로 갈려 있어서 총 학습 레벨이 그대로인 채 열리는 것이
    // 있다. 예전에는 레벨업이 없으면 창 자체가 뜨지 않아 아무 안내도 없었다 (#257).
    testWidgets('레벨이 오르지 않아도 열린 꾸미기를 알린다', (tester) async {
      await pumpLevelUp(
        tester,
        level: 19,
        previousLevel: 19,
        unlockedCosmetics: const ['hat_crown'],
      );

      expect(find.text('새 꾸미기가 열렸어요'), findsOneWidget);
      expect(find.text('왕관'), findsOneWidget);
      // 오르지 않은 레벨을 오른 것처럼 말하지 않는다.
      expect(find.text('Lv.19'), findsNothing);
      expect(find.text(missionLevelPhraseOf(19)), findsNothing);
      expect(find.text('계속하기'), findsOneWidget);
    });

    testWidgets('레벨이 올랐으면 해금 제목 대신 레벨 줄을 둔다', (tester) async {
      await pumpLevelUp(
        tester,
        level: 20,
        previousLevel: 19,
        unlockedCosmetics: _graduateSet,
      );

      expect(find.text('새 꾸미기가 열렸어요'), findsNothing);
      expect(find.text('Lv.19'), findsOneWidget);
    });

    testWidgets('해금된 테마가 없으면 그 자리는 통째로 없다', (tester) async {
      await pumpLevelUp(tester, level: 6, previousLevel: 5);

      expect(find.text('새 테마가 열렸어요'), findsNothing);
      expect(find.text('바로 적용해보기'), findsNothing);
    });
  });
}
