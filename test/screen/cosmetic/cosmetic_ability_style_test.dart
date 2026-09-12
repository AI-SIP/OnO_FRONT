// 능력치를 화면에 어떻게 그리는지 잠근다.
//
// 같은 능력치가 화면마다 다른 색·다른 이름이면 색이 정보를 잃는다. 꾸미기
// 화면의 잠금 배지와 옷장 탭 스탯창과 테마 트랙이 모두 [MissionPalette] 에서
// 가져다 쓰는지, 모델·프로바이더 쪽에 따로 둔 이름이 그것과 어긋나지 않는지를
// 여기서 본다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Model/Cosmetic/CosmeticItemModel.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticAbilityStyle.dart';
import 'package:ono/Screen/Mission/MissionPalette.dart';

CosmeticItemModel _item({
  required int level,
  required CosmeticAbility? ability,
}) {
  return CosmeticItemModel(
    itemKey: 'test_item',
    slot: 'HEAD',
    nameKo: '시험용',
    imageUrl: '',
    requiredLevel: level,
    requiredAbility: ability,
    setId: null,
    conflictsWith: const [],
    owned: false,
  );
}

void main() {
  group('이름', () {
    test('능력치 넷의 이름이 미션 화면과 같다', () {
      // 프로바이더 쪽 이름([cosmeticAbilityLabel])은 모델이 화면 파일을
      // import 하지 않으려고 따로 둔 것이다. 따로 두는 대신 어긋나지 않는지
      // 여기서 잠근다.
      for (final ability in CosmeticAbility.values) {
        expect(
          CosmeticAbilityStyle.labelOf(ability),
          MissionPalette.labelOfKind(CosmeticAbilityStyle.kindOf(ability)),
          reason: ability.key,
        );
      }
    });

    test('능력치가 없으면 총 학습이다', () {
      expect(CosmeticAbilityStyle.labelOf(null), '총 학습');
    });
  });

  group('색', () {
    test('넷은 각자 다른 색이고 총 학습은 그 넷 중 어느 것도 아니다', () {
      final accents = <int>{};
      for (final ability in CosmeticAbility.values) {
        accents.add(CosmeticAbilityStyle.colorsOf(ability).accent.toARGB32());
      }
      expect(accents, hasLength(4));

      final total = CosmeticAbilityStyle.colorsOf(null).accent.toARGB32();
      expect(accents, isNot(contains(total)));
    });

    test('출석은 미션 화면의 출석 색과 같다', () {
      expect(
        CosmeticAbilityStyle.colorsOf(CosmeticAbility.attendance).accent,
        MissionPalette.of(MissionKind.attendance).accent,
      );
    });
  });

  group('조건 문구', () {
    test('무엇을 얼마나 올려야 하는지 적는다', () {
      expect(
        CosmeticAbilityStyle.requirementOf(
          _item(level: 9, ability: CosmeticAbility.attendance),
        ),
        '출석 Lv.9',
      );
      expect(
        CosmeticAbilityStyle.requirementOf(_item(level: 14, ability: null)),
        '총 학습 Lv.14',
      );
    });

    test('프로바이더의 알림 문구와 같은 말을 쓴다', () {
      final item = _item(level: 10, ability: CosmeticAbility.problemPractice);
      expect(
        cosmeticRequirementLabel(item),
        CosmeticAbilityStyle.requirementOf(item),
      );
    });
  });

  group('남은 거리', () {
    test('지금 레벨과 남은 레벨을 같이 적는다', () {
      expect(
        CosmeticAbilityStyle.progressOf(
          _item(level: 14, ability: CosmeticAbility.attendance),
          CosmeticAbilityLevels(attendance: 11),
        ),
        '지금 출석 Lv.11 · 3 레벨 남았어요',
      );
    });

    test('한 칸 남았으면 한 칸 남았다고 말한다', () {
      // 이 한 줄이 "한 번만 더" 를 만든다.
      expect(
        CosmeticAbilityStyle.progressOf(
          _item(level: 14, ability: CosmeticAbility.attendance),
          CosmeticAbilityLevels(attendance: 13),
        ),
        '지금 출석 Lv.13 · 한 레벨만 더!',
      );
    });

    test('이미 열렸으면 남은 레벨을 말하지 않는다', () {
      expect(
        CosmeticAbilityStyle.progressOf(
          _item(level: 3, ability: CosmeticAbility.attendance),
          CosmeticAbilityLevels(attendance: 9),
        ),
        '지금 출석 Lv.9 · 열려 있어요',
      );
    });

    test('다른 능력치를 올려도 남은 거리는 그대로다', () {
      final item = _item(level: 14, ability: CosmeticAbility.attendance);
      final levels = CosmeticAbilityLevels(
        attendance: 11,
        noteWrite: CosmeticAbilityLevels.maxAbility,
        totalStudy: CosmeticAbilityLevels.maxTotalStudy,
      );

      expect(item.remainingLevelsAt(levels), 3);
    });
  });
}
