import 'package:flutter/foundation.dart';

import '../Model/Cosmetic/CosmeticAbilityLevels.dart';
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
///
/// 해금 기준이 총 학습 레벨 하나에서 **능력치별**로 바뀌어서, 이 프로바이더가
/// 들고 있는 것도 레벨 하나가 아니라 [CosmeticAbilityLevels] 다섯 묶음이다.
class CosmeticProvider with ChangeNotifier {
  CosmeticProvider({CosmeticAbilityLevels? mockLevels})
      : _levels = mockLevels ?? CosmeticMockData.demoLevels {
    _equipped = _presetFor(_levels);
  }

  /// 카탈로그. 더미라서 한 번 만들어 두고 계속 쓴다.
  final CosmeticLoadoutModel _catalog = CosmeticMockData.loadout;

  /// 지금 보고 있는 능력치 레벨 다섯. 시안에서는 디버그 패널로 사람이 옮긴다.
  CosmeticAbilityLevels _levels;

  /// 사람이 디버그 패널에서 레벨을 한 번이라도 옮겼는지.
  ///
  /// 옮기기 전까지는 [CosmeticMockData.demoLevels] 라서 "이 사람의 레벨"이라고
  /// 말할 수 없다. 옷장 탭의 스탯창이 이 값을 보고, 옮긴 뒤에만 더미 레벨을
  /// 따라간다. 그 전에는 서버가 준 진짜 레벨을 그대로 보여 준다.
  bool _levelsTouched = false;

  /// 지금 걸려 있는 것. 슬롯 키 → 아이템 키.
  Map<String, String> _equipped = const {};

  /// 사람이 한 번이라도 직접 갈아입었는지.
  ///
  /// 아직 안 만졌으면 첫 차림을 계속 다시 맞춘다. 레벨을 훑을 때 그 레벨의
  /// 사람이 처음 보게 될 모습이 나와야 하기 때문이다. 한 번 만진 뒤에는 고른
  /// 것을 덮지 않고 레벨이 모자라져 못 쓰게 된 것만 내린다.
  bool _touched = false;

  /// 마지막 실패 문구. 화면이 읽고 나면 [consumeFailure] 로 비운다.
  String? _lastFailureMessage;

  /// **디버그 전용.** 켜면 잠긴 것까지 전부 입어 볼 수 있다.
  ///
  /// 능력치 넷을 골고루 올려 둔 사람은 드물어서, 시안의 기본 레벨에서는
  /// 쉰다섯 중 절반쯤만 열린다. 디자인을 봐야 하는 자리에서는 잠긴 것도 입어
  /// 볼 수 있어야 해서 그것만 풀어 주는 스위치를 둔다.
  ///
  /// 켜고 끄는 것으로 입고 있던 것이 달라지지는 않는다. 끌 때 못 가지게 된
  /// 것만 내린다.
  bool _unlockAll = false;

  // ── 읽기 ────────────────────────────────────────────────────────────

  /// 지금 보고 있는 능력치 레벨 다섯.
  CosmeticAbilityLevels get levels => _levels;

  /// 디버그 패널에서 레벨을 옮긴 적이 있는지.
  bool get levelsTouched => _levelsTouched;

  /// 이 능력치의 지금 레벨. null 이면 총 학습 레벨이다.
  int levelOf(CosmeticAbility? ability) => _levels.levelOf(ability);

  /// 걸 수 있는 자리들. 옷장 탭 순서가 이 순서다.
  List<CosmeticSlotModel> get slots => _catalog.slots;

  /// 아이템 전부. `owned` 는 지금 레벨 기준으로 매겨져 있다.
  List<CosmeticItemModel> get items => loadout.items;

  /// 지금 걸려 있는 것. 슬롯 키 → 아이템 키.
  Map<String, String> get equipped =>
      Map<String, String>.unmodifiable(_equipped);

  /// 지금 차림. `owned` 와 `equipped` 가 지금 상태로 채워져 있다.
  CosmeticLoadoutModel get loadout => _loadoutAt(_levels, _equipped);

  /// 개구리를 그릴 층들. 뒤에서 앞 순서다. [FrogCharacter] 에 그대로 넘긴다.
  List<CosmeticLayerModel> get layers => loadout.resolveLayers();

