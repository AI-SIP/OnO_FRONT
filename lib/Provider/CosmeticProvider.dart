import 'package:flutter/foundation.dart';

import '../Model/Cosmetic/CosmeticAbilityLevels.dart';
import '../Model/Cosmetic/CosmeticEquipResultModel.dart';
import '../Model/Cosmetic/CosmeticItemModel.dart';
import '../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../Model/Cosmetic/CosmeticSlotModel.dart';
import '../Model/User/UserInfoModel.dart';
import '../Module/Cosmetic/CosmeticAssetGuard.dart';
import '../Module/Debug/DebugCosmeticPreset.dart';
import '../Module/Debug/DebugLevels.dart';
import '../Service/Api/Cosmetic/CosmeticService.dart';

/// 옷장을 아직 받았는지.
enum CosmeticLoadState {
  /// 로그인 전이거나 아직 한 번도 안 물어봤다.
  idle,

  /// 물어보는 중이다.
  loading,

  /// 받았다.
  ready,

  /// 물어봤는데 못 받았다. 들고 있는 카탈로그가 없다.
  failed,
}

/// 개구리 치장(옷장)을 들고 있는 프로바이더다.
///
/// 카탈로그도 무엇을 입고 있는지도 **전부 서버가 정한다**([CosmeticService]).
/// 앱에는 아이템 목록도, 자리 목록도, 기본 차림 규칙도 박혀 있지 않다. 아이템은
/// 계속 늘어날 것이라 앱에 박아 두면 하나 늘 때마다 앱을 다시 내보내야 한다.
///
/// **못 받아도 앱은 평소대로 떠야 한다.** 이 프로바이더를 보는 화면이 열일곱
/// 군데다. 하단 탭 아이콘, 프로필 사진, 출석 도장, 복습 완료, 튜토리얼까지
/// 걸쳐 있다. 그래서 세 경우 모두 **개구리 한 장**을 그린다.
///
/// | 언제 | [slots]·[items] | [layers] | 옷장 화면 |
/// |---|---|---|---|
/// | 받기 전([CosmeticLoadState.idle]) | 빈 목록 | 개구리 한 장 | 비어 있다고 말한다 |
/// | 받는 중([CosmeticLoadState.loading]) | 빈 목록 | 개구리 한 장 | 불러오는 중이라고 말한다 |
/// | 못 받음([CosmeticLoadState.failed]) | 빈 목록 | 개구리 한 장 | 못 불러왔다고 말하고 다시 시도를 준다 |
///
/// 빈 목록과 개구리 한 장을 고른 이유는, 치장이 **있으면 좋은 것**이기 때문이다.
/// 옷을 못 받았다고 하단 탭에 오류를 띄우거나 자리를 비워 두면 앱 전체가 고장 난
/// 것으로 읽힌다. 아무것도 안 걸친 개구리는 정상적인 모습이다.
///
/// 해금 기준은 총 학습 레벨 하나가 아니라 **능력치별**이라, 들고 있는 것도 레벨
/// 하나가 아니라 [CosmeticAbilityLevels] 다섯 묶음이다. 이 다섯은 서버가 준
/// 유저 정보에서 온다([syncWithUser]).
class CosmeticProvider with ChangeNotifier {
  /// 서버가 없으면 아무것도 못 한다. 테스트는 가짜를 끼워 넣는다.
  final CosmeticService _cosmeticService;

  CosmeticProvider({CosmeticService? cosmeticService})
      : _cosmeticService = cosmeticService ?? CosmeticService();

  /// 서버가 준 카탈로그. **아직 못 받았으면 null 이다.**
  ///
  /// null 과 "빈 카탈로그"를 가르는 이유는 옷장 화면이 셋을 달리 말해야 하기
  /// 때문이다. 아직 안 받은 것과, 받았는데 아이템이 없는 것은 다른 말이다.
  CosmeticLoadoutModel? _catalog;

  CosmeticLoadState _state = CosmeticLoadState.idle;

  /// 지금 나가 있는 조회. 요청이 겹치지 않게 한다.
  Future<bool>? _inFlightLoad;

  /// 이 사람의 능력치 레벨 다섯. 서버가 준 유저 정보에서 온다.
  CosmeticAbilityLevels _levels = CosmeticAbilityLevels.start;

