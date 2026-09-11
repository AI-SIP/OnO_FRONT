// 개구리 렌더링 테스트.
//
// 개구리는 레벨마다 그림이 통째로 바뀌던 방식에서, 고정 포즈 한 장(BASE) 위에
// 치장 파츠를 겹치는 방식으로 바뀌었다. 겹치는 순서가 틀리면 모자가 머리 뒤로
// 가거나 배경이 개구리를 덮는다. 순서를 여기서 잠근다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticLoadoutModel.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Screen/Cosmetic/Mock/CosmeticMockData.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';

import '../../helpers/helpers.dart';

/// FrogCharacter 안에 있는 격려 메시지 목록을 그대로 옮겨 둔 것.
/// lib 코드를 참조(reflection)하는 대신, 탭 후 화면에 뜬 문구가 그 중
/// 하나인지만 확인하는 용도다.
const _encouragementMessages = [
  '오늘도 화이팅!',
  '잘하고 있어요!',
  '꾸준히 성장 중이에요!',
  '대단해요!',
  '멋져요!',
  '계속 이렇게!',
  '최고예요!',
  '실수는 성공의 밑거름!',
  '지금 정말 잘하고 있어요!',
  '어제보다 더 성장했네요!',
  '개굴! 만점까지 달려볼까요?',
  '집중하는 모습에 반해버렸어요!',
  '내가 지켜보고 있어요, 화이팅!',
  '고생 많았어요. 개굴!',
  '할 수 있다! 할 수 있다!',
  '내가 항상 응원하고 있어요.',
];

