// 해금표와 더미 카탈로그가 어긋나지 않는지 잠근다.
//
// **표를 여기에 다시 옮겨 적지 않는다.** `docs/치장 시스템/해금표.md` 를 직접
// 읽어서 비교한다. 옮겨 적으면 문서와 테스트와 더미가 셋이 되고, 셋이 되면
// 언젠가 둘씩 짝지어 어긋난다. 문서가 계약이라면 계약서를 읽어야 한다.
//
// 문서를 고치고 더미를 안 고치면 여기서 걸리고, 더미를 고치고 문서를 안 고쳐도
// 여기서 걸린다. 어느 쪽을 먼저 고쳐야 하는지는 문서가 계약이므로 문서다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Screen/Cosmetic/Mock/CosmeticMockData.dart';

/// 해금표 한 줄.
class _TableRow {
  final String itemKey;
  final String slot;
  final int level;

  /// 서버가 쓰는 능력치 값. 총 학습이면 null 이다.
  final CosmeticAbility? ability;

  const _TableRow({
    required this.itemKey,
    required this.slot,
    required this.level,
    required this.ability,
  });

  @override
  String toString() => '$itemKey(${ability?.key ?? '총 학습'} Lv.$level, $slot)';
}

/// 문서 경로. `flutter test` 는 패키지 루트에서 돈다.
const String _docPath = 'docs/치장 시스템/해금표.md';

/// `## 출석 (`ATTENDANCE`)` 에서 백틱 안의 값을 꺼낸다. `-` 면 총 학습이다.
final RegExp _heading = RegExp(r'^##\s+.*?`([^`]+)`');

/// `| 2 | `bg_spring` | BACKGROUND |` 한 줄.
///
/// 표의 머리줄(`| Lv | 아이템 | 자리 |`)과 구분선은 숫자로 시작하지 않아서
/// 저절로 걸러진다.
final RegExp _row = RegExp(
  r'^\|\s*(\d+)\s*\|\s*`([A-Za-z0-9_]+)`\s*\|\s*([A-Z_]+)\s*\|',
);

/// 읽어 둔 해금표. 처음 쓰일 때 한 번만 읽는다.
///
/// `main()` 몸통에서 바로 읽지 않는 이유는, 파일이 없거나 표가 깨졌을 때
/// 테스트 하나가 실패하는 것과 파일 전체가 로드에 실패하는 것이 다르기
/// 때문이다. 뒤쪽은 무엇이 왜 틀렸는지 안 보인다.
final List<_TableRow> _table = _readTable();

/// 문서를 읽어 표 전체를 한 목록으로 편다.
List<_TableRow> _readTable() {
  final file = File(_docPath);
  if (!file.existsSync()) {
    throw StateError('$_docPath 가 없다. 해금표가 곧 계약이라 문서 없이는 이 테스트가 의미가 없다.');
  }

  final rows = <_TableRow>[];
  CosmeticAbility? ability;
  var inSection = false;

  for (final line in file.readAsLinesSync()) {
    final heading = _heading.firstMatch(line);
    if (heading != null) {
      final key = heading.group(1)!;
      ability = key == '-' ? null : CosmeticAbility.fromKeyOrNull(key);
      // `-` 가 아닌데 못 알아들은 값이면 문서가 앱보다 앞서 나갔다는 뜻이다.
      if (key != '-' && ability == null) {
        throw StateError('해금표가 모르는 능력치를 쓴다: $key');
      }
      inSection = true;
      continue;
    }

    if (!inSection) continue;

    final match = _row.firstMatch(line);
    if (match == null) continue;

    rows.add(
      _TableRow(
        level: int.parse(match.group(1)!),
        itemKey: match.group(2)!,
        slot: match.group(3)!,
        ability: ability,
      ),
    );
  }

  return rows;
}