  /// **디버그 전용.** 사람이 디버그 패널에서 레벨을 한 번이라도 옮겼는지.
  ///
  /// 옮긴 뒤로는 해금 판정을 앱이 직접 한다([_debugJudgesOwned]). 안 그러면
  /// 패널에서 레벨을 올려도 서버가 준 `owned` 가 그대로라 아무 일도 안 일어나
  /// 패널이 무력해진다. 릴리즈에서는 [setMockLevels] 가 통째로 막혀 있어서 늘
  /// false 다.
  bool _levelsTouched = false;

  /// 지금 걸려 있는 것. 슬롯 키 → 아이템 키.
  Map<String, String> _equipped = const {};

  /// **서버가 마지막으로 준 차림.** 저장이 실패했을 때 되돌아갈 자리다.
  ///
  /// 저장은 먼저 화면을 바꾸고 나중에 서버에 묻는다. 응답을 기다렸다 바꾸면
  /// 그 사이 화면이 멈춘 것처럼 보이기 때문이다. 대신 실패하면 되돌려야 하는데,
  /// 되돌릴 기준이 [_equipped] 안에는 없다. 이미 덮어썼기 때문이다.
  Map<String, String> _confirmedEquipped = const {};

  /// **디버그 전용.** 사람이 한 번이라도 직접 갈아입었는지.
  ///
  /// 디버그 패널로 레벨을 훑을 때, 아직 안 만졌으면 그 레벨의 첫 차림을 계속
  /// 다시 맞춘다. 그 레벨의 사람이 처음 보게 될 모습이 나와야 하기 때문이다.
  bool _touched = false;

  /// 마지막 실패 문구. 화면이 읽고 나면 [consumeFailure] 로 비운다.
  String? _lastFailureMessage;

  /// 마지막 알림 문구. 실패는 아니지만 사용자가 알아야 하는 것이다.
  ///
  /// 서버가 겹치는 자리를 함께 벗겼을 때가 그렇다. 저장은 됐는데 고른 것 중
  /// 일부가 조용히 사라지면 저장이 안 된 것으로 읽힌다.
  String? _lastNoticeMessage;

  /// **디버그 전용.** 켜면 잠긴 것까지 전부 입어 볼 수 있다.
  ///
  /// 능력치 넷을 골고루 올려 둔 사람은 드물어서 보통 절반쯤만 열린다. 디자인을
  /// 봐야 하는 자리에서는 잠긴 것도 입어 볼 수 있어야 해서 그것만 풀어 주는
  /// 스위치를 둔다. 릴리즈에서는 [setUnlockAll] 이 막혀 있어서 늘 false 다.
  bool _unlockAll = false;

  // ── 읽기 ────────────────────────────────────────────────────────────

  /// 서버가 준 카탈로그. 아직 못 받았으면 빈 것이다.
  CosmeticLoadoutModel get _catalogOrEmpty =>
      _catalog ?? CosmeticLoadoutModel.empty;

  /// 옷장을 받았는지.
  bool get hasCatalog => _catalog != null;

  /// 지금 서버에 물어보는 중인지.
  bool get isLoading => _state == CosmeticLoadState.loading;

  /// 물어봤는데 못 받았는지. 들고 있는 카탈로그가 없다는 뜻이다.
  bool get loadFailed => _state == CosmeticLoadState.failed;

  CosmeticLoadState get loadState => _state;

  /// 이 사람의 능력치 레벨 다섯.
  CosmeticAbilityLevels get levels => _levels;

  /// 디버그 패널에서 레벨을 옮긴 적이 있는지.
  bool get levelsTouched => _levelsTouched;

  /// 이 능력치의 지금 레벨. null 이면 총 학습 레벨이다.
  int levelOf(CosmeticAbility? ability) => _levels.levelOf(ability);

  /// 걸 수 있는 자리들. 옷장 탭 순서가 이 순서다.
  List<CosmeticSlotModel> get slots => _catalogOrEmpty.slots;

  /// 아이템 전부. 잠긴 것도 함께 온다.
  List<CosmeticItemModel> get items => loadout.items;

  /// 지금 걸려 있는 것. 슬롯 키 → 아이템 키.
  Map<String, String> get equipped =>
      Map<String, String>.unmodifiable(_equipped);

  /// 지금 차림. `equipped` 가 지금 상태로 채워져 있다.
  CosmeticLoadoutModel get loadout => _loadoutAt(_levels, _equipped);

  /// 개구리를 그릴 층들. 뒤에서 앞 순서다. [FrogCharacter] 에 그대로 넘긴다.
  ///
  /// 카탈로그를 못 받았으면 개구리 한 장이다. 빈 목록이 아니다. 하단 탭
  /// 아이콘과 프로필 사진이 이걸 그대로 그려서, 빈 목록을 주면 그 자리가
  /// 통째로 사라진다.
  List<CosmeticLayerModel> get layers => loadout.resolveLayers();