  /// 배경을 뺀 층들. 개구리만 투명한 바탕에 남는다.
  ///
  /// 달력 도장이나 복습 완료 화면처럼 **이미 바탕이 있는 자리**에 쓴다. 거기에
  /// 배경 파츠까지 깔면 네모난 판이 하나 더 생겨서, 개구리가 아니라 카드가
  /// 놓인 것처럼 보인다.
  ///
  /// 개구리 본체보다 뒤에 그려지는 것(배경, 등짐)을 걷어 낸다. 슬롯 키를 박아
  /// 두지 않는 이유는 자리 이름이 서버가 정하는 값이기 때문이다. 그리는 순서만
  /// 보면 된다.
  List<CosmeticLayerModel> get layersWithoutBackdrop {
    final all = layers;
    final baseOrder = all
        .where((layer) => layer.isBase)
        .map((layer) => layer.layerOrder)
        .firstOrNull;
    if (baseOrder == null) return all;
    return [
      for (final layer in all)
        if (layer.isBase || layer.layerOrder >= baseOrder) layer,
    ];
  }

  /// 다섯 레벨을 같은 값으로 놓았을 때의 **첫 차림**.
  ///
  /// 조합 검수 화면과 레벨업 연출이 "레벨을 올릴수록 개구리가 어떻게 달라지나"
  /// 를 한 축으로 훑을 때 쓴다. 능력치가 갈라진 뒤로 이 한 축은 실제 사용자의
  /// 모습이 아니라 **눈으로 훑기 위한 단면**이다.
  List<CosmeticLayerModel> layersAtLevel(int level) =>
      layersAtLevels(CosmeticAbilityLevels.uniform(level));