void main() {
  final items = CosmeticMockData.loadout.items;

  group('해금표 읽기', () {
    test('표에서 예순세 줄을 읽었다', () {
      // 이 숫자가 틀리면 아래 비교가 통째로 무의미해진다. 파서가 표를 제대로
      // 훑었는지부터 확인한다. 쉰다섯에서 예순셋이 된 것은 프로필 테두리
      // 여덟이 들어와서다.
      expect(_table, hasLength(63));
    });

    test('같은 아이템이 두 번 적혀 있지 않다', () {
      final keys = <String>{};
      for (final row in _table) {
        expect(keys.add(row.itemKey), isTrue,
            reason: '${row.itemKey} 가 두 번 있다');
      }
    });

    test('능력치 넷과 총 학습이 모두 쓰였다', () {
      final abilities = {for (final row in _table) row.ability};
      expect(abilities, hasLength(5));
      expect(abilities, contains(null));
      for (final ability in CosmeticAbility.values) {
        expect(abilities, contains(ability));
      }
    });
  });

  group('더미가 해금표를 따른다', () {
    test('개수가 같다', () {
      expect(items, hasLength(_table.length));
    });

    test('자리와 능력치와 레벨이 표와 같다', () {
      final byKey = {for (final item in items) item.itemKey: item};

      for (final row in _table) {
        final item = byKey[row.itemKey];
        expect(item, isNotNull, reason: '더미에 ${row.itemKey} 가 없다');
        if (item == null) continue;

        expect(item.slot, row.slot, reason: '$row 의 자리가 다르다');
        expect(item.requiredAbility, row.ability, reason: '$row 의 능력치가 다르다');
        expect(item.requiredLevel, row.level, reason: '$row 의 레벨이 다르다');
      }
    });

    test('표에 없는 아이템이 더미에 끼어 있지 않다', () {
      final tableKeys = {for (final row in _table) row.itemKey};

      for (final item in items) {
        expect(
          tableKeys,
          contains(item.itemKey),
          reason: '${item.itemKey} 는 해금표에 없다',
        );
      }
    });

    test('능력치 넷은 15, 총 학습은 20 을 넘지 않는다', () {
      for (final item in items) {
        final max = CosmeticAbilityLevels.maxLevelOf(item.requiredAbility);
        expect(
          item.requiredLevel,
          lessThanOrEqualTo(max),
          reason: '${item.itemKey} 가 상한을 넘는다',
        );
        expect(
          item.requiredLevel,
          greaterThan(CosmeticAbilityLevels.minLevel),
          reason: '${item.itemKey} 가 Lv.1 에 열린다. 시작부터 가진 것은 해금이 아니다',
        );
      }
    });
  });

  group('서버 응답 계약', () {
    test('rawResponse 가 백엔드가 확정한 모양 그대로다', () {
      final raw = CosmeticMockData.rawResponse;

      expect(
        raw.keys.toSet(),
        {'baseImageUrl', 'baseLayerOrder', 'slots', 'items', 'equipped'},
      );

      final slots = raw['slots']! as List<Map<String, Object?>>;
      for (final slot in slots) {
        // composited 는 개구리 합성에 들어가는 자리인지다. FRAME 이 생기면서
        // 계약에 들어왔다.
        expect(
          slot.keys.toSet(),
          {'slot', 'layerOrder', 'nameKo', 'composited'},
        );
      }

      final rawItems = raw['items']! as List<Map<String, Object?>>;
      for (final item in rawItems) {
        expect(
          item.keys.toSet(),
          {
            'itemKey',
            'slot',
            'nameKo',
            'imageUrl',
            'requiredLevel',
            'requiredAbility',
            'setId',
            'setNameKo',
            'conflictsWith',
            'fullBody',
            // 자리의 그리는 층을 덮어쓸 때만 값이 있다. 가방 자리가 쓴다.
            'layerOrder',
          },
          reason: '${item['itemKey']} 의 필드가 계약과 다르다',
        );
      }
    });

    test('가방은 자리 하나뿐이고 배낭만 층을 덮어쓴다', () {
      // 등에 메는 배낭과 앞으로 메는 가방이 한 자리다. 자리는 옷 위(450)에
      // 그리고, 배낭 둘만 아이템이 층을 개구리 뒤(200)로 덮어쓴다. 이 값이
      // 빠지면 배낭이 개구리 앞으로 나와 몸통 위에 얹힌다.
      final catalog = CosmeticMockData.loadout;

      expect(catalog.slots.any((s) => s.slot == 'BACK'), isFalse);
      final bag = catalog.slots.firstWhere((s) => s.slot == 'BAG');
      expect(bag.nameKo, '가방');
      expect(bag.layerOrder, 450);

      for (final item in catalog.itemsOfSlot('BAG')) {
        expect(
          item.layerOrder,
          item.itemKey.startsWith('back_') ? 200 : isNull,
          reason: item.itemKey,
        );
      }
    });
  });
}