  /// 배경을 뺀 층들. 개구리만 투명한 바탕에 남는다.
  ///
  /// 달력 도장이나 복습 완료 화면처럼 **이미 바탕이 있는 자리**에 쓴다. 거기에
  /// 배경 파츠까지 깔면 네모난 판이 하나 더 생겨서, 개구리가 아니라 카드가
  /// 놓인 것처럼 보인다.
  ///
  /// 개구리 본체보다 뒤에 그려지는 것(배경, 배낭)을 걷어 낸다. 슬롯 키를 박아
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

  /// **디버그 전용.** 다섯 레벨을 같은 값으로 놓았을 때의 첫 차림.
  ///
  /// 조합 검수 화면이 "레벨을 올릴수록 개구리가 어떻게 달라지나"를 한 축으로
  /// 훑을 때 쓴다. 그 스무 벌은 이 사람의 차림이 아니라서 서버에 물을 것이
  /// 없다. 릴리즈에서는 [DebugCosmeticPreset] 이 빈 맵을 주므로 개구리 한
  /// 장이 나오는데, 이걸 부르는 화면 자체가 `kDebugMode` 에서만 열린다.
  List<CosmeticLayerModel> layersAtLevel(int level) =>
      layersAtLevels(CosmeticAbilityLevels.uniform(level));

  /// **디버그 전용.** 그 레벨들에서의 첫 차림. [layersAtLevel] 을 보라.
  List<CosmeticLayerModel> layersAtLevels(CosmeticAbilityLevels levels) =>
      _loadoutAt(
        levels,
        DebugCosmeticPreset.presetOf(_catalogOrEmpty, levels),
      ).resolveLayers();

  /// **지금 차림 위에** 방금 열린 것을 더 얹은 층들.
  ///
  /// 해금 연출이 "방금 열린 것을 입어 보는" 모습을 그릴 때 쓴다. 자동으로
  /// 입혀 주는 것이 없으니 기준은 그 레벨의 정해진 차림이 아니라 지금 이
  /// 사람이 입고 있는 모습이어야 한다.
  ///
  /// 카탈로그에 아직 없는 아이템도 그린다. 해금은 서버가 알려 주는데 옷장
  /// 카탈로그는 아직 옛것일 수 있어서, `equipped` 에 키를 꽂는 대신 그림을
  /// 그대로 얹는다.
  List<CosmeticLayerModel> layersWith(List<CosmeticUnlockModel> extra) =>
      _loadoutAt(_levels, _equipped).resolveLayers(extra: extra);

  /// 무대 바닥에 깔 **배경 파츠 한 장**. 안 걸쳤으면 null 이다.
  ///
  /// 옷장 탭의 무대는 이 한 장을 개구리 사각형에서 꺼내 **화면 전체로 펼친다.**
  /// 512 정사각형 그대로 둥근 사각형에 갇혀 있으면 캐릭터가 서 있는 무대가
  /// 아니라 벽에 걸린 사진 한 장으로 읽히고, 무대가 깔아 둔 조명과 바닥
  /// 그림자를 그 그림이 통째로 덮어 버린다.
  ///
  /// **가장 뒤에 그려지는 슬롯**의 것이다. 그 자리가 배경이라는 것은 서버가
  /// 정한 그리는 순서에 이미 들어 있어서, 슬롯 이름을 앱에 박아 두지 않아도
  /// 알 수 있다. 배낭도 개구리보다 뒤에 그려지지만 그것은 개구리 몸에 맞춰
  /// 그린 그림이라 무대로 내보내면 자리가 어긋난다. 그래서 맨 뒤 한 자리만 본다.
  CosmeticLayerModel? get stageBackdrop => backdropOf(_equipped);

  /// 이 차림에서 무대에 깔 배경. [stageBackdrop] 의 시착판이다.
  CosmeticLayerModel? backdropOf(Map<String, String> equipped) {
    final slot = _backdropSlot;
    if (slot == null) return null;
    for (final layer in layersOf(equipped)) {
      if (layer.slot == slot) return layer;
    }
    return null;
  }

