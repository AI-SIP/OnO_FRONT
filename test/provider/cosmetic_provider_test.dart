// 옷장 프로바이더 테스트.
//
// 지금은 서버를 타지 않는 더미다. 해금 기준이 총 학습 레벨 하나에서
// **능력치별**로 바뀌었다. 출석만 올린 사람에게 배경이 열리고 복습만 한
// 사람에게 안경이 열리는지, 다른 능력치를 아무리 올려도 남의 것은 안 열리는지,
// 직접 갈아입은 뒤 레벨이 내려가면 못 쓰게 된 것이 벗겨지는지를 잠근다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Screen/Cosmetic/Mock/CosmeticMockData.dart';

void main() {
  /// 다섯을 다 끝까지 올린 사람.
  CosmeticProvider maxed() =>
      CosmeticProvider(mockLevels: CosmeticAbilityLevels.max);

  /// 다섯을 같은 값으로 놓은 사람. 한 축으로 훑어 볼 때 쓴다.
  CosmeticProvider uniform(int level) =>
      CosmeticProvider(mockLevels: CosmeticAbilityLevels.uniform(level));

  group('첫 차림', () {
    // 옷장을 한 번도 안 연 사람에게 입혀 주는 한 벌이다. 자리마다 가장 늦게
    // 열린 것을 고른다. 레벨이 높은 사람이 맨 개구리로 보이지 않게 하려는 것이다.
    test('자리마다 가장 늦게 열린 것을 입는다', () {
      final provider = maxed();

      expect(provider.equipped, {
        'BACKGROUND': 'bg_space', // 출석 Lv.15
        'BACK': 'back_backpack_canvas', // 오답노트 Lv.9
        'OUTFIT': 'outfit_graduate', // 총 학습 Lv.20
        'BAG': 'bag_crossbody_satchel', // 오답노트 Lv.11
        'NECK': 'neck_medal', // 복습 세트 Lv.12
        'FACE': 'face_moustache', // 문제 복습 Lv.14
        'HEAD': 'hat_graduate', // 총 학습 Lv.20
        'HAND': 'prop_diploma', // 총 학습 Lv.20
        'BADGE': 'badge_snowflake', // 총 학습 Lv.18
        'EFFECT': 'effect_snow', // 출석 Lv.13
      });
    });

    test('Lv.1 은 아직 열린 것이 없어서 개구리 한 장뿐이다', () {
      final provider =
          CosmeticProvider(mockLevels: CosmeticAbilityLevels.start);

      expect(provider.equipped, isEmpty);
      expect(provider.layers, hasLength(1));
      expect(provider.layers.single.isBase, isTrue);
    });

    test('레벨 범위를 벗어나면 1 과 각자의 상한 사이로 잘린다', () {
      // 능력치 넷은 15 까지, 총 학습은 20 까지다.
      final low =
          CosmeticProvider(mockLevels: CosmeticAbilityLevels.uniform(0));
      final high =
          CosmeticProvider(mockLevels: CosmeticAbilityLevels.uniform(99));

      expect(low.levels, CosmeticAbilityLevels.start);
      expect(high.levels.attendance, CosmeticAbilityLevels.maxAbility);
      expect(high.levels.totalStudy, CosmeticAbilityLevels.maxTotalStudy);
      expect(high.levels, CosmeticAbilityLevels.max);
    });
  });

  group('능력치별 해금', () {
    test('제 능력치를 올려야 열린다', () {
      // 봄은 출석 Lv.2 다.
      final provider =
          CosmeticProvider(mockLevels: CosmeticAbilityLevels(attendance: 2));

      expect(provider.isOwned('bg_spring'), isTrue);
    });

    test('다른 능력치를 아무리 올려도 남의 것은 안 열린다', () {
      // 봄은 출석 Lv.2 인데 출석만 Lv.1 로 두고 나머지를 끝까지 올린다.
      final provider = CosmeticProvider(
        mockLevels: CosmeticAbilityLevels(
          attendance: 1,
          noteWrite: CosmeticAbilityLevels.maxAbility,
          problemPractice: CosmeticAbilityLevels.maxAbility,
          notePractice: CosmeticAbilityLevels.maxAbility,
          totalStudy: CosmeticAbilityLevels.maxTotalStudy,
        ),
      );

      expect(provider.isOwned('bg_spring'), isFalse);
      // 다른 능력치의 것들은 다 열려 있다.
      expect(provider.isOwned('glasses_round'), isTrue);
      expect(provider.isOwned('hat_graduate'), isTrue);
    });

    test('총 학습으로 열리는 것은 능력치 넷과 무관하다', () {
      // 왕관은 총 학습 Lv.19 다.
      final provider =
          CosmeticProvider(mockLevels: CosmeticAbilityLevels(totalStudy: 19));

      expect(provider.isOwned('hat_crown'), isTrue);
      // 같은 머리 자리의 비니는 문제 복습 Lv.4 라서 아직 잠겨 있다.
      expect(provider.isOwned('hat_beanie'), isFalse);
    });
  });

  group('setMockLevel', () {
    test('아직 안 갈아입었으면 그 레벨의 첫 차림으로 다시 맞춘다', () {
      final provider = maxed();

      provider.setMockLevels(CosmeticAbilityLevels.uniform(6));

      expect(provider.equipped, {
        // 출석 6: 봄(2) · 여름(4) · 비 오는 날(6) 중 가장 늦은 것
        'BACKGROUND': 'bg_rainy',
        'BAG': 'bag_mini_backpack', // 오답노트 2
        'HAND': 'prop_study', // 오답노트 6
        'BACK': 'back_backpack_navy', // 오답노트 5
        'FACE': 'glasses_sun', // 문제 복습 6
        'HEAD': 'hat_beanie', // 문제 복습 4
        'NECK': 'neck_scarf_coral', // 복습 세트 6
        'OUTFIT': 'outfit_cardigan', // 복습 세트 5
        'BADGE': 'badge_star', // 총 학습 5
        'EFFECT': 'effect_sparkle', // 출석 5
      });
    });

    test('능력치 하나만 옮길 수 있다', () {
      final provider =
          CosmeticProvider(mockLevels: CosmeticAbilityLevels.start);

      provider.setMockLevel(CosmeticAbility.attendance, 9);

      expect(provider.levels.attendance, 9);
      expect(provider.levels.noteWrite, CosmeticAbilityLevels.minLevel);
      expect(provider.isOwned('bg_autumn'), isTrue); // 출석 Lv.9
    });

    test('능력치를 null 로 주면 총 학습 레벨을 옮긴다', () {
      final provider =
          CosmeticProvider(mockLevels: CosmeticAbilityLevels.start);

      provider.setMockLevel(null, 14);

      expect(provider.levels.totalStudy, 14);
      expect(provider.isOwned('badge_flame'), isTrue); // 총 학습 Lv.14
    });

    test('한 번 갈아입은 뒤에는 고른 것을 덮지 않는다', () {
      final provider = maxed();
      provider.equip('HEAD', 'headband_sprout');

      provider.setMockLevel(CosmeticAbility.attendance, 14);

      expect(provider.equippedItemKeyOf('HEAD'), 'headband_sprout');
    });

    test('레벨이 내려가 못 쓰게 된 것은 내린다', () {
      final provider = maxed();
      provider.equip('HEAD', 'hat_crown'); // 총 학습 Lv.19

      provider.setMockLevel(null, 3);

      expect(provider.equippedItemKeyOf('HEAD'), isNull);
    });

    test('알림이 한 번 간다', () {
      final provider = maxed();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.setMockLevel(CosmeticAbility.attendance, 10);
      expect(notified, 1);

      // 같은 레벨이면 아무 일도 없다.
      provider.setMockLevel(CosmeticAbility.attendance, 10);
      expect(notified, 1);
    });

    test('옮기기 전에는 사람이 만진 적 없다고 말한다', () {
      // 옷장 탭 스탯창이 이 값을 보고 진짜 레벨을 그릴지 더미를 그릴지 정한다.
      final provider = maxed();
      expect(provider.levelsTouched, isFalse);

      provider.setMockLevel(CosmeticAbility.attendance, 7);
      expect(provider.levelsTouched, isTrue);
    });
  });

  group('시착', () {
    // 꾸미기 화면은 저장을 눌러야 반영된다. 그동안 프로바이더가 들고 있는
    // 차림이 바뀌면 하단 탭 아이콘과 프로필 사진까지 따라 바뀌어 버린다.
    test('previewEquip 은 넘긴 차림만 바꾸고 프로바이더는 건드리지 않는다', () {
      final provider = maxed();
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
      final provider = maxed();

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
      final provider = maxed();

      expect(provider.layersOf(const {}), hasLength(1));
      expect(provider.layersOf(const {}).single.isBase, isTrue);
      // 프로바이더가 입고 있는 것은 그대로다.
      expect(provider.layers.length, greaterThan(1));
    });

    test('usableOf 는 지금 레벨에서 못 쓰는 것을 걷어 낸다', () {
      final provider = uniform(3);

      // 왕관은 총 학습 Lv.19, 봄은 출석 Lv.2 다.
      final fitting = {'HEAD': 'hat_crown', 'BACKGROUND': 'bg_spring'};

      expect(provider.usableOf(fitting), {'BACKGROUND': 'bg_spring'});
    });

    test('lockReasonOf 는 무엇을 얼마나 올려야 하는지까지 알려 준다', () {
      final provider = uniform(3);

      // 능력치 이름이 없으면 `Lv.19 부터` 가 무엇의 19 인지 알 수 없다.
      expect(provider.lockReasonOf('hat_crown'), '총 학습 Lv.19 부터 쓸 수 있어요.');
      expect(provider.lockReasonOf('hat_beret'), '문제 복습 Lv.10 부터 쓸 수 있어요.');
      expect(provider.lockReasonOf('bg_summer'), '출석 Lv.4 부터 쓸 수 있어요.');
      expect(provider.lockReasonOf('bg_spring'), isNull);
      expect(provider.lockReasonOf('없는_아이템'), '지금은 쓸 수 없는 아이템이에요.');
    });

    test('save 는 시착한 차림을 확정하면서 못 쓰는 것은 걷어 낸다', () {
      final provider = uniform(3);

      provider.save({'HEAD': 'hat_crown', 'BACKGROUND': 'bg_spring'});

      expect(provider.equipped, {'BACKGROUND': 'bg_spring'});
    });

    test('save 로 전부 벗길 수도 있다', () {
      final provider = maxed();
      expect(provider.equipped, isNotEmpty);

      provider.save(const {});

      expect(provider.equipped, isEmpty);
    });
  });

  group('장착', () {
    test('열린 아이템은 걸린다', () {
      final provider = maxed();

      provider.equip('HEAD', 'hat_beanie');

      expect(provider.equippedItemKeyOf('HEAD'), 'hat_beanie');
      expect(provider.lastFailureMessage, isNull);
    });

    test('아직 안 열린 것은 걸리지 않고 무엇을 올려야 하는지 알려 준다', () {
      final provider = uniform(3);

      provider.equip('HEAD', 'hat_crown'); // 총 학습 Lv.19

      expect(provider.equippedItemKeyOf('HEAD'), isNot('hat_crown'));
      expect(provider.consumeFailure(), '총 학습 Lv.19 부터 쓸 수 있어요.');
      // 한 번 꺼내 쓰면 비워져서 같은 말이 두 번 뜨지 않는다.
      expect(provider.lastFailureMessage, isNull);
    });

    test('슬롯이 다르면 걸리지 않는다', () {
      final provider = maxed();

      provider.equip('FACE', 'hat_beanie');

      expect(provider.equippedItemKeyOf('FACE'), isNot('hat_beanie'));
      expect(provider.consumeFailure(), '지금은 쓸 수 없는 아이템이에요.');
    });

    test('unequip 은 그 자리만 비운다', () {
      final provider = maxed();

      provider.unequip('HEAD');

      expect(provider.equippedItemKeyOf('HEAD'), isNull);
      expect(provider.equippedItemKeyOf('OUTFIT'), 'outfit_graduate');
    });

    test('equipSet 은 세트를 통째로 건다', () {
      final provider = maxed();

      provider.equipSet('graduate');

      expect(provider.equippedItemKeyOf('HEAD'), 'hat_graduate');
      expect(provider.equippedItemKeyOf('OUTFIT'), 'outfit_graduate');
      expect(provider.equippedItemKeyOf('HAND'), 'prop_diploma');
    });

    test('세트에 못 가진 것이 있으면 하나도 걸지 않는다', () {
      final provider = uniform(10);

      provider.equipSet('graduate');

      expect(provider.equippedItemKeyOf('HEAD'), isNot('hat_graduate'));
      expect(provider.consumeFailure(), '총 학습 Lv.20 부터 쓸 수 있어요.');
    });

    test('unequipAll 은 걸친 것을 전부 벗긴다', () {
      final provider = maxed();
      provider.equipSet('graduate');
      provider.equip('NECK', 'scarf');

      provider.unequipAll();

      expect(provider.equipped, isEmpty);
    });
  });

  group('NEW 표시', () {
    test('justUnlocked 는 제 능력치에서 막 열린 것만 준다', () {
      // 출석 9 면 가을(출석 9)이 막 열린 것이다. 다른 능력치는 Lv.1 이라
      // Lv.1 에 열리는 것이 없으므로 아무것도 안 걸린다.
      final provider =
          CosmeticProvider(mockLevels: CosmeticAbilityLevels(attendance: 9));

      expect(
        [for (final item in provider.justUnlocked) item.itemKey],
        ['bg_autumn'],
      );
    });
  });

  group('레벨업 연출에 넘길 것', () {
    test('layersAtLevel 은 지금 차림과 무관하게 그 레벨의 기본 차림이다', () {
      final provider = maxed();
      provider.unequip('HEAD');

      final before = provider.layersAtLevel(19);
      final after = provider.layersAtLevel(20);

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

    test('unlockedAtTotalStudyLevel 은 총 학습으로 열리는 것만 준다', () {
      final provider = maxed();

      expect(
        [
          for (final item in provider.unlockedAtTotalStudyLevel(20))
            item.itemKey,
        ],
        ['hat_graduate', 'outfit_graduate', 'prop_diploma'],
      );
      expect(provider.unlockedAtTotalStudyLevel(1), isEmpty);

      // 출석 Lv.15 의 우주는 총 학습 레벨업의 몫이 아니다. 레벨업 축하는
      // 총 학습 레벨이 오를 때 뜨기 때문이다.
      expect(
        [
          for (final item in provider.unlockedAtTotalStudyLevel(15))
            item.itemKey,
        ],
        isEmpty,
      );
    });
  });

  group('프로필 테두리', () {
    // FRAME 은 개구리에 겹치지 않는 유일한 자리다. 원형 프로필 사진 둘레에만
    // 두른다. 이걸 안 보면 테두리가 개구리 얼굴 위를 덮는다.
    test('개구리 합성에서 빠진다', () {
      final provider = maxed()..equip('FRAME', 'frame_master');

      expect(provider.equipped['FRAME'], 'frame_master');
      expect(
        provider.layers.any((layer) => layer.slot == 'FRAME'),
        isFalse,
        reason: '프레임이 개구리 위에 그려지고 있다',
      );
    });

    test('걸친 테두리는 profileFrame 으로 따로 나온다', () {
      final provider = maxed()..equip('FRAME', 'frame_master');

      expect(provider.profileFrame?.itemKey, 'frame_master');
      expect(provider.profileFrame?.imageUrl,
          'assets/ProfileFrame/frame_master.svg');
    });

    test('안 걸치면 null 이다', () {
      expect(maxed().profileFrame, isNull);
    });

    test('첫 차림에는 안 들어간다', () {
      // 프로필은 스터디룸에서 남들과 나란히 보이는데 서버가 남의 치장을
      // 안 내려준다. 자동으로 걸면 나만 테두리가 있게 된다.
      expect(maxed().equipped.containsKey('FRAME'), isFalse);
      expect(uniform(12).equipped.containsKey('FRAME'), isFalse);
    });

    test('합성되는 자리는 첫 차림에 그대로 들어간다', () {
      // 프레임만 빠져야지 다른 자리까지 빠지면 안 된다.
      final equipped = maxed().equipped;
      for (final slot in CosmeticMockData.loadout.slots) {
        if (!slot.composited) continue;
        expect(equipped.containsKey(slot.slot), isTrue, reason: slot.slot);
      }
    });
  });

  group('무대에 깔 배경', () {
    // 옷장 탭의 무대는 배경 파츠 한 장을 개구리 사각형에서 꺼내 화면 전체로
    // 편다. 512 정사각형이 둥근 사각형에 갇혀 있으면 개구리가 선 무대가 아니라
    // 벽에 걸린 사진 한 장으로 읽히고, 무대가 깔아 둔 조명과 바닥 그림자를
    // 그 그림이 통째로 덮어 버린다.
    test('가장 뒤에 그려지는 자리의 것을 무대로 내보낸다', () {
      final provider = maxed();

      expect(provider.stageBackdrop?.itemKey, 'bg_space');
      expect(provider.stageBackdrop?.slot, 'BACKGROUND');
    });

    test('배경을 안 걸치면 없다', () {
      final provider = maxed()..unequipAll();

      expect(provider.stageBackdrop, isNull);
      // 뺄 것이 없으면 층이 하나도 안 줄어든다. 모델에 == 이 없어서 목록끼리
      // 견주지 않고 길이로 본다.
      expect(provider.layersOnStage.length, provider.layers.length);
    });

    test('개구리에게는 배경 한 장만 빠진 층들이 간다', () {
      final provider = maxed();

      final onStage = provider.layersOnStage;
      expect(onStage.length, provider.layers.length - 1);
      expect(onStage.any((layer) => layer.slot == 'BACKGROUND'), isFalse);
    });

    test('배낭은 개구리와 함께 남는다', () {
      // 배낭도 개구리보다 뒤에 그려지지만 개구리 몸에 맞춰 그린 그림이다.
      // 무대로 내보내면 자리가 어긋난다. layersWithoutBackdrop 과 다른 점이다.
      final provider = maxed();

      expect(
        provider.layersOnStage.any((layer) => layer.slot == 'BACK'),
        isTrue,
      );
      expect(
        provider.layersWithoutBackdrop.any((layer) => layer.slot == 'BACK'),
        isFalse,
      );
    });
  });

  group('더미 카탈로그', () {
    test('에셋 경로가 자리에 맞는 곳을 가리킨다', () {
      // 개구리에 겹치는 파츠는 512 비트맵이고, 개구리에 안 겹치는 자리
      // (프로필 테두리)는 벡터다. 크기가 널뛰는 원 둘레에 쓰여서 비트맵으로
      // 두면 어느 한쪽이 뭉갠다.
      final catalog = CosmeticMockData.loadout;

      for (final item in catalog.items) {
        final composited = catalog.slotOf(item.slot)?.composited ?? true;
        expect(
          item.imageUrl,
          composited
              ? 'assets/Cosmetic/${item.itemKey}.png'
              : 'assets/ProfileFrame/${item.itemKey}.svg',
          reason: item.itemKey,
        );
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

    test('레벨로 안 열리는 아이템은 하나도 없다', () {
      // 예전에는 절반 넘게 "미션 보상"이라 레벨을 올려도 안 열렸다. 지금은
      // 쉰다섯이 전부 어느 능력치엔가 매달려 있다.
      final provider = maxed();

      for (final item in provider.items) {
        expect(item.owned, isTrue, reason: item.itemKey);
      }
    });

    test('세트는 학사 세트 하나뿐이고 이름을 달고 있다', () {
      for (final item in CosmeticMockData.loadout.items) {
        if (item.setId == null) {
          expect(item.setNameKo, isNull, reason: item.itemKey);
          continue;
        }
        expect(item.setId, CosmeticMockData.graduateSetId,
            reason: item.itemKey);
        expect(
          item.setNameKo,
          CosmeticMockData.graduateSetNameKo,
          reason: item.itemKey,
        );
      }
    });
  });
}
