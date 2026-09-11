// 옷장 프로바이더 테스트.
//
// 지금은 서버를 타지 않는 더미다. 레벨을 옮기면 해금이 어떻게 쌓이는지,
// 직접 갈아입은 뒤 레벨이 내려가면 못 쓰게 된 것이 벗겨지는지를 잠근다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Screen/Cosmetic/Mock/CosmeticMockData.dart';

void main() {
  group('첫 차림', () {
    // 옷장을 한 번도 안 연 사람에게 입혀 주는 한 벌이다. 자리마다 가장 늦게
    // 열린 것을 고른다. 레벨이 높은 사람이 맨 개구리로 보이지 않게 하려는 것이다.
    test('자리마다 가장 늦게 열린 것을 입는다', () {
      final provider = CosmeticProvider(mockLevel: 15);

      expect(provider.equipped, {
        'BACKGROUND': 'bg_night', // Lv.13
        'BAG': 'bag_mini_backpack', // Lv.8
        'OUTFIT': 'outfit_graduate', // Lv.15
        'NECK': 'scarf', // Lv.5
        'FACE': 'glasses_sun', // Lv.11
        'HEAD': 'hat_graduate', // Lv.15
        'HAND': 'prop_diploma', // Lv.15
        // BADGE 는 레벨로 열리는 것이 없어서 빈다.
      });
    });

    test('Lv.1 은 아직 열린 것이 없어서 개구리 한 장뿐이다', () {
      final provider = CosmeticProvider(mockLevel: 1);

      expect(provider.equipped, isEmpty);
      expect(provider.layers, hasLength(1));
      expect(provider.layers.single.isBase, isTrue);
    });

    test('레벨 범위를 벗어나면 1 과 최대 사이로 잘린다', () {
      expect(CosmeticProvider(mockLevel: 0).level, 1);
      expect(CosmeticProvider(mockLevel: 99).level, CosmeticMockData.maxLevel);
    });
  });

  group('setMockLevel', () {
    test('아직 안 갈아입었으면 그 레벨의 첫 차림으로 다시 맞춘다', () {
      final provider = CosmeticProvider(mockLevel: 15);

      provider.setMockLevel(6);

      expect(provider.equipped, {
        'BACKGROUND': 'bg_spring', // Lv.3
        'NECK': 'scarf', // Lv.5
        'FACE': 'glasses_round', // Lv.4
        'HEAD': 'hat_beanie', // Lv.6
      });
    });

    test('한 번 갈아입은 뒤에는 고른 것을 덮지 않는다', () {
      final provider = CosmeticProvider(mockLevel: 15);
      provider.equip('HEAD', 'headband_sprout');

      provider.setMockLevel(14);

      expect(provider.equippedItemKeyOf('HEAD'), 'headband_sprout');
    });

    test('레벨이 내려가 못 쓰게 된 것은 내린다', () {
      final provider = CosmeticProvider(mockLevel: 15);
      provider.equip('HEAD', 'hat_crown'); // Lv.14

      provider.setMockLevel(3);

      expect(provider.equippedItemKeyOf('HEAD'), isNull);
    });

    test('알림이 한 번 간다', () {
      final provider = CosmeticProvider(mockLevel: 15);
      var notified = 0;
      provider.addListener(() => notified++);

      provider.setMockLevel(10);
      expect(notified, 1);

      // 같은 레벨이면 아무 일도 없다.
      provider.setMockLevel(10);
      expect(notified, 1);
    });
  });

  group('시착', () {
    // 꾸미기 화면은 저장을 눌러야 반영된다. 그동안 프로바이더가 들고 있는
    // 차림이 바뀌면 하단 탭 아이콘과 프로필 사진까지 따라 바뀌어 버린다.
    test('previewEquip 은 넘긴 차림만 바꾸고 프로바이더는 건드리지 않는다', () {
      final provider = CosmeticProvider(mockLevel: 15);
      final before = Map<String, String>.from(provider.equipped);

      final next = provider.previewEquip(
        provider.equipped,
        slot: 'HEAD',
        itemKey: 'hat_beanie',
      );

      expect(next['HEAD'], 'hat_beanie');
      expect(provider.equipped, before);
    });

    test('previewEquip 도 같이 걸 수 없는 것은 함께 내린다', () {
      final provider = CosmeticProvider(mockLevel: 15);

      final next = provider.previewEquip(
        provider.equipped,
        slot: 'HEAD',
        itemKey: 'hat_beanie',
      );

      // 실제로 거는 equip 과 같은 규칙을 써야 화면과 프로바이더가 다른 말을
      // 하지 않는다.
      provider.equip('HEAD', 'hat_beanie');
      expect(next, provider.equipped);
    });

    test('layersOf 는 넘긴 차림을 그린다', () {
      final provider = CosmeticProvider(mockLevel: 15);

      expect(provider.layersOf(const {}), hasLength(1));
      expect(provider.layersOf(const {}).single.isBase, isTrue);
      // 프로바이더가 입고 있는 것은 그대로다.
      expect(provider.layers.length, greaterThan(1));
    });

    test('usableOf 는 지금 레벨에서 못 쓰는 것을 걷어 낸다', () {
      final provider = CosmeticProvider(mockLevel: 3);

      final fitting = {'HEAD': 'hat_crown', 'BACKGROUND': 'bg_spring'};

      expect(provider.usableOf(fitting), {'BACKGROUND': 'bg_spring'});
    });

    test('lockReasonOf 는 못 쓰는 이유를 알려 주고 쓸 수 있으면 null 이다', () {
      final provider = CosmeticProvider(mockLevel: 3);

      expect(provider.lockReasonOf('hat_crown'), 'Lv.14 부터 쓸 수 있어요.');
      expect(provider.lockReasonOf('hat_beret'), '미션을 마치면 받을 수 있어요.');
      expect(provider.lockReasonOf('bg_spring'), isNull);
      expect(provider.lockReasonOf('없는_아이템'), '지금은 쓸 수 없는 아이템이에요.');
    });

    test('save 는 시착한 차림을 확정하면서 못 쓰는 것은 걷어 낸다', () {
      final provider = CosmeticProvider(mockLevel: 3);

      provider.save({'HEAD': 'hat_crown', 'BACKGROUND': 'bg_spring'});

      expect(provider.equipped, {'BACKGROUND': 'bg_spring'});
    });

    test('save 로 전부 벗길 수도 있다', () {
      final provider = CosmeticProvider(mockLevel: 15);
      expect(provider.equipped, isNotEmpty);

      provider.save(const {});

      expect(provider.equipped, isEmpty);
    });
  });

  group('장착', () {
    test('열린 아이템은 걸린다', () {
      final provider = CosmeticProvider(mockLevel: 15);

      provider.equip('HEAD', 'hat_beanie');

      expect(provider.equippedItemKeyOf('HEAD'), 'hat_beanie');
      expect(provider.lastFailureMessage, isNull);
    });

    test('아직 안 열린 것은 걸리지 않고 몇 레벨부터인지 알려 준다', () {
      final provider = CosmeticProvider(mockLevel: 3);

      provider.equip('HEAD', 'hat_crown'); // Lv.14

      expect(provider.equippedItemKeyOf('HEAD'), isNot('hat_crown'));
      expect(provider.consumeFailure(), 'Lv.14 부터 쓸 수 있어요.');
      // 한 번 꺼내 쓰면 비워져서 같은 말이 두 번 뜨지 않는다.
      expect(provider.lastFailureMessage, isNull);
    });

    test('미션 보상은 레벨을 올려도 안 열린다', () {
      final provider = CosmeticProvider(mockLevel: 15);

      provider.equip('HEAD', 'hat_beret');

      expect(provider.isOwned('hat_beret'), isFalse);
      expect(provider.consumeFailure(), '미션을 마치면 받을 수 있어요.');
    });

    test('슬롯이 다르면 걸리지 않는다', () {
      final provider = CosmeticProvider(mockLevel: 15);

      provider.equip('FACE', 'hat_beanie');

      expect(provider.equippedItemKeyOf('FACE'), isNot('hat_beanie'));
      expect(provider.consumeFailure(), '지금은 쓸 수 없는 아이템이에요.');
    });

    test('unequip 은 그 자리만 비운다', () {
      final provider = CosmeticProvider(mockLevel: 15);

      provider.unequip('HEAD');

      expect(provider.equippedItemKeyOf('HEAD'), isNull);
      expect(provider.equippedItemKeyOf('OUTFIT'), 'outfit_graduate');
    });

    test('equipSet 은 세트를 통째로 건다', () {
      final provider = CosmeticProvider(mockLevel: 15);

      provider.equipSet('graduate');

      expect(provider.equippedItemKeyOf('HEAD'), 'hat_graduate');
      expect(provider.equippedItemKeyOf('OUTFIT'), 'outfit_graduate');
      expect(provider.equippedItemKeyOf('HAND'), 'prop_diploma');
    });

    test('세트에 못 가진 것이 있으면 하나도 걸지 않는다', () {
      final provider = CosmeticProvider(mockLevel: 10);

      provider.equipSet('graduate');

      expect(provider.equippedItemKeyOf('HEAD'), isNot('hat_graduate'));
      expect(provider.consumeFailure(), 'Lv.15 부터 쓸 수 있어요.');
    });

    test('unequipAll 은 걸친 것을 전부 벗긴다', () {
      final provider = CosmeticProvider(mockLevel: 15);
      provider.equipSet('graduate');
      provider.equip('NECK', 'scarf');

      provider.unequipAll();

      expect(provider.equipped, isEmpty);
    });
  });

  group('레벨업 연출에 넘길 것', () {
    test('layersAtLevel 은 지금 차림과 무관하게 그 레벨의 기본 차림이다', () {
      final provider = CosmeticProvider(mockLevel: 15);
      provider.unequip('HEAD');

      final before = provider.layersAtLevel(14);
      final after = provider.layersAtLevel(15);

      expect(
        [for (final layer in after) layer.itemKey],
        contains('hat_graduate'),
      );
      expect(
        [for (final layer in before) layer.itemKey],
        contains('hat_crown'),
      );
      // 지금 차림은 건드리지 않는다.
      expect(provider.equippedItemKeyOf('HEAD'), isNull);
    });

    test('unlockedAt 은 그 레벨에서 새로 열리는 것만 준다', () {
      final provider = CosmeticProvider(mockLevel: 15);

      expect(
        [for (final item in provider.unlockedAt(15)) item.itemKey],
        ['hat_graduate', 'outfit_graduate', 'prop_diploma'],
      );
      expect(provider.unlockedAt(1), isEmpty);
    });
  });

  group('더미 카탈로그', () {
    test('에셋 경로가 모두 assets/Cosmetic 아래를 가리킨다', () {
      for (final item in CosmeticMockData.loadout.items) {
        expect(item.imageUrl, 'assets/Cosmetic/${item.itemKey}.png');
      }
    });

    test('모든 아이템이 카탈로그에 있는 슬롯에 속한다', () {
      final slotKeys = {
        for (final slot in CosmeticMockData.loadout.slots) slot.slot,
      };

      for (final item in CosmeticMockData.loadout.items) {
        expect(slotKeys, contains(item.slot), reason: item.itemKey);
      }
    });

    test('레벨로 열리는 것과 미션 보상이 섞여 있다', () {
      final items = CosmeticMockData.loadout.items;

      expect(items.where((item) => item.unlocksByLevel), hasLength(16));
      expect(items.where((item) => !item.unlocksByLevel), hasLength(39));
    });
  });
}