  /// [stageBackdrop] 한 장을 뺀 층들. 개구리 사각형에 그대로 남을 것들이다.
  ///
  /// [layersWithoutBackdrop] 과 다르다. 그쪽은 개구리 본체보다 **뒤에 그려지는
  /// 것을 전부** 걷어 내서 배낭까지 사라진다. 이쪽은 맨 뒤 한 장만 뺀다. 무대가
  /// 그 한 장을 대신 그리고, 배낭은 개구리와 같은 사각형에 남아야 한다.
  List<CosmeticLayerModel> get layersOnStage => layersOnStageOf(_equipped);

  /// 이 차림에서 배경 한 장을 뺀 층들. [layersOnStage] 의 시착판이다.
  List<CosmeticLayerModel> layersOnStageOf(Map<String, String> equipped) {
    final all = layersOf(equipped);
    final slot = _backdropSlot;
    if (slot == null) return all;
    return [
      for (final layer in all)
        if (layer.slot != slot) layer,
    ];
  }

  /// 가장 뒤에 그려지는 슬롯의 키. 슬롯이 하나도 없으면 null.
  ///
  /// **개구리에 겹치는 자리 중에서** 고른다. 프로필 테두리처럼 합성에서 빠지는
  /// 자리는 애초에 개구리 뒤에 깔리는 것이 아니다.
  String? get _backdropSlot {
    CosmeticSlotModel? lowest;
    for (final slot in _catalogOrEmpty.slots) {
      if (!slot.composited) continue;
      if (lowest == null || slot.layerOrder < lowest.layerOrder) lowest = slot;
    }
    return lowest?.slot;
  }

  /// 원형 프로필 사진에 두르는 **테두리**. 안 걸쳤으면 null 이다.
  ///
  /// 개구리 합성에서 빠지는 자리(`composited == false`)의 것이라 [layers] 에는
  /// 안 들어간다. 개구리 위에 겹쳐 그리는 그림이 아니라 프로필 원 둘레에 두르는
  /// 테두리라서, [ProfileAvatar] 가 따로 받아 간다.
  ///
  /// 그런 자리가 여럿이면 맨 앞에 그려지는 것을 쓴다. 지금은 `FRAME` 하나뿐이다.
  CosmeticItemModel? get profileFrame {
    CosmeticSlotModel? frame;
    for (final slot in _catalogOrEmpty.slots) {
      if (slot.composited) continue;
      if (frame == null || slot.layerOrder > frame.layerOrder) frame = slot;
    }
    if (frame == null) return null;
    return _catalogOrEmpty.itemOf(_equipped[frame.slot]);
  }

  /// 이 슬롯에 들어가는 아이템들. 카탈로그 순서를 지킨다.
  List<CosmeticItemModel> itemsOfSlot(String slot) => loadout.itemsOfSlot(slot);

  /// 이 세트에 묶인 아이템들.
  List<CosmeticItemModel> itemsOfSet(String setId) => loadout.itemsOfSet(setId);

  /// 이 슬롯에 지금 걸려 있는 아이템 키. 없으면 null.
  String? equippedItemKeyOf(String slot) => _equipped[slot];

  /// 아이템 키로 아이템을 찾는다. 없으면 null.
  CosmeticItemModel? itemOf(String? itemKey) => loadout.itemOf(itemKey);

  /// 이 아이템을 가지고 있는지.
  bool isOwned(String itemKey) {
    final item = _catalogOrEmpty.itemOf(itemKey);
    return item != null && _ownsAt(item, _levels);
  }

  /// 디버그 전용 전체 해금이 켜져 있는지.
  bool get unlockAll => _unlockAll;

  /// 이 아이템을 가졌는지. **릴리즈에서는 서버가 준 `owned` 를 그대로 쓴다.**
  ///
  /// 가졌는지 아닌지는 서버가 정한다. 레벨로 여는 것 말고 미션 보상처럼 다른
  /// 길로 열리는 것이 생길 수 있고, 그 규칙이 앱에 박혀 있으면 규칙이 바뀔
  /// 때마다 앱을 다시 내보내야 한다.
  ///
  /// 앱이 직접 매기는 것은 **디버그 패널을 만졌을 때뿐**이다([_debugJudgesOwned]).
  /// 서버 값만 쓰면 패널에서 레벨을 옮겨도 해금 상태가 그대로라 패널이
  /// 무력해진다. 릴리즈에서는 이 아래 [CosmeticItemModel.isUnlockedAt] 이
  /// 한 번도 안 돈다.
  bool _ownsAt(CosmeticItemModel item, CosmeticAbilityLevels levels) {
    if (!_debugJudgesOwned) return item.owned;
    return _unlockAll || item.isUnlockedAt(levels);
  }

