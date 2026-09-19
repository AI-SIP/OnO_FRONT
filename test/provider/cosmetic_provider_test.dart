// 옷장 프로바이더 테스트.
//
// **카탈로그도 차림도 서버가 준다.** 그래서 여기 있는 프로바이더는 전부
// 가짜 서버([FakeCosmeticService])에서 한 번 받아 온 것이다. 생성자로 상태를
// 밀어 넣지 않는다. 그러면 조회가 빠진 길을 잠그게 된다.
//
// 잠그는 것은 셋이다.
//
// 1. **서버가 준 것을 그대로 그리는가.** 차림도 `owned` 도 서버가 정한다.
// 2. **못 받아도 앱이 사는가.** 조회가 실패해도 개구리 한 장은 나와야 한다.
// 3. **저장이 실패하면 되돌아가는가.** 먼저 바꾸고 나중에 묻는 방식이라,
//    실패했을 때 서버가 준 마지막 차림으로 돌아가지 않으면 앱과 서버가 다른
//    옷을 말하게 된다.
//
// 해금이 능력치별이라는 것(출석만 올린 사람에게 배경이 열리고 복습만 한
// 사람에게 안경이 열린다)은 이제 서버가 정하지만, 그 표가 `해금표.md` 이고
// 가짜 서버가 같은 표를 쓰기 때문에 여기서도 그대로 확인할 수 있다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Model/Cosmetic/CosmeticEquipResultModel.dart';
import 'package:ono/Model/Cosmetic/CosmeticItemModel.dart';
import 'package:ono/Provider/CosmeticProvider.dart';

