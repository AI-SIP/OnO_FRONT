import 'package:flutter/foundation.dart';

import '../Model/Cosmetic/CosmeticItemModel.dart';
import '../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../Model/Cosmetic/CosmeticSlotModel.dart';
import '../Screen/Cosmetic/Mock/CosmeticMockData.dart';

/// 개구리 치장(옷장)을 들고 있는 프로바이더다.
///
/// **지금은 서버를 타지 않는다.** 화면 시안을 보기 위한 더미라서 카탈로그는
/// [CosmeticMockData] 에서 읽고, 무엇을 입고 있는지는 메모리에만 있다. 앱을 끄면
/// 사라진다.
///
/// 나중에 백엔드가 붙으면 [CosmeticMockData.rawResponse] 자리에 실제 응답을
/// 넣고, 장착 메서드에서 서버 호출을 더하면 된다. 화면은 [layers] 와
/// [equipped] 만 보고 있어서 그 위쪽은 바뀌지 않는다.
class CosmeticProvider with ChangeNotifier {
  CosmeticProvider({int mockLevel = CosmeticMockData.maxLevel})
      : _level = _clampLevel(mockLevel) {
    _equipped = _presetFor(_level);
  }

  /// 카탈로그. 더미라서 한 번 만들어 두고 계속 쓴다.
  final CosmeticLoadoutModel _catalog = CosmeticMockData.loadout;

  /// 지금 보고 있는 레벨. 시안에서는 슬라이더로 사람이 직접 바꾼다.
  int _level;

  /// 지금 걸려 있는 것. 슬롯 키 → 아이템 키.
  Map<String, String> _equipped = const {};

  /// 사람이 한 번이라도 직접 갈아입었는지.
  ///
  /// 아직 안 만졌으면 첫 차림을 계속 다시 맞춘다. 슬라이더를 훑을 때 그 레벨의
  /// 사람이 처음 보게 될 모습이 나와야 하기 때문이다. 한 번 만진 뒤에는 고른
  /// 것을 덮지 않고 레벨이 모자라져 못 쓰게 된 것만 내린다.
  bool _touched = false;

  /// 마지막 실패 문구. 화면이 읽고 나면 [consumeFailure] 로 비운다.
  String? _lastFailureMessage;

  /// **디버그 전용.** 켜면 잠긴 것까지 전부 입어 볼 수 있다.
  ///
  /// 시안에서 레벨로 열리는 것은 서른다섯 중 열여섯뿐이고, 나머지 열아홉은
  /// 미션 보상이라 슬라이더를 끝까지 올려도 걸리지 않는다. 그러면 디자인을
  /// 볼 수 없는 아이템이 절반을 넘는다. 그것만 풀어 주는 스위치다.
  ///
  /// 켜고 끄는 것으로 입고 있던 것이 달라지지는 않는다. 끌 때 못 가지게 된
  /// 것만 내린다.
  bool _unlockAll = false;

  // ── 읽기 ────────────────────────────────────────────────────────────

  /// 지금 보고 있는 레벨.
  int get level => _level;

  /// 더미가 다룰 수 있는 가장 높은 레벨.
  int get maxLevel => CosmeticMockData.maxLevel;

  /// 걸 수 있는 자리들. 옷장 탭 순서가 이 순서다.
  List<CosmeticSlotModel> get slots => _catalog.slots;

  /// 아이템 전부. `owned` 는 지금 레벨 기준으로 매겨져 있다.
  List<CosmeticItemModel> get items => loadout.items;

  /// 지금 걸려 있는 것. 슬롯 키 → 아이템 키.
  Map<String, String> get equipped =>
      Map<String, String>.unmodifiable(_equipped);

  /// 지금 차림. `owned` 와 `equipped` 가 지금 상태로 채워져 있다.
  CosmeticLoadoutModel get loadout => _loadoutAt(_level, _equipped);

  /// 개구리를 그릴 층들. 뒤에서 앞 순서다. [FrogCharacter] 에 그대로 넘긴다.
  List<CosmeticLayerModel> get layers => loadout.resolveLayers();

  /// 그 레벨의 **첫 차림**. 자리마다 가장 늦게 열린 것을 하나씩 걸친 모습이다.
  ///
  /// 옷장을 한 번도 안 연 사람이 보는 모습이고, 조합 검수 화면도 이걸 쓴다.
  List<CosmeticLayerModel> layersAtLevel(int level) {
    final clamped = _clampLevel(level);
    return _loadoutAt(clamped, _presetFor(clamped)).resolveLayers();
  }

  /// **지금 차림 위에** 아이템 몇 개를 더 얹은 층들.
  ///
  /// 레벨업 연출이 "방금 열린 것을 입어 보는" 모습을 그릴 때 쓴다. 자동으로
  /// 입혀 주는 것이 없으니 기준은 그 레벨의 정해진 차림이 아니라 지금 이
  /// 사람이 입고 있는 모습이어야 한다.
  List<CosmeticLayerModel> layersWith(Iterable<CosmeticItemModel> extra) {
    final next = Map<String, String>.from(_equipped);
    for (final item in extra) {
      next[item.slot] = item.itemKey;
    }
    return _loadoutAt(_level, next).resolveLayers();
  }