  /// 해금 판정을 앱이 직접 하는 중인지. **릴리즈에서는 언제나 false 다.**
  ///
  /// [kDebugMode] 를 맨 앞에 두어 컴파일러가 이 경로를 통째로 걷어내게 한다.
  /// 두 스위치 모두 디버그에서만 켜지지만, 그 사실이 여기 한 줄에 보여야
  /// 나중에 조건이 하나 더 늘어도 경계가 안 흐려진다.
  bool get _debugJudgesOwned =>
      kDebugMode && (_unlockAll || _levelsTouched || DebugLevels.isTouched);

  /// **지금 레벨에서 막 열린** 아이템들. 옷장 격자의 `NEW` 표시가 쓴다.
  ///
  /// 제 능력치의 레벨과 필요 레벨이 딱 맞는 것들이다. 능력치가 갈라진 뒤로는
  /// "이번 레벨"이 하나가 아니라 다섯이라, 넷 중 어느 쪽을 올렸든 그쪽에서
  /// 막 열린 것에 표시가 붙는다.
  List<CosmeticItemModel> get justUnlocked => [
        for (final item in _catalogOrEmpty.items)
          if (item.requiredLevel == _levels.levelOf(item.requiredAbility)) item,
      ];

  /// 그 **총 학습 레벨**에서 새로 열리는 아이템들. 레벨업 연출에 쓴다.
  ///
  /// 레벨업 축하는 총 학습 레벨이 오를 때 뜬다. 그래서 여기서 세는 것도
  /// 능력치가 안 붙은(총 학습 기준) 아이템뿐이다. 출석이나 복습으로 열리는
  /// 것은 그쪽 레벨이 오를 때 열리는 것이라 이 축하의 몫이 아니다.
  List<CosmeticItemModel> unlockedAtTotalStudyLevel(int level) => [
        for (final item in _catalogOrEmpty.items)
          if (item.requiredAbility == null && item.requiredLevel == level) item,
      ];

  /// 총 학습 레벨의 끝. 레벨업 연출의 게이지 오른쪽 끝이다.
  int get maxTotalStudyLevel => CosmeticAbilityLevels.maxTotalStudy;

  String? get lastFailureMessage => _lastFailureMessage;

  String? get lastNoticeMessage => _lastNoticeMessage;

  // ── 서버 ────────────────────────────────────────────────────────────

  /// 유저 정보가 새로 들어왔다. 레벨을 맞추고 필요하면 옷장을 받는다.
  ///
  /// [UserProvider] 가 유저 정보를 받는 자리마다 부른다. 로그인, 자동 로그인,
  /// 프로필 수정 뒤가 모두 여기를 지난다.
  ///
  /// **레벨이 오른 그때가 새로 열린 것이 생긴 때다.** 그래서 처음 한 번과
  /// 레벨이 달라졌을 때만 다시 읽는다. 유저 정보는 문제를 하나 풀 때마다도
  /// 다시 읽히는데 그때마다 옷장까지 물으면 요청만 는다.
  ///
  /// 정보가 null 이면 아무것도 하지 않는다. 유저 정보 조회가 잠깐 실패해도
  /// null 이 오는데, 그걸 로그아웃으로 보고 옷을 벗기면 안 된다. 비우는 것은
  /// 로그아웃이 [clear] 로 직접 시킨다.
  Future<void> syncWithUser(UserInfoModel? info) async {
    if (info == null) return;

    final next = _levelsOf(info);
    final levelsChanged = next != _levels;
    _levels = next;
    if (levelsChanged) notifyListeners();

    if (_catalog == null || levelsChanged) await load();
  }

  /// 옷장을 서버에서 받는다. 받았으면 true 다.
  ///
  /// 이미 나가 있는 조회가 있으면 그것을 함께 기다린다. 옷장 화면에 들어올
  /// 때와 로그인 직후가 겹칠 수 있다.
  Future<bool> load() {
    final inFlight = _inFlightLoad;
    if (inFlight != null) return inFlight;

    final fetch = _runLoad();
    _inFlightLoad = fetch;
    _state = CosmeticLoadState.loading;
    notifyListeners();

    return fetch.whenComplete(() {
      _inFlightLoad = null;
      notifyListeners();
    });
  }