import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  /// 다섯을 다 끝까지 올린 사람.
  Future<CosmeticProvider> maxed() =>
      loadedCosmeticProvider(levels: CosmeticAbilityLevels.max);

  /// 다섯을 같은 값으로 놓은 사람. 한 축으로 훑어 볼 때 쓴다.
  Future<CosmeticProvider> uniform(int level) =>
      loadedCosmeticProvider(levels: CosmeticAbilityLevels.uniform(level));

  /// 그 레벨들의 사람.
  Future<CosmeticProvider> at(CosmeticAbilityLevels levels) =>
      loadedCosmeticProvider(levels: levels);

  group('서버가 준 차림', () {
    // 옷장을 한 번도 안 연 사람에게 무엇을 입혀 줄지는 **서버가 정한다.**
    // 자리마다 가장 늦게 열린 것을 고르는 규칙은 `defaultPreset()` 의 것이고,
    // 앱은 응답의 `equipped` 를 그대로 그린다. 규칙이 바뀌어도 앱을 다시
    // 내보낼 필요가 없어야 해서 그렇게 갈랐다.
    test('받은 것을 그대로 입는다', () async {
      final provider = await maxed();

      expect(provider.equipped, {
        'BACKGROUND': 'bg_space', // 출석 Lv.15
        'OUTFIT': 'outfit_graduate', // 총 학습 Lv.20
        // 배낭과 앞가방이 한 자리라 다섯 중 하나만 걸린다.
        'BAG': 'bag_crossbody_satchel', // 오답노트 Lv.11
        'NECK': 'neck_medal', // 복습 세트 Lv.12
        'FACE': 'face_moustache', // 문제 복습 Lv.14
        'HEAD': 'hat_graduate', // 총 학습 Lv.20
        'HAND': 'prop_diploma', // 총 학습 Lv.20
        'BADGE': 'badge_snowflake', // 총 학습 Lv.18
        'EFFECT': 'effect_snow', // 출석 Lv.13
      });
    });

    test('Lv.1 은 아직 열린 것이 없어서 개구리 한 장뿐이다', () async {
      final provider = await at(CosmeticAbilityLevels.start);

      expect(provider.equipped, isEmpty);
      expect(provider.layers, hasLength(1));
      expect(provider.layers.single.isBase, isTrue);
    });

    test('레벨은 유저 정보에서 온다', () async {
      // 프로바이더가 혼자 떠 있으면 이 사람의 레벨을 한 번도 못 본다.
      // 유저 정보를 받는 자리에서 [syncWithUser] 로 넘어온다.
      final provider = await at(CosmeticAbilityLevels(attendance: 9));

      expect(provider.levels.attendance, 9);
      expect(provider.levels.noteWrite, CosmeticAbilityLevels.minLevel);
    });

    test('레벨 범위를 벗어나면 1 과 각자의 상한 사이로 잘린다', () async {
      // 능력치 넷과 총 학습 모두 상한은 20 이다. 임계값이 네 배 관계라
      // 넷을 만렙까지 올린 누적이 총 학습 만렙과 정확히 맞물린다.
      final low = await uniform(0);
      final high = await uniform(99);

      expect(low.levels, CosmeticAbilityLevels.start);
      expect(high.levels.attendance, CosmeticAbilityLevels.maxAbility);
      expect(high.levels.totalStudy, CosmeticAbilityLevels.maxTotalStudy);
      expect(high.levels, CosmeticAbilityLevels.max);
    });

    test('레벨이 그대로면 옷장을 다시 읽지 않는다', () async {
      // 유저 정보는 문제를 하나 풀 때마다도 다시 읽힌다. 그때마다 옷장까지
      // 물으면 요청만 는다. 새로 열린 것이 생기는 때는 레벨이 오른 때다.
      final service = FakeCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.uniform(5)),
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.uniform(5),
        service: service,
      );
      expect(service.loadCount, 1);

      await provider.syncWithUser(
          CosmeticMockData.userInfoAt(CosmeticAbilityLevels.uniform(5)));
      expect(service.loadCount, 1);

      // 레벨이 오르면 새로 열린 것이 있을 수 있어 그때는 다시 읽는다.
      await provider.syncWithUser(
          CosmeticMockData.userInfoAt(CosmeticAbilityLevels.uniform(6)));
      expect(service.loadCount, 2);
    });
  });

  group('못 받았을 때', () {
    // 이 프로바이더를 보는 화면이 열일곱 군데다. 하단 탭 아이콘부터 출석
    // 도장까지 걸쳐 있어서, 여기서 터지거나 빈 목록을 주면 앱이 통째로
    // 고장 난 것처럼 보인다.
    test('조회가 실패해도 개구리 한 장은 그린다', () async {
      final provider = await loadedCosmeticProvider(
        service: FakeCosmeticService(failLoad: true),
      );

      expect(provider.hasCatalog, isFalse);
      expect(provider.loadFailed, isTrue);
      expect(provider.slots, isEmpty);
      expect(provider.items, isEmpty);
      expect(provider.equipped, isEmpty);
      // 빈 목록이 아니다. 개구리 한 장이다.
      expect(provider.layers, hasLength(1));
      expect(provider.layers.single.isBase, isTrue);
      expect(provider.layersWithoutBackdrop, hasLength(1));
      expect(provider.stageBackdrop, isNull);
      expect(provider.profileFrame, isNull);
    });

    test('다시 시도해서 받으면 그때부터 입는다', () async {
      final service = FakeCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.max),
        failLoad: true,
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.max,
        service: service,
      );
      expect(provider.loadFailed, isTrue);

      service.failLoad = false;
      await provider.load();

      expect(provider.hasCatalog, isTrue);
      expect(provider.loadFailed, isFalse);
      expect(provider.equipped, isNotEmpty);
    });

    test('한 번 받은 뒤의 조회 실패는 입고 있던 것을 벗기지 않는다', () async {
      // 잠깐 끊겼다고 입고 있던 옷이 벗겨지는 편이 더 이상하다.
      final service = FakeCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.max),
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.max,
        service: service,
      );
      final before = Map<String, String>.from(provider.equipped);

      service.failLoad = true;
      await provider.load();

      expect(provider.equipped, before);
      expect(provider.hasCatalog, isTrue);
      expect(provider.loadFailed, isFalse);
    });
  });

  group('owned 는 서버가 정한다', () {
    test('디버그 패널을 안 만졌으면 서버 값을 그대로 쓴다', () async {
      // 레벨로 여는 것 말고 다른 길이 생겨도 앱은 몰라도 된다. 서버가
      // `owned: true` 라고 하면 가진 것이다.
      final levels = CosmeticAbilityLevels(attendance: 1);
      final catalog = CosmeticMockData.catalogAt(levels);
      // 출석 Lv.2 짜리 봄을 서버가 가졌다고 내려준다. 레벨만 보면 잠긴 것이다.
      final service = FakeCosmeticService(
        catalog: catalog.withOwned(const ['bg_spring']),
      );
      final provider = await loadedCosmeticProvider(
        levels: levels,
        service: service,
      );

      expect(provider.isOwned('bg_spring'), isTrue);
      expect(provider.lockReasonOf('bg_spring'), isNull);
    });

    test('서버가 안 줬으면 잠겨 있고 무엇을 올려야 하는지 말한다', () async {
      final provider = await uniform(3);

      // 능력치 이름이 없으면 `Lv.19 부터` 가 무엇의 19 인지 알 수 없다.
      expect(provider.isOwned('hat_crown'), isFalse);
      expect(provider.lockReasonOf('hat_crown'), '총 학습 Lv.19 부터 쓸 수 있어요.');
      expect(provider.lockReasonOf('hat_beret'), '문제 복습 Lv.10 부터 쓸 수 있어요.');
      expect(provider.lockReasonOf('bg_summer'), '출석 Lv.4 부터 쓸 수 있어요.');
      expect(provider.lockReasonOf('bg_spring'), isNull);
      expect(provider.lockReasonOf('없는_아이템'), '지금은 쓸 수 없는 아이템이에요.');
    });

    test('제 능력치를 올려야 열린다', () async {
      // 봄은 출석 Lv.2 다.
      final provider = await at(CosmeticAbilityLevels(attendance: 2));

      expect(provider.isOwned('bg_spring'), isTrue);
    });

    test('다른 능력치를 아무리 올려도 남의 것은 안 열린다', () async {
      // 봄은 출석 Lv.2 인데 출석만 Lv.1 로 두고 나머지를 끝까지 올린다.
      final provider = await at(
        CosmeticAbilityLevels(
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

    test('총 학습으로 열리는 것은 능력치 넷과 무관하다', () async {
      // 왕관은 총 학습 Lv.19 다.
      final provider = await at(CosmeticAbilityLevels(totalStudy: 19));

      expect(provider.isOwned('hat_crown'), isTrue);
      // 같은 머리 자리의 비니는 문제 복습 Lv.4 라서 아직 잠겨 있다.
      expect(provider.isOwned('hat_beanie'), isFalse);
    });
  });

  group('setMockLevel', () {
    // **디버그 전용이다.** 서버 `owned` 만 쓰면 패널에서 레벨을 옮겨도 해금
    // 상태가 그대로라 패널이 무력해진다. 그래서 패널을 만진 뒤로는 앱이
    // 직접 매긴다. 릴리즈에서는 이 메서드가 통째로 막혀 있다.
    test('아직 안 갈아입었으면 그 레벨의 첫 차림으로 다시 맞춘다', () async {
      final provider = await maxed();

      provider.setMockLevels(CosmeticAbilityLevels.uniform(6));

      expect(provider.equipped, {
        // 출석 6: 봄(2) · 여름(4) · 비 오는 날(6) 중 가장 늦은 것
        'BACKGROUND': 'bg_rainy',
        // 가방 자리에서 가장 늦게 열린 것. 미니 백팩(2)보다 남색 배낭(5)이
        // 늦다. 둘이 한 자리라 하나만 걸린다.
        'BAG': 'back_backpack_navy', // 오답노트 5
        'HAND': 'prop_study', // 오답노트 6
        'FACE': 'glasses_sun', // 문제 복습 6
        'HEAD': 'hat_beanie', // 문제 복습 4
        'NECK': 'neck_scarf_coral', // 복습 세트 6
        'OUTFIT': 'outfit_cardigan', // 복습 세트 5
        'BADGE': 'badge_star', // 총 학습 5
        'EFFECT': 'effect_sparkle', // 출석 5
      });
    });

    test('능력치 하나만 옮길 수 있다', () async {
      final provider = await at(CosmeticAbilityLevels.start);

      provider.setMockLevel(CosmeticAbility.attendance, 9);

      expect(provider.levels.attendance, 9);
      expect(provider.levels.noteWrite, CosmeticAbilityLevels.minLevel);
      // 서버는 Lv.1 기준으로 owned 를 줬지만 패널을 만진 뒤로는 앱이 매긴다.
      expect(provider.isOwned('bg_autumn'), isTrue); // 출석 Lv.9
    });

    test('능력치를 null 로 주면 총 학습 레벨을 옮긴다', () async {
      final provider = await at(CosmeticAbilityLevels.start);

      provider.setMockLevel(null, 14);

      expect(provider.levels.totalStudy, 14);
      expect(provider.isOwned('badge_flame'), isTrue); // 총 학습 Lv.14
    });

    test('한 번 갈아입은 뒤에는 고른 것을 덮지 않는다', () async {
      final provider = await maxed();
      await provider.equip('HEAD', 'headband_sprout');

      provider.setMockLevel(CosmeticAbility.attendance, 14);

      expect(provider.equippedItemKeyOf('HEAD'), 'headband_sprout');
    });

    test('레벨이 내려가 못 쓰게 된 것은 내린다', () async {
      final provider = await maxed();
      await provider.equip('HEAD', 'hat_crown'); // 총 학습 Lv.19

      provider.setMockLevel(null, 3);

      expect(provider.equippedItemKeyOf('HEAD'), isNull);
    });

    test('알림이 한 번 간다', () async {
      final provider = await maxed();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.setMockLevel(CosmeticAbility.attendance, 10);
      expect(notified, 1);

      // 같은 레벨이면 아무 일도 없다.
      provider.setMockLevel(CosmeticAbility.attendance, 10);
      expect(notified, 1);
    });

    test('옮기기 전에는 사람이 만진 적 없다고 말한다', () async {
      // 옷장 탭 스탯창이 이 값을 보고 진짜 레벨을 그릴지 더미를 그릴지 정한다.
      final provider = await maxed();
      expect(provider.levelsTouched, isFalse);

      provider.setMockLevel(CosmeticAbility.attendance, 7);
      expect(provider.levelsTouched, isTrue);
    });

    test('디버그로 옮긴 차림은 서버로 나가지 않는다', () async {
      // 진짜 레벨이 아닌 것을 보고 고른 차림이라 서버에 남길 것이 아니다.
      final service = FakeCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.max),
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.max,
        service: service,
      );

      provider.setMockLevels(CosmeticAbilityLevels.uniform(6));

      expect(service.equipAllRequests, isEmpty);
    });
  });

  group('시착', () {
    // 꾸미기 화면은 저장을 눌러야 반영된다. 그동안 프로바이더가 들고 있는
    // 차림이 바뀌면 하단 탭 아이콘과 프로필 사진까지 따라 바뀌어 버린다.
    test('previewEquip 은 넘긴 차림만 바꾸고 프로바이더는 건드리지 않는다', () async {
      final provider = await maxed();
      final before = Map<String, String>.from(provider.equipped);

      final next = provider.previewEquip(
        provider.equipped,
        slot: 'HEAD',
        itemKey: 'hat_beanie',
      );

      expect(next['HEAD'], 'hat_beanie');
      expect(provider.equipped, before);
    });

    test('previewEquip 도 같이 걸 수 없는 것은 함께 내린다', () async {
      final provider = await maxed();

      final next = provider.previewEquip(
        provider.equipped,
        slot: 'HEAD',
        itemKey: 'hat_beanie',
      );

      // 실제로 거는 equip 과 같은 규칙을 써야 화면과 프로바이더가 다른 말을
      // 하지 않는다.
      await provider.equip('HEAD', 'hat_beanie');
      expect(next, provider.equipped);
    });

    test('layersOf 는 넘긴 차림을 그린다', () async {
      final provider = await maxed();

      expect(provider.layersOf(const {}), hasLength(1));
      expect(provider.layersOf(const {}).single.isBase, isTrue);
      // 프로바이더가 입고 있는 것은 그대로다.
      expect(provider.layers.length, greaterThan(1));
    });

    test('usableOf 는 지금 못 쓰는 것을 걷어 낸다', () async {
      final provider = await uniform(3);

      // 왕관은 총 학습 Lv.19, 봄은 출석 Lv.2 다.
      final fitting = {'HEAD': 'hat_crown', 'BACKGROUND': 'bg_spring'};

      expect(provider.usableOf(fitting), {'BACKGROUND': 'bg_spring'});
    });
  });

  group('저장', () {
    test('시착한 차림을 확정하면서 못 쓰는 것은 걷어 낸다', () async {
      final provider = await uniform(3);

      await provider.save({'HEAD': 'hat_crown', 'BACKGROUND': 'bg_spring'});

      expect(provider.equipped, {'BACKGROUND': 'bg_spring'});
    });

    test('전부 벗길 수도 있다', () async {
      final provider = await maxed();
      expect(provider.equipped, isNotEmpty);

      await provider.save(const {});

      expect(provider.equipped, isEmpty);
    });

    test('서버로 차림 전체가 한 번에 나간다', () async {
      // 자리마다 요청을 하나씩 보내면 중간에 하나가 실패했을 때 절반만
      // 갈아입은 차림이 서버에 남는다.
      final service = FakeCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.max),
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.max,
        service: service,
      );

      await provider.save({'HEAD': 'hat_beanie', 'BACKGROUND': 'bg_spring'});

      expect(service.equipAllRequests, hasLength(1));
      expect(service.equipAllRequests.single, {
        'HEAD': 'hat_beanie',
        'BACKGROUND': 'bg_spring',
      });
    });

    test('프로필 테두리도 함께 실려 나간다', () async {
      // 서버는 **요청에 없는 자리를 비운다.** 개구리에 안 겹치는 자리라고
      // 저장 payload 에서 빼면, 다른 자리를 바꿀 때마다 사용자가 골라 둔
      // 테두리가 조용히 벗겨진다.
      final provider = await maxed();
      await provider.equip('FRAME', 'frame_master');
      expect(provider.equipped['FRAME'], 'frame_master');

      // 꾸미기 화면이 넘기는 것과 같은 모양이다. 지금 차림에서 한 자리만 바꾼다.
      await provider.save(
        provider.previewEquip(
          provider.equipped,
          slot: 'HEAD',
          itemKey: 'hat_beanie',
        ),
      );

      expect(provider.equipped['HEAD'], 'hat_beanie');
      expect(
        provider.equipped['FRAME'],
        'frame_master',
        reason: '다른 자리를 바꿨는데 프로필 테두리가 벗겨졌다',
      );
    });

    test('실패하면 서버가 준 마지막 차림으로 되돌아간다', () async {
      // 먼저 바꾸고 나중에 묻는다. 되돌리지 않으면 앱과 서버가 서로 다른
      // 옷을 말하게 되고, 다음에 앱을 켜면 저장된 줄 알았던 차림이 사라진다.
      final service = FakeCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.max),
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.max,
        service: service,
      );
      final before = Map<String, String>.from(provider.equipped);

      service.failEquip = true;
      final saved = await provider.save(const {'HEAD': 'hat_beanie'});

      expect(saved, isFalse);
      expect(provider.equipped, before);
      expect(provider.consumeFailure(), '차림을 저장하지 못했어요. 잠시 뒤 다시 해 주세요.');
      // 한 번 꺼내 쓰면 비워져서 같은 말이 두 번 뜨지 않는다.
      expect(provider.lastFailureMessage, isNull);
    });

    test('실패해도 서버의 차림은 그대로다', () async {
      final service = FakeCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.max),
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.max,
        service: service,
      );
      final onServer = Map<String, String>.from(service.equipped);

      service.failEquip = true;
      await provider.save(const {'HEAD': 'hat_beanie'});
      service.failEquip = false;
      await provider.load();

      expect(provider.equipped, onServer);
    });

    test('서버가 벗긴 자리가 있으면 무엇이 벗겨졌는지 알린다', () async {
      // 저장은 됐는데 고른 것 중 일부가 조용히 사라지면 저장이 안 된 것으로
      // 읽힌다. 자리 이름은 서버가 준 것을 쓴다.
      final service = FakeCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.max),
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.max,
        service: service,
      );

      service.equipAllUnequippedSlots = const ['HEAD', 'FACE'];
      final saved = await provider.save(const {'BACKGROUND': 'bg_spring'});

      expect(saved, isTrue);
      expect(provider.consumeNotice(), '머리 · 얼굴 자리는 함께 벗었어요.');
      expect(provider.lastNoticeMessage, isNull);
      // 실패가 아니다. 저장은 됐다.
      expect(provider.lastFailureMessage, isNull);
    });

    test('벗긴 자리가 없으면 알릴 것도 없다', () async {
      final provider = await maxed();

      await provider.save(const {'BACKGROUND': 'bg_spring'});

      expect(provider.consumeNotice(), isNull);
    });

    test('서버가 준 차림이 보낸 것과 달라도 서버 쪽을 따른다', () async {
      // 한 요청 안에서 둘이 부딪히면 어느 쪽을 남길지는 서버가 정한다.
      // 앱이 예상한 것과 달라도 응답이 진실이다.
      final service = _RewritingCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.max),
        rewritten: const {'OUTFIT': 'outfit_hoodie'},
        unequipped: const ['HEAD'],
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.max,
        service: service,
      );

      await provider.save(const {
        'OUTFIT': 'outfit_hoodie',
        'HEAD': 'hat_beanie',
      });

      expect(provider.equipped, {'OUTFIT': 'outfit_hoodie'});
      expect(provider.consumeNotice(), '머리 자리는 함께 벗었어요.');
    });
  });

  group('장착', () {
    test('열린 아이템은 걸린다', () async {
      final provider = await maxed();

      await provider.equip('HEAD', 'hat_beanie');

      expect(provider.equippedItemKeyOf('HEAD'), 'hat_beanie');
      expect(provider.lastFailureMessage, isNull);
    });

    test('아직 안 열린 것은 서버에 묻지도 않는다', () async {
      final service = FakeCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.uniform(3)),
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.uniform(3),
        service: service,
      );
      final before = Map<String, String>.from(service.equipped);

      await provider.equip('HEAD', 'hat_crown'); // 총 학습 Lv.19

      expect(provider.equippedItemKeyOf('HEAD'), isNot('hat_crown'));
      expect(provider.consumeFailure(), '총 학습 Lv.19 부터 쓸 수 있어요.');
      expect(service.equipped, before);
    });

    test('슬롯이 다르면 걸리지 않는다', () async {
      final provider = await maxed();

      await provider.equip('FACE', 'hat_beanie');

      expect(provider.equippedItemKeyOf('FACE'), isNot('hat_beanie'));
      expect(provider.consumeFailure(), '지금은 쓸 수 없는 아이템이에요.');
    });

    test('unequip 은 그 자리만 비운다', () async {
      final provider = await maxed();

      await provider.unequip('HEAD');

      expect(provider.equippedItemKeyOf('HEAD'), isNull);
      expect(provider.equippedItemKeyOf('OUTFIT'), 'outfit_graduate');
    });

    test('equipSet 은 세트를 통째로 건다', () async {
      final provider = await maxed();

      await provider.equipSet('graduate');

      expect(provider.equippedItemKeyOf('HEAD'), 'hat_graduate');
      expect(provider.equippedItemKeyOf('OUTFIT'), 'outfit_graduate');
      expect(provider.equippedItemKeyOf('HAND'), 'prop_diploma');
    });

    test('세트에 못 가진 것이 있으면 하나도 걸지 않는다', () async {
      final provider = await uniform(10);

      await provider.equipSet('graduate');

      expect(provider.equippedItemKeyOf('HEAD'), isNot('hat_graduate'));
      expect(provider.consumeFailure(), '총 학습 Lv.20 부터 쓸 수 있어요.');
    });

    test('unequipAll 은 걸친 것을 전부 벗긴다', () async {
      final provider = await maxed();
      await provider.equipSet('graduate');
      await provider.equip('NECK', 'scarf');

      await provider.unequipAll();

      expect(provider.equipped, isEmpty);
    });

    test('장착이 실패하면 되돌아간다', () async {
      final service = FakeCosmeticService(
        catalog: CosmeticMockData.catalogAt(CosmeticAbilityLevels.max),
      );
      final provider = await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.max,
        service: service,
      );
      final before = Map<String, String>.from(provider.equipped);

      service.failEquip = true;
      final done = await provider.equip('HEAD', 'hat_beanie');

      expect(done, isFalse);
      expect(provider.equipped, before);
      expect(provider.consumeFailure(), '갈아입지 못했어요. 잠시 뒤 다시 해 주세요.');
    });
  });

  group('로그아웃', () {
    test('비우면 개구리 한 장만 남는다', () async {
      // 비우지 않으면 같은 기기에서 다른 계정으로 로그인한 첫 화면의 하단
      // 탭과 프로필에 앞 사람이 꾸며 둔 개구리가 그대로 남는다.
      final provider = await maxed();
      expect(provider.equipped, isNotEmpty);

      provider.clear();

      expect(provider.hasCatalog, isFalse);
      expect(provider.loadState, CosmeticLoadState.idle);
      expect(provider.equipped, isEmpty);
      expect(provider.items, isEmpty);
      expect(provider.slots, isEmpty);
      expect(provider.levels, CosmeticAbilityLevels.start);
      expect(provider.levelsTouched, isFalse);
      expect(provider.layers, hasLength(1));
      expect(provider.layers.single.isBase, isTrue);
    });

    test('비운 뒤 다시 로그인하면 새 사람의 옷장을 받는다', () async {
      final provider = await maxed();
      provider.clear();

      await provider
          .syncWithUser(CosmeticMockData.userInfoAt(CosmeticAbilityLevels.max));

      expect(provider.hasCatalog, isTrue);
      expect(provider.equipped, isNotEmpty);
    });
  });

  group('NEW 표시', () {
    test('justUnlocked 는 제 능력치에서 막 열린 것만 준다', () async {
      // 출석 9 면 가을(출석 9)이 막 열린 것이다. 다른 능력치는 Lv.1 이라
      // Lv.1 에 열리는 것이 없으므로 아무것도 안 걸린다.
      final provider = await at(CosmeticAbilityLevels(attendance: 9));

      expect(
        [for (final item in provider.justUnlocked) item.itemKey],
        ['bg_autumn'],
      );
    });
  });

  group('레벨업 연출에 넘길 것', () {
    test('unlockedAtTotalStudyLevel 은 총 학습으로 열리는 것만 준다', () async {
      final provider = await maxed();

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

    test('layersAtLevel 은 지금 차림과 무관하게 그 레벨의 첫 차림이다', () async {
      // **디버그 조합 검수 화면만 쓴다.** 그 스무 벌은 이 사람의 차림이 아니라
      // 서버에 물을 것이 없어서, 규칙 한 벌이 [DebugCosmeticPreset] 에 남아
      // 있다. 릴리즈에서는 빈 맵이라 개구리 한 장이 나오고, 이걸 부르는 화면
      // 자체가 디버그에서만 열린다.
      final provider = await maxed();
      await provider.unequip('HEAD');

      expect(
        [for (final layer in provider.layersAtLevel(20)) layer.itemKey],
        contains('hat_graduate'),
      );
      expect(
        [for (final layer in provider.layersAtLevel(19)) layer.itemKey],
        contains('hat_crown'),
      );
      // 지금 차림은 건드리지 않는다.
      expect(provider.equippedItemKeyOf('HEAD'), isNull);
    });

    test('layersWith 는 지금 차림 위에 방금 열린 것을 얹는다', () async {
      final provider = await maxed();
      await provider.unequip('HEAD');

      final crown = provider.itemOf('hat_crown')!;
      final layers = provider.layersWith([
        CosmeticUnlockModel(
          itemKey: crown.itemKey,
          nameKo: crown.nameKo,
          slot: crown.slot,
          imageUrl: crown.imageUrl,
        ),
      ]);

      expect(
        [for (final layer in layers) layer.itemKey],
        contains('hat_crown'),
      );
      // 지금 차림은 건드리지 않는다.
      expect(provider.equippedItemKeyOf('HEAD'), isNull);
    });
  });

  group('프로필 테두리', () {
    // FRAME 은 개구리에 겹치지 않는 유일한 자리다. 원형 프로필 사진 둘레에만
    // 두른다. 이걸 안 보면 테두리가 개구리 얼굴 위를 덮는다.
    test('개구리 합성에서 빠진다', () async {
      final provider = await maxed();
      await provider.equip('FRAME', 'frame_master');

      expect(provider.equipped['FRAME'], 'frame_master');
      expect(
        provider.layers.any((layer) => layer.slot == 'FRAME'),
        isFalse,
        reason: '프레임이 개구리 위에 그려지고 있다',
      );
    });

    test('걸친 테두리는 profileFrame 으로 따로 나온다', () async {
      final provider = await maxed();
      await provider.equip('FRAME', 'frame_master');

      expect(provider.profileFrame?.itemKey, 'frame_master');
      expect(provider.profileFrame?.imageUrl,
          'assets/ProfileFrame/frame_master.svg');
    });

    test('안 걸치면 null 이다', () async {
      expect((await maxed()).profileFrame, isNull);
    });

    test('서버가 준 첫 차림에는 안 들어간다', () async {
      // 프로필은 스터디룸에서 남들과 나란히 보이는데 서버가 남의 치장을
      // 안 내려준다. 자동으로 걸면 나만 테두리가 있게 된다.
      expect((await maxed()).equipped.containsKey('FRAME'), isFalse);
      expect((await uniform(12)).equipped.containsKey('FRAME'), isFalse);
    });

    test('합성되는 자리는 첫 차림에 그대로 들어간다', () async {
      // 프레임만 빠져야지 다른 자리까지 빠지면 안 된다.
      final provider = await maxed();
      for (final slot in provider.slots) {
        if (!slot.composited) continue;
        expect(provider.equipped.containsKey(slot.slot), isTrue,
            reason: slot.slot);
      }
    });
  });

  group('가방 자리의 그리는 층', () {
    // 등에 메는 배낭과 앞으로 메는 가방이 한 자리다. 사용자에게는 `가방` 한
    // 탭이고 그중 하나만 걸린다. 자리를 합치면서 그리는 층까지 하나로 묶으면
    // 배낭이 개구리 앞으로 나와 몸통 위에 얹힌다. **합치면서 제일 깨지기 쉬운
    // 지점이라 여기서 잠근다.**
    int orderOf(CosmeticProvider provider, String itemKey) {
      return provider.layers
          .firstWhere((layer) => layer.itemKey == itemKey)
          .layerOrder;
    }

    int baseOrder(CosmeticProvider provider) {
      return provider.layers.firstWhere((layer) => layer.isBase).layerOrder;
    }

    test('배낭은 개구리 뒤에 그려진다', () async {
      for (final itemKey in ['back_backpack_navy', 'back_backpack_canvas']) {
        final provider = await maxed();
        await provider.equip('BAG', itemKey);

        expect(provider.equipped['BAG'], itemKey);
        expect(
          orderOf(provider, itemKey),
          lessThan(baseOrder(provider)),
          reason: '$itemKey 가 개구리 앞으로 나왔다',
        );
      }
    });

    test('앞으로 메는 가방은 개구리 앞에 그려진다', () async {
      for (final itemKey in [
        'bag_mini_backpack',
        'bag_waist_pouch',
        'bag_crossbody_satchel',
      ]) {
        final provider = await maxed();
        await provider.equip('BAG', itemKey);

        expect(
          orderOf(provider, itemKey),
          greaterThan(baseOrder(provider)),
          reason: '$itemKey 가 개구리 뒤로 갔다',
        );
      }
    });

    test('둘은 같은 자리라 하나만 걸린다', () async {
      final provider = await maxed();
      await provider.equip('BAG', 'back_backpack_navy');
      await provider.equip('BAG', 'bag_waist_pouch');

      expect(provider.equipped['BAG'], 'bag_waist_pouch');
      expect(
        provider.layers.where((layer) => layer.slot == 'BAG'),
        hasLength(1),
      );
    });

    test('그려지는 순서가 실제로 배낭 · 개구리 · 앞가방이다', () async {
      // 층 번호만 보면 정렬이 틀렸어도 통과한다. 목록에 놓인 차례로 본다.
      final back = await maxed();
      await back.equip('BAG', 'back_backpack_canvas');
      final backIndex = back.layers
          .indexWhere((layer) => layer.itemKey == 'back_backpack_canvas');
      final backBase = back.layers.indexWhere((layer) => layer.isBase);
      expect(backIndex, lessThan(backBase));

      final front = await maxed();
      await front.equip('BAG', 'bag_crossbody_satchel');
      final frontIndex = front.layers
          .indexWhere((layer) => layer.itemKey == 'bag_crossbody_satchel');
      final frontBase = front.layers.indexWhere((layer) => layer.isBase);
      expect(frontIndex, greaterThan(frontBase));
    });
  });

  group('무대에 깔 배경', () {
    // 옷장 탭의 무대는 배경 파츠 한 장을 개구리 사각형에서 꺼내 화면 전체로
    // 편다. 512 정사각형이 둥근 사각형에 갇혀 있으면 개구리가 선 무대가 아니라
    // 벽에 걸린 사진 한 장으로 읽히고, 무대가 깔아 둔 조명과 바닥 그림자를
    // 그 그림이 통째로 덮어 버린다.
    test('가장 뒤에 그려지는 자리의 것을 무대로 내보낸다', () async {
      final provider = await maxed();

      expect(provider.stageBackdrop?.itemKey, 'bg_space');
      expect(provider.stageBackdrop?.slot, 'BACKGROUND');
    });

    test('배경을 안 걸치면 없다', () async {
      final provider = await maxed();
      await provider.unequipAll();

      expect(provider.stageBackdrop, isNull);
      // 뺄 것이 없으면 층이 하나도 안 줄어든다. 모델에 == 이 없어서 목록끼리
      // 견주지 않고 길이로 본다.
      expect(provider.layersOnStage.length, provider.layers.length);
    });

    test('개구리에게는 배경 한 장만 빠진 층들이 간다', () async {
      final provider = await maxed();

      final onStage = provider.layersOnStage;
      expect(onStage.length, provider.layers.length - 1);
      expect(onStage.any((layer) => layer.slot == 'BACKGROUND'), isFalse);
    });

    test('배낭은 개구리와 함께 남는다', () async {
      // 배낭도 개구리보다 뒤에 그려지지만 개구리 몸에 맞춰 그린 그림이다.
      // 무대로 내보내면 자리가 어긋난다. layersWithoutBackdrop 과 다른 점이다.
      final provider = await maxed();
      await provider.equip('BAG', 'back_backpack_canvas');

      expect(
        provider.layersOnStage
            .any((layer) => layer.itemKey == 'back_backpack_canvas'),
        isTrue,
      );
      expect(
        provider.layersWithoutBackdrop
            .any((layer) => layer.itemKey == 'back_backpack_canvas'),
        isFalse,
      );
    });
  });

  group('계약 픽스처', () {
    // 서버가 이 모양으로 내려준다는 전제를 여기서 잠근다. 이 표가 어긋나면
    // 위의 테스트들이 통째로 다른 것을 보게 된다.
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

    test('레벨로 안 열리는 아이템은 하나도 없다', () async {
      // 예전에는 절반 넘게 "미션 보상"이라 레벨을 올려도 안 열렸다. 지금은
      // 예순셋이 전부 어느 능력치엔가 매달려 있다.
      final provider = await maxed();

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

/// 보낸 것과 **다른** 차림을 돌려주는 서버.
///
/// 한 요청 안에서 둘이 부딪히면 어느 쪽을 남길지는 서버가 정한다(뒤에 깔리는
/// 자리가 남는다). 앱의 겹침 규칙과 결과가 갈릴 수 있어서, 그때 응답을 따르는지
/// 보려고 둔다.
class _RewritingCosmeticService extends FakeCosmeticService {
  _RewritingCosmeticService({
    required super.catalog,
    required this.rewritten,
    required this.unequipped,
  });

  final Map<String, String> rewritten;
  final List<String> unequipped;

  @override
  Future<CosmeticEquipResultModel?> equipAll(
    Map<String, String> equipped,
  ) async {
    equipAllRequests.add(Map<String, String>.from(equipped));
    this.equipped = Map<String, String>.from(rewritten);
    return CosmeticEquipResultModel(
      equipped: Map<String, String>.from(rewritten),
      unequippedSlots: unequipped,
    );
  }
}