  /// 그 레벨들에서의 첫 차림. 자리마다 가장 늦게 열린 것을 하나씩 걸친 모습이다.
  List<CosmeticLayerModel> layersAtLevels(CosmeticAbilityLevels levels) =>
      _loadoutAt(levels, _presetFor(levels)).resolveLayers();

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
    return _loadoutAt(_levels, next).resolveLayers();
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
    return item != null && _ownsAt(item, _levels);
  }

  /// 디버그 전용 전체 해금이 켜져 있는지.
  bool get unlockAll => _unlockAll;

  /// 그 레벨들에서 이 아이템을 쓸 수 있는지. 전체 해금이 켜져 있으면 늘 참이다.
  bool _ownsAt(CosmeticItemModel item, CosmeticAbilityLevels levels) =>
      _unlockAll || item.isUnlockedAt(levels);

  /// **지금 레벨에서 막 열린** 아이템들. 옷장 격자의 `NEW` 표시가 쓴다.
  ///
  /// 제 능력치의 레벨과 필요 레벨이 딱 맞는 것들이다. 능력치가 갈라진 뒤로는
  /// "이번 레벨"이 하나가 아니라 다섯이라, 넷 중 어느 쪽을 올렸든 그쪽에서
  /// 막 열린 것에 표시가 붙는다.
  List<CosmeticItemModel> get justUnlocked => [
        for (final item in _catalog.items)
          if (item.requiredLevel == _levels.levelOf(item.requiredAbility)) item,
      ];

  /// 그 **총 학습 레벨**에서 새로 열리는 아이템들. 레벨업 연출에 쓴다.
  ///
  /// 레벨업 축하는 총 학습 레벨이 오를 때 뜬다. 그래서 여기서 세는 것도
  /// 능력치가 안 붙은(총 학습 기준) 아이템뿐이다. 출석이나 복습으로 열리는
  /// 것은 그쪽 레벨이 오를 때 열리는 것이라 이 축하의 몫이 아니다.
  List<CosmeticItemModel> unlockedAtTotalStudyLevel(int level) => [
        for (final item in _catalog.items)
          if (item.requiredAbility == null && item.requiredLevel == level) item,
      ];

  /// 총 학습 레벨의 끝. 레벨업 연출의 게이지 오른쪽 끝이다.
  int get maxTotalStudyLevel => CosmeticAbilityLevels.maxTotalStudy;

  String? get lastFailureMessage => _lastFailureMessage;

  // ── 시착 ────────────────────────────────────────────────────────────
  //
  // 꾸미기 화면은 이것저것 걸쳐 보다가 저장을 눌러야 반영되는 시착 방식이다.
  // **시착 중인 차림은 화면이 들고 있고 프로바이더는 모른다.** 하단 탭 아이콘과
  // 프로필 사진이 이 프로바이더를 보고 있어서, 입어 보는 동안 그것들까지 같이
  // 바뀌면 안 되기 때문이다.
  //
  // 그래서 아래 넷은 전부 **지금 차림을 건드리지 않는다.** 화면이 들고 있는
  // 차림 하나를 넘기면 규칙만 빌려 주고 결과를 돌려준다. 규칙(충돌 처리, 잠금
  // 판정, 잠긴 이유)이 화면으로 새어 나가면 두 군데가 서로 다른 말을 하게 된다.

  /// 이 차림을 그리면 어떤 층이 되는지. [layers] 의 시착판이다.
  List<CosmeticLayerModel> layersOf(Map<String, String> equipped) =>
      _loadoutAt(_levels, equipped).resolveLayers();

  /// 이 차림에 하나를 걸거나([itemKey] 를 주거나) 벗긴(null) 결과.
  ///
  /// 같이 걸 수 없다고 한 것은 함께 내려 준다. 실제로 거는 [equip] 과 같은
  /// 규칙을 쓴다.
  Map<String, String> previewEquip(
    Map<String, String> equipped, {
    required String slot,
    String? itemKey,
  }) {
    return _applyEquip(equipped, slot: slot, itemKey: itemKey);
  }

  /// 이 차림에서 지금 레벨에 못 쓰는 것을 걷어 낸 것.
  ///
  /// 시착하는 동안 레벨을 내리거나 전체 해금을 끄면 방금 입어 본 것이 못 쓰는
  /// 것이 된다. 화면은 매번 이걸 통과시킨 차림을 그린다.
  Map<String, String> usableOf(Map<String, String> equipped) =>
      _pruneLocked(equipped, _levels);

  /// 이 아이템을 아직 못 쓰는 이유. 쓸 수 있으면 null 이다.
  String? lockReasonOf(String itemKey) {
    final item = _catalog.itemOf(itemKey);
    if (item == null) return '지금은 쓸 수 없는 아이템이에요.';
    if (_ownsAt(item, _levels)) return null;
    return _lockedMessage(item);
  }

  // ── 쓰기 ────────────────────────────────────────────────────────────

  /// **디버그 전용.** 능력치 하나의 더미 레벨을 바꾼다. null 이면 총 학습이다.
  void setMockLevel(CosmeticAbility? ability, int level) {
    setMockLevels(_levels.withLevel(ability, level));
  }

  /// **디버그 전용.** 더미 레벨 다섯을 통째로 바꾼다.
  ///
  /// 아직 한 번도 갈아입지 않았으면 그 레벨의 기본 차림으로 다시 맞춘다.
  /// 이미 갈아입었으면 사람이 고른 것을 두되, 레벨이 내려가 못 쓰게 된 것은
  /// 내린다. 못 가진 것을 입고 있는 모습이 더 이상하다.
  void setMockLevels(CosmeticAbilityLevels next) {
    _levelsTouched = true;
    if (next == _levels) return;

    _levels = next;
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
      _equipped = _pruneLocked(_equipped, _levels);
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
    if (!_ownsAt(item, _levels)) {
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
        if (!_ownsAt(item, _levels)) item,
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

  /// 걸친 것을 전부 벗는다.
  void unequipAll() {
    _touched = true;
    _equipped = const {};
    _lastFailureMessage = null;
    notifyListeners();
  }

  /// 시착한 차림을 확정한다. 꾸미기 화면의 **저장** 버튼이 부른다.
  ///
  /// 여기서야 비로소 하단 탭 아이콘과 프로필 사진의 개구리가 바뀐다. 그 사이에
  /// 레벨이 내려가 못 쓰게 된 것이 섞여 있으면 걷어 내고 저장한다.
  void save(Map<String, String> equipped) {
    _touched = true;
    _equipped = _pruneLocked(equipped, _levels);
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
    _levels = CosmeticMockData.demoLevels;
    _levelsTouched = false;
    _touched = false;
    _equipped = _presetFor(_levels);
    _lastFailureMessage = null;
    notifyListeners();
  }

  // ── 안쪽 ────────────────────────────────────────────────────────────

  /// 그 레벨들에서의 차림 하나를 만든다. `owned` 를 레벨로 다시 매긴다.
  CosmeticLoadoutModel _loadoutAt(
    CosmeticAbilityLevels levels,
    Map<String, String> equipped,
  ) {
    return CosmeticLoadoutModel(
      baseImageUrl: _catalog.baseImageUrl,
      slots: _catalog.slots,
      items: [
        for (final item in _catalog.items)
          item.copyWith(owned: _ownsAt(item, levels)),
      ],
      equipped: Map<String, String>.unmodifiable(equipped),
      baseLayerOrder: _catalog.baseLayerOrder,
    );
  }

  /// 그 레벨들에서의 기본 차림.
  ///
  /// 옷장을 한 번도 안 연 사람에게 입혀 줄 한 벌이다. 자리마다 **열려 있는 것
  /// 중 가장 늦게 열리는 것**을 고른다. 늦게 열릴수록 그 사람이 여기까지 왔다는
  /// 표시라서, 레벨이 높은 사람이 맨 개구리로 보이지 않는다.
  ///
  /// 능력치가 갈라진 뒤로 필요 레벨끼리의 비교는 능력치를 가로지른다. 출석
  /// Lv.9 와 총 학습 Lv.8 중 어느 쪽이 "더 멀리 온 것"인지는 정할 수 없지만,
  /// 여기서 정해야 하는 것은 기본 차림 한 벌이라 그 정도면 된다.
  Map<String, String> _presetFor(CosmeticAbilityLevels levels) {
    final picked = <String, CosmeticItemModel>{};

    for (final item in _catalog.items) {
      if (!item.isUnlockedAt(levels)) continue;

      final current = picked[item.slot];
      if (current == null || item.requiredLevel > current.requiredLevel) {
        picked[item.slot] = item;
      }
    }

    return Map<String, String>.unmodifiable({
      for (final entry in picked.entries) entry.key: entry.value.itemKey,
    });
  }

  /// 그 레벨들에서 못 쓰게 된 것을 내린다.
  Map<String, String> _pruneLocked(
    Map<String, String> equipped,
    CosmeticAbilityLevels levels,
  ) {
    final next = <String, String>{};
    equipped.forEach((slot, itemKey) {
      final item = _catalog.itemOf(itemKey);
      if (item != null && _ownsAt(item, levels)) {
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
  /// **무엇을 얼마나 올려야 하는지까지 말한다.** `Lv.9 부터` 만으로는 무엇의
  /// 9 인지 알 수 없어서, 출석을 올려야 하는 것을 복습만 하며 기다리게 된다.
  ///
  /// 세트처럼 여러 개가 한꺼번에 걸리면 **가장 멀리 있는 것**을 말한다. 그것만
  /// 채우면 나머지는 이미 열려 있다.
  String _lockedMessage(
    CosmeticItemModel item, {
    List<CosmeticItemModel> others = const [],
  }) {
    var farthest = item;
    for (final other in others) {
      if (other.remainingLevelsAt(_levels) >
          farthest.remainingLevelsAt(_levels)) {
        farthest = other;
      }
    }
    return '${cosmeticRequirementLabel(farthest)} 부터 쓸 수 있어요.';
  }

  void _fail(String message) {
    _lastFailureMessage = message;
    notifyListeners();
  }
}

/// 이 아이템을 열려면 무엇을 얼마나 올려야 하는지. `출석 Lv.9` 처럼 쓴다.
///
/// 프로바이더의 알림 문구와 화면의 잠금 배지가 같은 말을 쓰게 하려고 한 군데에
/// 둔다. 능력치 이름은 [cosmeticAbilityLabel] 이 정한다.
String cosmeticRequirementLabel(CosmeticItemModel item) =>
    '${cosmeticAbilityLabel(item.requiredAbility)} Lv.${item.requiredLevel}';

/// 능력치 이름. null 이면 총 학습 레벨이다.
///
/// 미션 화면과 스탯창이 쓰는 이름([MissionPalette]) 과 같아야 해서, 그쪽과
/// 어긋나지 않는지는 `test/screen/cosmetic/cosmetic_ability_style_test.dart`
/// 가 잠근다. 여기에 이름을 두는 것은 모델과 프로바이더가 화면 파일을 import
/// 하지 않게 하려는 것이다.
String cosmeticAbilityLabel(CosmeticAbility? ability) => switch (ability) {
      CosmeticAbility.attendance => '출석',
      CosmeticAbility.noteWrite => '오답노트',
      CosmeticAbility.problemPractice => '문제 복습',
      CosmeticAbility.notePractice => '복습 세트',
      null => '총 학습',
    };