  Future<bool> _runLoad() async {
    final received = await _cosmeticService.getCosmetics();

    if (received == null) {
      // 조회에 실패하면 들고 있던 것을 지우지 않는다. 잠깐 끊겼다고 입고 있던
      // 옷이 벗겨지는 편이 더 이상하다. 한 번도 못 받았을 때만 실패로 남는다.
      _state =
          _catalog == null ? CosmeticLoadState.failed : CosmeticLoadState.ready;
      return false;
    }

    // 서버에 아이템이 늘었는데 그 그림이 설치된 앱에 없으면 빈 칸이 된다.
    _catalog = await CosmeticAssetGuard.pruneUndrawable(received);
    _confirm(_catalog!.equipped);
    // 서버가 준 차림이 기준이 됐으니 디버그로 훑던 흔적은 여기서 끝난다.
    _touched = false;
    _state = CosmeticLoadState.ready;
    return true;
  }

  /// 시착한 차림을 확정한다. 꾸미기 화면의 **저장** 버튼이 부른다.
  ///
  /// 여기서야 비로소 하단 탭 아이콘과 프로필 사진의 개구리가 바뀐다.
  ///
  /// **먼저 바꾸고 나중에 묻는다.** 서버 응답을 기다렸다 바꾸면 그 사이 화면이
  /// 멈춘 것처럼 보인다. 대신 실패하면 [_confirmedEquipped] 로 되돌리고 왜
  /// 안 됐는지 알린다. 되돌릴 기준을 따로 들고 있는 이유가 이것이다.
  ///
  /// 성공했어도 서버가 준 차림이 보낸 것과 다를 수 있다. 겹치는 자리를 서버가
  /// 함께 벗기기 때문이고, 어느 쪽을 남길지는 서버가 정한다(뒤에 깔리는 자리가
  /// 남는다). 앱이 예상한 것과 달라도 **응답이 진실이다.** 그대로 따르고
  /// 무엇이 벗겨졌는지 알린다.
  ///
  /// [equipped] 는 **걸 수 있는 자리 전부**여야 한다. 서버는 요청에 없는 자리를
  /// 비우기 때문에, 개구리에 안 겹치는 자리(프로필 테두리)를 빼고 보내면 그
  /// 자리가 조용히 벗겨진다.
  Future<bool> save(Map<String, String> equipped) async {
    final next = _pruneLocked(equipped, _levels);

    _touched = true;
    _equipped = next;
    _lastFailureMessage = null;
    _lastNoticeMessage = null;
    notifyListeners();

    final result = await _cosmeticService.equipAll(next);
    if (result == null) {
      _equipped = _confirmedEquipped;
      _fail('차림을 저장하지 못했어요. 잠시 뒤 다시 해 주세요.');
      return false;
    }

    _confirm(result.equipped);
    _noticeUnequipped(result.unequippedSlots);
    notifyListeners();
    return true;
  }

  /// 한 자리에 아이템을 건다. 못 가진 것은 걸리지 않는다.
  ///
  /// [save] 와 같이 먼저 바꾸고 나중에 묻는다.
  Future<bool> equip(String slot, String itemKey) async {
    final item = _catalogOrEmpty.itemOf(itemKey);
    if (item == null || item.slot != slot) {
      _fail('지금은 쓸 수 없는 아이템이에요.');
      return false;
    }
    if (!_ownsAt(item, _levels)) {
      _fail(_lockedMessage(item));
      return false;
    }

    return _applyAndSend(
      _catalogOrEmpty.applyEquip(_equipped, slot: slot, itemKey: itemKey),
      () => _cosmeticService.equip(slot: slot, itemKey: itemKey),
    );
  }

  /// 한 자리를 비운다.
  Future<bool> unequip(String slot) async {
    if (!_equipped.containsKey(slot)) return true;

    return _applyAndSend(
      _catalogOrEmpty.applyEquip(_equipped, slot: slot, itemKey: null),
      () => _cosmeticService.equip(slot: slot, itemKey: null),
    );
  }

  /// 세트를 통째로 건다.
  ///
  /// 세트 안에 못 가진 것이 섞여 있으면 하나도 걸지 않는다. 절반만 입혀 두면
  /// 무엇이 모자란지 알 수 없다.
  Future<bool> equipSet(String setId) async {
    final members = _catalogOrEmpty.itemsOfSet(setId);
    if (members.isEmpty) {
      _fail('지금은 쓸 수 없는 세트예요.');
      return false;
    }

    final locked = [
      for (final item in members)
        if (!_ownsAt(item, _levels)) item,
    ];
    if (locked.isNotEmpty) {
      _fail(_lockedMessage(locked.first, others: locked));
      return false;
    }

    var next = _equipped;
    for (final item in members) {
      next = _catalogOrEmpty.applyEquip(
        next,
        slot: item.slot,
        itemKey: item.itemKey,
      );
    }

    return _applyAndSend(next, () => _cosmeticService.equipSet(setId));
  }