  /// 이 슬롯에 들어가는 아이템들. 카탈로그 순서를 지킨다.
  List<CosmeticItemModel> itemsOfSlot(String slot) => loadout.itemsOfSlot(slot);

  /// 이 세트에 묶인 아이템들.
  List<CosmeticItemModel> itemsOfSet(String setId) => loadout.itemsOfSet(setId);

  /// 이 슬롯에 지금 걸려 있는 아이템 키. 없으면 null.
  String? equippedItemKeyOf(String slot) => _equipped[slot];

  /// 아이템 키로 아이템을 찾는다. 없으면 null.
  CosmeticItemModel? itemOf(String? itemKey) => loadout.itemOf(itemKey);

  /// 지금 레벨에서 가지고 있는지.
  bool isOwned(String itemKey) {
    final item = _catalog.itemOf(itemKey);
    return item != null && _ownsAt(item, _level);
  }

  /// 디버그 전용 전체 해금이 켜져 있는지.
  bool get unlockAll => _unlockAll;

  /// 그 레벨에서 이 아이템을 쓸 수 있는지. 전체 해금이 켜져 있으면 늘 참이다.
  bool _ownsAt(CosmeticItemModel item, int level) =>
      _unlockAll || item.isUnlockedAt(level);

  /// 그 레벨에서 **새로** 열리는 아이템들. 레벨업 연출에 쓴다.
  List<CosmeticItemModel> unlockedAt(int level) => [
        for (final item in _catalog.items)
          if (item.requiredLevel == level) item,
      ];

  String? get lastFailureMessage => _lastFailureMessage;

  // ── 쓰기 ────────────────────────────────────────────────────────────

  /// 더미 레벨을 바꾼다. 시안의 레벨 슬라이더가 부른다.
  ///
  /// 아직 한 번도 갈아입지 않았으면 그 레벨의 기본 차림으로 다시 맞춘다.
  /// 이미 갈아입었으면 사람이 고른 것을 두되, 레벨이 내려가 못 쓰게 된 것은
  /// 내린다. 못 가진 것을 입고 있는 모습이 더 이상하다.
  void setMockLevel(int level) {
    final next = _clampLevel(level);
    if (next == _level) return;

    _level = next;
    _equipped = _touched ? _pruneLocked(_equipped, next) : _presetFor(next);
    notifyListeners();
  }

  /// **디버그 전용.** 잠긴 아이템까지 전부 입어 볼 수 있게 하거나 되돌린다.
  ///
  /// 끌 때는 그 사이에 걸어 둔 잠긴 것들을 내린다. 안 내리면 못 가진 것을
  /// 입고 있는 모습이 남는다.
  void setUnlockAll(bool value) {
    if (_unlockAll == value) return;

    _unlockAll = value;
    if (!value) {
      _equipped = _pruneLocked(_equipped, _level);
    }
    notifyListeners();
  }

  /// 한 자리에 아이템을 건다. 못 가진 것은 걸리지 않는다.
  void equip(String slot, String itemKey) {
    final item = _catalog.itemOf(itemKey);
    if (item == null || item.slot != slot) {
      _fail('지금은 쓸 수 없는 아이템이에요.');
      return;
    }
    if (!_ownsAt(item, _level)) {
      _fail(_lockedMessage(item));
      return;
    }

    _touched = true;
    _equipped = _applyEquip(_equipped, slot: slot, itemKey: itemKey);
    _lastFailureMessage = null;
    notifyListeners();
  }

  /// 한 자리를 비운다.
  void unequip(String slot) {
    if (!_equipped.containsKey(slot)) return;

    _touched = true;
    _equipped = _applyEquip(_equipped, slot: slot, itemKey: null);
    _lastFailureMessage = null;
    notifyListeners();
  }

  /// 세트를 통째로 건다.
  ///
  /// 세트 안에 못 가진 것이 섞여 있으면 하나도 걸지 않는다. 절반만 입혀 두면
  /// 무엇이 모자란지 알 수 없다.
  void equipSet(String setId) {
    final members = _catalog.itemsOfSet(setId);
    if (members.isEmpty) {
      _fail('지금은 쓸 수 없는 세트예요.');
      return;
    }

    final locked = [
      for (final item in members)
        if (!_ownsAt(item, _level)) item,
    ];
    if (locked.isNotEmpty) {
      _fail(_lockedMessage(locked.first, others: locked));
      return;
    }

    var next = _equipped;
    for (final item in members) {
      next = _applyEquip(next, slot: item.slot, itemKey: item.itemKey);
    }

    _touched = true;
    _equipped = next;
    _lastFailureMessage = null;
    notifyListeners();
  }

  /// 지금 레벨의 기본 차림으로 되돌린다.
  void unequipAll() {
    _touched = true;
    _equipped = const {};
    _lastFailureMessage = null;
    notifyListeners();
  }