void main() {
  setUpOnoWidgetTest();

  Finder speechBubbleFinder() => find.byWidgetPredicate(
        (widget) =>
            widget is StandardText &&
            _encouragementMessages.contains(widget.text),
      );

  /// 화면에 그려진 에셋 경로를 위에서 아래(뒤에서 앞) 순서로 모은다.
  List<String> drawnAssets(WidgetTester tester) => [
        for (final image in tester.widgetList<Image>(find.byType(Image)))
          if (image.image case final AssetImage asset) asset.assetName,
      ];

  Future<void> pumpFrog(
    WidgetTester tester, {
    List<CosmeticLayerModel> layers = const [],
    VoidCallback? onTap,
    double size = 180,
    bool showEncouragement = true,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Scaffold(
          body: FrogCharacter(
            layers: layers,
            onTap: onTap,
            size: size,
            showEncouragement: showEncouragement,
          ),
        ),
        surfaceSize: surfaceSize,
        settle: false,
      );
      await tester.pump();
    });
  }

  group('전신 의상', () {
    // 소매와 바짓단이 그려진 옷은 뒤에 전신 개구리를 두면 원래 팔다리가
    // 옷 밖으로 삐져나온다. 그럴 때는 본체를 머리만 있는 그림으로 바꾼다.
    test('입으면 본체가 머리만 있는 그림으로 바뀐다', () {
      final layers = CosmeticMockData.loadout.resolveLayers(
        equippedOverride: const {'OUTFIT': 'outfit_cardigan'},
      );

      expect(
        layers.first.imageUrl,
        CosmeticLoadoutModel.defaultBaseHeadImageUrl,
      );
    });

    test('옷이 아닌 것만 걸치면 본체를 그대로 쓴다', () {
      final layers = CosmeticMockData.loadout.resolveLayers(
        equippedOverride: const {'HEAD': 'hat_crown', 'NECK': 'scarf'},
      );

      expect(layers.first.imageUrl, CosmeticLoadoutModel.defaultBaseImageUrl);
    });

    test('아무것도 안 입으면 본체를 그대로 쓴다', () {
      final layers = CosmeticMockData.loadout.resolveLayers(
        equippedOverride: const {},
      );

      expect(layers.first.imageUrl, CosmeticLoadoutModel.defaultBaseImageUrl);
    });

    test('전신 의상에 모자를 같이 써도 본체만 바뀐다', () {
      final layers = CosmeticMockData.loadout.resolveLayers(
        equippedOverride: const {
          'OUTFIT': 'outfit_hoodie',
          'HEAD': 'hat_beanie',
        },
      );

      expect(
        layers.first.imageUrl,
        CosmeticLoadoutModel.defaultBaseHeadImageUrl,
      );
      expect(
        [for (final layer in layers) layer.itemKey],
        [null, 'outfit_hoodie', 'hat_beanie'],
      );
    });
  });

  group('레이어 겹치는 순서', () {
    test('layerOrder 오름차순으로 뒤에서 앞 순서로 나온다', () {
      final layers = CosmeticMockData.loadout.resolveLayers(
        equippedOverride: const {
          'HEAD': 'hat_graduate',
          'BACKGROUND': 'bg_night',
          'OUTFIT': 'outfit_graduate',
          'BAG': 'bag_mini_backpack',
        },
      );

      expect(
        [for (final layer in layers) layer.layerOrder],
        [100, 300, 400, 450, 700],
      );
      expect(
        [for (final layer in layers) layer.itemKey],
        [
          'bg_night',
          null, // 개구리 본체
          'outfit_graduate',
          'bag_mini_backpack', // 앞으로 메는 그림이라 옷 위에 온다
          'hat_graduate',
        ],
      );
    });

    test('개구리 본체는 배경·가방 뒤가 아니라 그 앞에 선다', () {
      final layers = CosmeticMockData.loadout.resolveLayers(
        equippedOverride: const {'BACKGROUND': 'bg_spring'},
      );

      final baseIndex = layers.indexWhere((layer) => layer.isBase);
      final bgIndex =
          layers.indexWhere((layer) => layer.itemKey == 'bg_spring');

      expect(bgIndex, lessThan(baseIndex));
    });

    test('아무것도 안 걸치면 개구리 본체 한 장뿐이다', () {
      final layers = CosmeticMockData.loadout.resolveLayers(
        equippedOverride: const {},
      );

      expect(layers, hasLength(1));
      expect(layers.single.imageUrl, 'assets/Cosmetic/BASE.png');
    });

    test('프로바이더가 준 층도 같은 순서다', () {
      final provider = CosmeticProvider(mockLevels: CosmeticAbilityLevels.max);
      // 다 열린 사람은 자리마다 하나씩 입고 있다. 순서만 보려는 것이라
      // 전부 벗기고 양 끝 둘만 직접 걸친다.
      provider.unequipAll();
      provider.equip('BACKGROUND', 'bg_night');
      provider.equip('HAND', 'prop_diploma');

      expect(
        [for (final layer in provider.layers) layer.layerOrder],
        [for (final layer in provider.layers) layer.layerOrder]..sort(),
      );
      expect(provider.layers.first.itemKey, 'bg_night');
      expect(provider.layers.last.itemKey, 'prop_diploma');
    });
  });

  testWidgets('층을 준 순서 그대로 겹쳐 그린다', (tester) async {
    final layers = CosmeticMockData.loadout.resolveLayers(
      equippedOverride: const {
        'BACKGROUND': 'bg_night',
        'HEAD': 'hat_graduate',
      },
    );

    await pumpFrog(tester, layers: layers);

    expect(drawnAssets(tester), [
      'assets/Cosmetic/bg_night.png',
      'assets/Cosmetic/BASE.png',
      'assets/Cosmetic/hat_graduate.png',
    ]);
  });

  testWidgets('층을 안 주면 개구리 본체 한 장만 그린다', (tester) async {
    await pumpFrog(tester);

    expect(find.byType(Image), findsOneWidget);
    expect(drawnAssets(tester), ['assets/Cosmetic/BASE.png']);
    expect(speechBubbleFinder(), findsNothing);
  });

  testWidgets('없는 그림이 섞여 있어도 나머지는 그려진다', (tester) async {
    await pumpFrog(
      tester,
      layers: const [
        CosmeticLayerModel(
          imageUrl: 'assets/Cosmetic/BASE.png',
          layerOrder: 300,
        ),
        CosmeticLayerModel(
          imageUrl: 'assets/Cosmetic/없는파일.png',
          layerOrder: 700,
          slot: 'HEAD',
          itemKey: 'missing',
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(drawnAssets(tester), contains('assets/Cosmetic/BASE.png'));
  });

  testWidgets('배경을 깐 개구리는 모서리가 잘려 카드처럼 보인다', (tester) async {
    await pumpFrog(tester, layers: CosmeticMockData.graduateLayers);

    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets('탭하면 onTap 콜백이 호출된다', (tester) async {
    var tapCount = 0;
    await pumpFrog(tester, onTap: () => tapCount++);

    await tester.tap(find.byType(FrogCharacter));
    await tester.pump(const Duration(milliseconds: 50));

    expect(tapCount, 1);

    // 탭으로 예약된 2초짜리 메시지 숨김 타이머를 다 흘려보내야
    // 테스트 종료 시 "pending timer" 오류가 나지 않는다.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('탭하면 격려 메시지가 잠깐 보인다', (tester) async {
    await pumpFrog(tester);

    await tester.tap(find.byType(FrogCharacter));
    // 확대/축소 애니메이션(300ms)이 끝날 때까지 진행시킨다.
    await tester.pump(const Duration(milliseconds: 350));

    expect(speechBubbleFinder(), findsOneWidget);

    // 메시지 숨김 타이머(2초)를 마저 흘려보낸다.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('2초 뒤에는 격려 메시지가 사라진다', (tester) async {
    await pumpFrog(tester);

    await tester.tap(find.byType(FrogCharacter));
    await tester.pump(const Duration(milliseconds: 350));
    expect(speechBubbleFinder(), findsOneWidget);

    await tester.pump(const Duration(seconds: 2, milliseconds: 100));

    expect(speechBubbleFinder(), findsNothing);
  });

  testWidgets('onTap 이 없어도 탭하면 예외 없이 메시지만 뜬다', (tester) async {
    await pumpFrog(tester, onTap: null);

    await tester.tap(find.byType(FrogCharacter));
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.takeException(), isNull);
    expect(speechBubbleFinder(), findsOneWidget);

    // 메시지 숨김 타이머(2초)를 마저 흘려보낸다.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('말풍선을 끄면 탭해도 메시지가 안 뜬다', (tester) async {
    await pumpFrog(tester, showEncouragement: false);

    await tester.tap(find.byType(FrogCharacter));
    await tester.pump(const Duration(milliseconds: 350));

    expect(speechBubbleFinder(), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpFrog(
      tester,
      layers: CosmeticMockData.graduateLayers,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