  /// 걸친 것을 전부 벗는다.
  Future<bool> unequipAll() => save(const {});

  /// 먼저 바꾸고 서버에 보낸다. 실패하면 마지막으로 받은 차림으로 되돌린다.
  Future<bool> _applyAndSend(
    Map<String, String> next,
    Future<CosmeticEquipResultModel?> Function() send,
  ) async {
    _touched = true;
    _equipped = next;
    _lastFailureMessage = null;
    _lastNoticeMessage = null;
    notifyListeners();

    final result = await send();
    if (result == null) {
      _equipped = _confirmedEquipped;
      _fail('갈아입지 못했어요. 잠시 뒤 다시 해 주세요.');
      return false;
    }

    _confirm(result.equipped);
    _noticeUnequipped(result.unequippedSlots);
    notifyListeners();
    return true;
  }

  /// 서버가 준 차림을 받아들인다. 되돌릴 기준도 이것으로 바뀐다.
  void _confirm(Map<String, String> equipped) {
    _confirmedEquipped = Map<String, String>.unmodifiable(equipped);
    _equipped = _confirmedEquipped;
  }

  /// 서버가 벗긴 자리를 사용자에게 알린다.
  ///
  /// 겹쳐 걸 수 없는 것을 함께 내렸을 때다. 저장은 됐는데 고른 것 중 일부가
  /// 조용히 사라지면 저장이 안 된 것으로 읽힌다. 자리 이름은 서버가 준
  /// `nameKo` 를 쓰고, 모르는 자리면 키를 그대로 적는다.
  void _noticeUnequipped(List<String> slots) {
    if (slots.isEmpty) return;

    final names = [
      for (final slot in slots) _catalogOrEmpty.slotOf(slot)?.nameKo ?? slot,
    ];
    // `자리는` 으로 받는다. 이름이 무엇으로 끝나든 조사가 어색해지지 않는다.
    _lastNoticeMessage = '${names.join(' · ')} 자리는 함께 벗었어요.';
  }