  /// 실패 문구를 한 번 꺼내 쓰고 비운다. 같은 말이 두 번 뜨는 것을 막는다.
  String? consumeFailure() {
    final message = _lastFailureMessage;
    _lastFailureMessage = null;
    return message;
  }

  /// 들고 있는 것을 전부 비운다. 로그아웃 때 부른다.
  void clear() {
    _level = CosmeticMockData.maxLevel;
    _touched = false;
    _equipped = _presetFor(_level);
    _lastFailureMessage = null;
    notifyListeners();
  }

  // ── 안쪽 ────────────────────────────────────────────────────────────

  /// 그 레벨에서의 차림 하나를 만든다. `owned` 를 레벨로 다시 매긴다.
  CosmeticLoadoutModel _loadoutAt(int level, Map<String, String> equipped) {
    return CosmeticLoadoutModel(
      baseImageUrl: _catalog.baseImageUrl,
      slots: _catalog.slots,
      items: [
        for (final item in _catalog.items)
          item.copyWith(owned: _ownsAt(item, level)),
      ],
      equipped: Map<String, String>.unmodifiable(equipped),
      baseLayerOrder: _catalog.baseLayerOrder,
    );
  }

  /// 그 레벨의 기본 차림.
  ///
  /// 슬롯마다 **열려 있는 것 중 가장 늦게 열린 것**을 입는다. 레벨을 올릴수록
  /// 새로 얻은 것이 바로 보이는 쪽이 해금이 쌓이는 느낌을 준다.
  /// 옷장을 한 번도 안 연 사람에게 입혀 줄 한 벌.
  ///
  /// 자리마다 **가장 늦게 열리는 것**을 고른다. 늦게 열릴수록 그 사람이
  /// 여기까지 왔다는 표시라서, 레벨이 높은 사람이 맨 개구리로 보이지 않는다.
  ///
  /// **처음 만들 때 한 번만 쓴다.** 레벨이 바뀌어도 다시 계산하지 않는다.
  /// 매번 다시 맞추면 사람이 골라 둔 것을 앱이 덮어쓰게 된다.
  Map<String, String> _presetFor(int level) {
    final picked = <String, CosmeticItemModel>{};

    for (final item in _catalog.items) {
      if (!item.isUnlockedAt(level)) continue;

      final current = picked[item.slot];
      if (current == null ||
          (item.requiredLevel ?? 0) > (current.requiredLevel ?? 0)) {
        picked[item.slot] = item;
      }
    }

    return Map<String, String>.unmodifiable({
      for (final entry in picked.entries) entry.key: entry.value.itemKey,
    });
  }

  /// 그 레벨에서 못 쓰게 된 것을 내린다.
  Map<String, String> _pruneLocked(Map<String, String> equipped, int level) {
    final next = <String, String>{};
    equipped.forEach((slot, itemKey) {
      final item = _catalog.itemOf(itemKey);
      if (item != null && _ownsAt(item, level)) {
        next[slot] = itemKey;
      }
    });
    return Map<String, String>.unmodifiable(next);
  }

  /// 걸고 벗기는 것을 반영한다. 같이 걸 수 없다고 한 것은 함께 내린다.
  Map<String, String> _applyEquip(
    Map<String, String> equipped, {
    required String slot,
    String? itemKey,
  }) {
    final next = Map<String, String>.from(equipped);

    if (itemKey == null) {
      next.remove(slot);
      return Map<String, String>.unmodifiable(next);
    }

    next[slot] = itemKey;

    // 서로 한쪽에만 적어 두는 경우가 있어서 양쪽 방향을 모두 본다.
    final conflicts =
        _catalog.itemOf(itemKey)?.conflictsWith ?? const <String>[];
    for (final entry in next.entries.toList()) {
      if (entry.key == slot) continue;
      final other = _catalog.itemOf(entry.value);
      if (other == null) continue;

      final collides = conflicts.contains(other.itemKey) ||
          other.conflictsWith.contains(itemKey);
      if (collides) next.remove(entry.key);
    }

    return Map<String, String>.unmodifiable(next);
  }

  /// 아직 못 쓰는 이유를 사람 말로 적는다.
  ///
  /// 레벨로 열리는 것이면 몇 레벨부터인지, 미션 보상이면 그렇다고 말한다.
  /// 미션 보상에 "Lv.0 부터"라고 쓰면 없는 규칙을 알려 주는 셈이 된다.
  String _lockedMessage(
    CosmeticItemModel item, {
    List<CosmeticItemModel> others = const [],
  }) {
    var required = item.requiredLevel;
    for (final other in others) {
      final level = other.requiredLevel;
      if (level == null) return '미션을 마치면 받을 수 있어요.';
      if (required == null || level > required) required = level;
    }
    if (required == null) return '미션을 마치면 받을 수 있어요.';
    return 'Lv.$required 부터 쓸 수 있어요.';
  }

  void _fail(String message) {
    _lastFailureMessage = message;
    notifyListeners();
  }

  static int _clampLevel(int level) {
    if (level < 1) return 1;
    if (level > CosmeticMockData.maxLevel) return CosmeticMockData.maxLevel;
    return level;
  }
}