  /// 유저 정보에서 능력치 레벨 다섯을 꺼낸다.
  ///
  /// 디버그 패널로 옮겨 놓은 레벨은 [UserProvider] 가 유저 정보를 내주는
  /// 자리에서 이미 갈아 끼운다. 그래서 여기서 따로 챙길 것이 없다.
  CosmeticAbilityLevels _levelsOf(UserInfoModel info) => CosmeticAbilityLevels(
        attendance: info.attendanceLevel,
        noteWrite: info.noteWriteLevel,
        problemPractice: info.problemPracticeLevel,
        notePractice: info.notePracticeLevel,
        totalStudy: info.totalStudyLevel,
      );

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
    return _catalogOrEmpty.applyEquip(equipped, slot: slot, itemKey: itemKey);
  }

  /// 이 차림에서 지금 못 쓰는 것을 걷어 낸 것.
  ///
  /// 화면은 매번 이걸 통과시킨 차림을 그린다. 서버가 준 `owned` 를 보므로,
  /// 옷장을 열어 둔 사이에 카탈로그가 다시 읽혀 못 가진 것이 되면 그 자리에서
  /// 벗겨진다. 디버그 패널로 레벨을 내리거나 전체 해금을 껐을 때도 같다.
  Map<String, String> usableOf(Map<String, String> equipped) =>
      _pruneLocked(equipped, _levels);

  /// 이 아이템을 아직 못 쓰는 이유. 쓸 수 있으면 null 이다.
  String? lockReasonOf(String itemKey) {
    final item = _catalogOrEmpty.itemOf(itemKey);
    if (item == null) return '지금은 쓸 수 없는 아이템이에요.';
    if (_ownsAt(item, _levels)) return null;
    return _lockedMessage(item);
  }

  // ── 쓰기 ────────────────────────────────────────────────────────────

  /// **디버그 전용.** 능력치 하나의 레벨을 바꾼다. null 이면 총 학습이다.
  void setMockLevel(CosmeticAbility? ability, int level) {
    setMockLevels(_levels.withLevel(ability, level));
  }

  /// **디버그 전용.** 레벨 다섯을 통째로 바꾼다. 릴리즈에서는 아무 일도 없다.
  ///
  /// 아직 한 번도 갈아입지 않았으면 그 레벨의 기본 차림으로 다시 맞춘다.
  /// 이미 갈아입었으면 사람이 고른 것을 두되, 레벨이 내려가 못 쓰게 된 것은
  /// 내린다. 못 가진 것을 입고 있는 모습이 더 이상하다.
  ///
  /// 여기서 바꾼 차림은 **서버로 나가지 않는다.** 진짜 레벨이 아닌 것을 보고
  /// 고른 차림이라 서버에 남길 것이 아니다.
  void setMockLevels(CosmeticAbilityLevels next) {
    if (!kDebugMode) return;

    _levelsTouched = true;
    // **앱 전체가 이 레벨을 보게 한다.** 여기만 바꾸면 옷장은 Lv.15 인데
    // 테마는 진짜 레벨을 말하는 화면이 둘 생긴다. UserProvider 가 유저 정보를
    // 내줄 때 이 값을 갈아 끼워서, 레벨을 읽는 화면이 모두 따라오게 한다.
    DebugLevels.override(next);
    if (next == _levels) return;

    _levels = next;
    _equipped = _touched
        ? _pruneLocked(_equipped, next)
        : DebugCosmeticPreset.presetOf(_catalogOrEmpty, next);
    notifyListeners();
  }

  /// **디버그 전용.** 잠긴 아이템까지 전부 입어 볼 수 있게 하거나 되돌린다.
  ///
  /// 끌 때는 그 사이에 걸어 둔 잠긴 것들을 내린다. 안 내리면 못 가진 것을
  /// 입고 있는 모습이 남는다.
  void setUnlockAll(bool value) {
    if (!kDebugMode) return;
    if (_unlockAll == value) return;

    _unlockAll = value;
    if (!value) {
      _equipped = _pruneLocked(_equipped, _levels);
    }
    notifyListeners();
  }

  /// 실패 문구를 한 번 꺼내 쓰고 비운다. 같은 말이 두 번 뜨는 것을 막는다.
  String? consumeFailure() {
    final message = _lastFailureMessage;
    _lastFailureMessage = null;
    return message;
  }

  /// 알림 문구를 한 번 꺼내 쓰고 비운다.
  String? consumeNotice() {
    final message = _lastNoticeMessage;
    _lastNoticeMessage = null;
    return message;
  }

  /// 들고 있는 것을 전부 비운다. 로그아웃 때 부른다.
  ///
  /// 카탈로그까지 버린다. 같은 기기에서 다른 계정으로 로그인했을 때 앞 사람이
  /// 입고 있던 개구리가 하단 탭에 그대로 남으면 안 된다.
  void clear() {
    _catalog = null;
    _state = CosmeticLoadState.idle;
    _levels = CosmeticAbilityLevels.start;
    _levelsTouched = false;
    DebugLevels.reset();
    _touched = false;
    _unlockAll = false;
    _equipped = const {};
    _confirmedEquipped = const {};
    _lastFailureMessage = null;
    _lastNoticeMessage = null;
    notifyListeners();
  }

  // ── 안쪽 ────────────────────────────────────────────────────────────

  /// 그 차림 하나를 만든다.
  ///
  /// 릴리즈에서는 서버가 준 카탈로그에 `equipped` 만 갈아 끼운다. 아이템을
  /// 한 벌 복사하는 것은 **디버그 패널을 만졌을 때뿐**이다. 이 게터가 화면
  /// 열일곱 군데의 build 마다 불리는 자리라, 릴리즈에서 예순 몇 개를 매번 다시
  /// 만들 이유가 없다.
  CosmeticLoadoutModel _loadoutAt(
    CosmeticAbilityLevels levels,
    Map<String, String> equipped,
  ) {
    final catalog = _catalogOrEmpty;
    if (!_debugJudgesOwned) return catalog.withEquipped(equipped);

    return CosmeticLoadoutModel(
      baseImageUrl: catalog.baseImageUrl,
      slots: catalog.slots,
      items: [
        for (final item in catalog.items)
          item.copyWith(owned: _ownsAt(item, levels)),
      ],
      equipped: Map<String, String>.unmodifiable(equipped),
      baseLayerOrder: catalog.baseLayerOrder,
    );
  }

  /// 그 차림에서 지금 못 쓰는 것을 내린다.
  Map<String, String> _pruneLocked(
    Map<String, String> equipped,
    CosmeticAbilityLevels levels,
  ) {
    final next = <String, String>{};
    equipped.forEach((slot, itemKey) {
      final item = _catalogOrEmpty.itemOf(itemKey);
      if (item != null && _ownsAt(item, levels)) {
        next[slot] = itemKey;
      }
    });
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
