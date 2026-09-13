import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Model/Cosmetic/CosmeticEquipResultModel.dart';
import 'package:ono/Model/Cosmetic/CosmeticLoadoutModel.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Module/Debug/DebugCosmeticPreset.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Service/Api/Cosmetic/CosmeticService.dart';

/// 옷장 **계약 픽스처**다. `GET /api/cosmetics` 가 내려줄 것을 그대로 적어 둔다.
///
/// 원래는 백엔드가 붙기 전까지 앱이 읽던 더미였다(`lib/Screen/Cosmetic/Mock/`).
/// 서버가 붙으면서 앱은 더 이상 이것을 읽지 않는다. 그런데도 지우지 않고 테스트
/// 쪽으로 옮겨 온 이유는 **역할이 바뀌었기 때문**이다.
///
/// 1. **해금표와 서버 사이의 계약서다.** 여기 적힌 자리·능력치·레벨은
///    `docs/치장 시스템/해금표.md` 를 그대로 옮긴 것이고, 어긋나지 않는지는
///    `test/screen/cosmetic/cosmetic_unlock_table_test.dart` 가 문서를 직접
///    읽어 잠근다. 이것을 없애면 그 테스트가 같이 사라진다. 배치를 바꿀 일이
///    생기면 문서를 먼저 고친다.
/// 2. **가짜 서버의 밑천이다.** [FakeCosmeticService] 가 이 카탈로그로 응답을
///    만든다. 그래서 옷장을 보는 테스트들은 서버 왕복까지 포함한 길을 탄다.
///
/// Dart 객체를 직접 만들어 두지 않고 굳이 Map 을 거치는 것도 그대로 뒀다.
/// 파싱까지 같은 길을 타야 실제 응답이 달라졌을 때 여기서 걸린다.
///
/// **`test/fixtures/cosmetic/*.json` 과 역할이 다르다.** 이쪽은 어떤 아이템이
/// 몇 레벨에 열리는지(해금표)를 잠그고 가짜 서버의 밑천이 된다. 그쪽은 응답
/// **한 번의 본문 모양**을, `CommonResponse` 껍데기까지 포함해 잠근다. 아이템
/// 목록은 몇 줄뿐이어서 해금표를 대신하지 못한다.
class CosmeticMockData {
  const CosmeticMockData._();

  /// 개구리 본체 그림.
  static const String baseImageUrl = 'assets/Cosmetic/BASE.png';

  /// 개구리 본체가 들어가는 층. 배경(100)·배낭(200) 뒤, 옷(400) 앞이다.
  ///
  /// 배낭은 자리가 아니라 아이템이 층을 덮어써서 200 에 온다([_backLayerOrder]).
  static const int baseLayerOrder = 300;

  /// 등에 메는 것이 그려지는 층. 개구리 본체(300) 바로 뒤다.
  ///
  /// 자리가 아니라 **아이템**이 들고 있는 값이다. 배낭과 앞가방이 같은 `BAG`
  /// 자리를 쓰지만 하나는 개구리 뒤, 하나는 옷 위에 그려져야 한다.
  static const int _backLayerOrder = 200;

  /// 지금 하나뿐인 세트.
  static const String graduateSetId = 'graduate';
  static const String graduateSetNameKo = '학사 세트';

  /// `GET /api/cosmetics` 응답과 같은 모양이다.
  ///
  /// `owned` 와 `equipped` 는 비워 둔다. 둘 다 **사람마다 다른 값**이라 이
  /// 표에는 적을 것이 없다. 레벨을 정해 놓고 그 사람의 응답을 만드는 것은
  /// [catalogAt] 이 한다.
  static Map<String, Object?> get rawResponse => {
        'baseImageUrl': baseImageUrl,
        'baseLayerOrder': baseLayerOrder,
        'slots': _slots,
        'items': _items,
        'equipped': <String, String>{},
      };

  /// 파싱까지 끝낸 카탈로그. 아무것도 안 가졌고 아무것도 안 걸친 상태다.
  ///
  /// 표 자체를 확인하는 테스트(해금표 대조, 에셋 경로)가 쓴다. 사람의 상태가
  /// 필요하면 [catalogAt] 을 쓴다.
  static final CosmeticLoadoutModel loadout =
      CosmeticLoadoutModel.fromJsonOrNull(rawResponse) ??
          CosmeticLoadoutModel.empty;

  /// 그 레벨들의 사람에게 **서버가 내려줄** 응답.
  ///
  /// 서버가 하는 일 둘을 여기서 그대로 흉내 낸다.
  ///
  /// 1. 아이템마다 `owned` 를 매긴다. 해금표대로 제 능력치의 레벨을 본다.
  /// 2. 장착 행이 없는 사람에게 **기본 차림**을 계산해 `equipped` 에 채운다.
  ///
  /// 둘 다 이제 서버의 몫이라 앱에는 규칙이 없다. 규칙 한 벌은
  /// [DebugCosmeticPreset] 에 남아 있는데(조합 검수 화면이 쓴다), 같은 규칙을
  /// 여기 또 적으면 두 벌이 되고 두 벌이 되면 언젠가 갈린다. 그래서 그것을
  /// 빌려 쓴다.
  static CosmeticLoadoutModel catalogAt(CosmeticAbilityLevels levels) {
    final items = [
      for (final item in rawResponse['items']! as List<Map<String, Object?>>)
        {...item, 'owned': _isUnlocked(item, levels)},
    ];
    final catalog = CosmeticLoadoutModel.fromJsonOrNull({
          ...rawResponse,
          'items': items,
        }) ??
        CosmeticLoadoutModel.empty;

    return catalog.withEquipped(DebugCosmeticPreset.presetOf(catalog, levels));
  }

  /// 그 레벨들에서 이 줄이 열려 있는지. 해금표가 정한 규칙 그대로다.
  static bool _isUnlocked(
    Map<String, Object?> item,
    CosmeticAbilityLevels levels,
  ) {
    final ability = CosmeticAbility.fromKeyOrNull(item['requiredAbility']);
    final required = item['requiredLevel'] as int;
    return levels.levelOf(ability) >= required;
  }

  /// 그 레벨들을 달고 있는 유저 정보.
  ///
  /// 옷장은 [CosmeticProvider.syncWithUser] 로만 레벨을 받는다. 실제 앱에서
  /// 레벨이 오는 길이 그것 하나뿐이라, 테스트도 같은 길로 넣는다.
  static UserInfoModel userInfoAt(CosmeticAbilityLevels levels) =>
      UserInfoModel(
        userId: 1,
        attendanceLevel: levels.attendance,
        noteWriteLevel: levels.noteWrite,
        problemPracticeLevel: levels.problemPractice,
        notePracticeLevel: levels.notePractice,
        totalStudyLevel: levels.totalStudy,
      );

  /// 학사 세트를 입은 개구리 한 벌.
  ///
  /// 튜토리얼처럼 "가장 보기 좋은 개구리" 한 장이 필요한 곳에서 쓴다. 사용자가
  /// 실제로 무엇을 입고 있든 상관없이 늘 같은 모습이어야 하는 자리다.
  static final List<CosmeticLayerModel> graduateLayers = loadout.resolveLayers(
    equippedOverride: const {
      'BACKGROUND': 'bg_study',
      'OUTFIT': 'outfit_graduate',
      'HEAD': 'hat_graduate',
      'HAND': 'prop_diploma',
    },
  );

  /// 아무것도 걸치지 않은 개구리 한 장. 차림을 아직 모를 때 쓴다.
  static final List<CosmeticLayerModel> baseOnlyLayers =
      loadout.resolveLayers(equippedOverride: const {});

  /// 시안을 열었을 때 처음 서 있는 레벨들이다.
  ///
  /// 다섯을 다 끝까지 올려 두면 쉰다섯 칸이 전부 열려서 **잠긴 칸을 볼 수가
  /// 없다.** 이 시안에서 봐야 하는 것의 절반이 "무엇을 얼마나 올려야 열리는지"
  /// 라서, 넷을 서로 다른 높이에 흩어 둔다. 그러면 한 화면에서 열린 칸과 잠긴
  /// 칸이, 그리고 능력치 넷의 색이 모두 같이 보인다.
  ///
  /// 값 자체에 의미는 없다. 디버그 패널에서 언제든 옮길 수 있다.
  static final CosmeticAbilityLevels demoLevels = CosmeticAbilityLevels(
    attendance: 9,
    noteWrite: 5,
    problemPractice: 12,
    notePractice: 3,
    totalStudy: 11,
  );

  // ── 아래는 서버가 내려줄 원본 모양 ──────────────────────────────────

  /// 겹쳐 그리는 자리들. `layerOrder` 가 작을수록 뒤에 깔린다.
  ///
  /// 이 순서가 옷장 탭의 순서이기도 하다.
  static const List<Map<String, Object?>> _slots = [
    {
      'slot': 'BACKGROUND',
      'layerOrder': 100,
      'nameKo': '배경',
      'composited': true,
    },
    {'slot': 'OUTFIT', 'layerOrder': 400, 'nameKo': '옷', 'composited': true},
    // **자리 하나에 그리는 층이 둘인 유일한 자리다.** 앞으로 메는 가방 셋은
    // 개구리 뒤(200)에 두면 몸통이 덮어 끈 조각만 보여서 옷 위(450)에 그린다.
    // 등에 메는 배낭 둘은 반대로 개구리 뒤여야 해서 아이템이 층을 200 으로
    // 덮어쓴다. 사용자에게는 둘 다 `가방` 한 자리다.
    {'slot': 'BAG', 'layerOrder': 450, 'nameKo': '가방', 'composited': true},
    {'slot': 'NECK', 'layerOrder': 500, 'nameKo': '목', 'composited': true},
    {'slot': 'FACE', 'layerOrder': 600, 'nameKo': '얼굴', 'composited': true},
    {'slot': 'HEAD', 'layerOrder': 700, 'nameKo': '머리', 'composited': true},
    {'slot': 'HAND', 'layerOrder': 800, 'nameKo': '손', 'composited': true},
    {'slot': 'BADGE', 'layerOrder': 850, 'nameKo': '뱃지', 'composited': true},
    // 개구리 앞에 흩날리는 것들. 무엇과도 겹치지 않는다.
    {'slot': 'EFFECT', 'layerOrder': 900, 'nameKo': '효과', 'composited': true},
    // **개구리에 겹치지 않는 유일한 자리다.** 원형 프로필 사진 둘레에 두르는
    // 테두리라, layerOrder 가 맨 뒤여도 개구리 합성에서는 빠진다. 그 판단을
    // 앱이 슬롯 이름으로 하지 않도록 서버가 composited 로 내려준다.
    {'slot': 'FRAME', 'layerOrder': 1000, 'nameKo': '프레임', 'composited': false},
  ];

  /// 아이템 전부. 예순세 가지가 빠짐없이 어느 능력치엔가 매달려 있다.
  ///
  /// 능력치별로 묶고 레벨 오름차순으로 적는다. 해금표와 같은 순서라 둘을 나란히
  /// 놓고 볼 수 있다. 이 순서가 옷장 격자의 순서이기도 해서, 한 자리 안에서는
  /// 같은 능력치의 것들이 붙어 나온다.
  static final List<Map<String, Object?>> _items = [
    // ── 출석 ──
    _item('bg_spring', 'BACKGROUND', '봄', 2, _attendance),
    _item('effect_petals', 'EFFECT', '꽃잎', 3, _attendance),
    _frame('frame_spring', '봄 테두리', 3, _attendance),
    _item('bg_summer', 'BACKGROUND', '여름', 4, _attendance),
    _item('effect_sparkle', 'EFFECT', '반짝임', 5, _attendance),
    _frame('frame_summer', '여름 테두리', 5, _attendance),
    _item('bg_rainy', 'BACKGROUND', '비 오는 날', 6, _attendance),
    _item('effect_fireflies', 'EFFECT', '반딧불', 8, _attendance),
    _item('bg_autumn', 'BACKGROUND', '가을', 9, _attendance),
    _frame('frame_autumn', '가을 테두리', 10, _attendance),
    _item('bg_sunset', 'BACKGROUND', '노을', 11, _attendance),
    _item('bg_winter', 'BACKGROUND', '겨울', 12, _attendance),
    _item('effect_snow', 'EFFECT', '눈', 13, _attendance),
    _frame('frame_winter', '겨울 테두리', 13, _attendance),
    _item('bg_night', 'BACKGROUND', '밤하늘', 14, _attendance),
    _item('bg_space', 'BACKGROUND', '우주', 15, _attendance),
    _frame('frame_night', '밤하늘 테두리', 15, _attendance),

    // ── 오답노트 작성 ──
    _item('bag_mini_backpack', 'BAG', '미니 백팩', 2, _noteWrite),
    _item('prop_notebook', 'HAND', '공책', 3, _noteWrite),
    _item('back_backpack_navy', 'BAG', '남색 배낭', 5, _noteWrite,
        layerOrder: _backLayerOrder),
    _item('prop_study', 'HAND', '공부 소품', 6, _noteWrite),
    _item('bag_waist_pouch', 'BAG', '허리 가방', 8, _noteWrite),
    _item('back_backpack_canvas', 'BAG', '캔버스 배낭', 9, _noteWrite,
        layerOrder: _backLayerOrder),
    _item('bag_crossbody_satchel', 'BAG', '크로스백', 11, _noteWrite),
    _item('bg_study', 'BACKGROUND', '공부방', 12, _noteWrite),
    _item('prop_tumbler', 'HAND', '텀블러', 13, _noteWrite),
    _frame('frame_study', '공부방 테두리', 14, _noteWrite),

    // ── 문제 복습 ──
    _item('glasses_round', 'FACE', '동그란 안경', 2, _problemPractice),
    _item('hat_beanie', 'HEAD', '비니', 4, _problemPractice),
    _item('face_cheek_stickers', 'FACE', '볼 스티커', 5, _problemPractice),
    _item('glasses_sun', 'FACE', '선글라스', 6, _problemPractice),
    _item('hat_bucket', 'HEAD', '버킷햇', 8, _problemPractice),
    _item('face_eye_patch', 'FACE', '안대', 9, _problemPractice),
    _item('hat_beret', 'HEAD', '베레모', 10, _problemPractice),
    _item('glasses_heart', 'FACE', '하트 안경', 12, _problemPractice),
    _item('headphone', 'HEAD', '헤드폰', 13, _problemPractice),
    _item('face_moustache', 'FACE', '콧수염', 14, _problemPractice),
    _item('head_earmuffs_winter', 'HEAD', '겨울 귀마개', 15, _problemPractice),

    // ── 복습 세트 복습 ──
    _item('scarf', 'NECK', '목도리', 2, _notePractice),
    _item('bowtie', 'NECK', '나비넥타이', 3, _notePractice),
    _item('outfit_cardigan', 'OUTFIT', '가디건', 5, _notePractice, fullBody: true),
    _item('neck_scarf_coral', 'NECK', '코랄 목도리', 6, _notePractice),
    _item('outfit_hoodie', 'OUTFIT', '후드티', 8, _notePractice, fullBody: true),
    _item('neck_camera', 'NECK', '카메라', 9, _notePractice),
    _item('outfit_raincoat', 'OUTFIT', '비옷', 10, _notePractice, fullBody: true),
    _item('neck_medal', 'NECK', '메달', 12, _notePractice),
    _item('outfit_school', 'OUTFIT', '교복', 13, _notePractice, fullBody: true),

    // ── 총 학습 레벨 (능력치 넷을 합산해 오른다) ──
    _item('headband_sprout', 'HEAD', '새싹 머리띠', 2, null),
    _item('badge_leaf_star', 'BADGE', '나뭇잎 별', 3, null),
    _frame('frame_leaf', '나뭇잎 테두리', 4, null),
    _item('badge_star', 'BADGE', '별 뱃지', 5, null),
    _item('badge_heart', 'BADGE', '하트 뱃지', 7, null),
    _item('prop_bouquet', 'HAND', '꽃다발', 8, null),
    _item('badge_music', 'BADGE', '음표 뱃지', 10, null),
    _item('prop_umbrella', 'HAND', '우산', 12, null),
    _item('badge_flame', 'BADGE', '불꽃 뱃지', 14, null),
    _item('prop_lantern', 'HAND', '랜턴', 16, null),
    _frame('frame_master', '마스터 테두리', 17, null),
    _item('badge_snowflake', 'BADGE', '눈꽃 뱃지', 18, null),
    _item('hat_crown', 'HEAD', '왕관', 19, null),
    _item('hat_graduate', 'HEAD', '학사모', 20, null, setId: graduateSetId),
    _item('outfit_graduate', 'OUTFIT', '학사복', 20, null,
        setId: graduateSetId, fullBody: true),
    _item('prop_diploma', 'HAND', '졸업장', 20, null, setId: graduateSetId),
  ];

  // 서버가 쓰는 능력치 값. 표와 나란히 읽히도록 짧은 이름을 붙여 둔다.
  static const String _attendance = 'ATTENDANCE';
  static const String _noteWrite = 'NOTE_WRITE';
  static const String _problemPractice = 'PROBLEM_PRACTICE';
  static const String _notePractice = 'NOTE_PRACTICE';

  /// 아이템 한 줄을 서버 응답 모양으로 만든다.
  ///
  /// `owned` 는 넣지 않는다. 더미에서는 가진 것인지를 능력치 레벨로 판단하기
  /// 때문에 `CosmeticProvider` 가 지금 레벨들을 보고 매번 다시 매긴다.
  ///
  /// [ability] 가 null 이면 총 학습 레벨 기준이다. 서버도 그 자리를 비워 보낸다.
  /// 프로필 테두리 한 줄.
  ///
  /// 다른 치장과 두 가지가 다르다. 그림이 **SVG** 라서 `assets/ProfileFrame/`
  /// 에 있고, 자리가 `FRAME` 이라 개구리 합성에서 빠진다. 서버도 같은 모양으로
  /// 내려준다.
  static Map<String, Object?> _frame(
    String itemKey,
    String nameKo,
    int level,
    String? ability,
  ) {
    return {
      ..._item(itemKey, 'FRAME', nameKo, level, ability),
      'imageUrl': 'assets/ProfileFrame/$itemKey.svg',
    };
  }

  static Map<String, Object?> _item(
    String itemKey,
    String slot,
    String nameKo,
    int level,
    String? ability, {
    String? setId,
    bool fullBody = false,
    int? layerOrder,
  }) {
    return {
      'itemKey': itemKey,
      'slot': slot,
      'nameKo': nameKo,
      'imageUrl': 'assets/Cosmetic/$itemKey.png',
      'requiredLevel': level,
      'requiredAbility': ability,
      'setId': setId,
      // 세트에 안 묶인 것은 이름도 없다. 서버도 둘을 같이 비운다.
      'setNameKo': setId == null ? null : graduateSetNameKo,
      'conflictsWith': const <String>[],
      // 소매와 바짓단이 그려진 옷이다. 뒤에 전신 개구리를 두면 원래 팔다리가
      // 옷 밖으로 삐져나와서, 본체를 머리만 있는 그림으로 바꿔 깐다.
      'fullBody': fullBody,
      // 자리의 그리는 층을 덮어쓸 때만 값이 있다. 서버도 같은 모양으로
      // 내려주고, 비어 있으면 자리 값을 쓴다.
      'layerOrder': layerOrder,
    };
  }
}

/// 옷장 API 의 **가짜 서버**다.
///
/// 진짜 서버처럼 차림을 제가 들고 있는다. 장착 요청을 받으면 제 차림을 고쳐
/// 놓고 **차림 전체**를 돌려준다. 응답만 흉내 내고 상태를 안 들고 있으면,
/// "저장한 것이 다음 조회에 실려 온다" 같은 것을 잠글 수 없다.
///
/// 겹쳐 걸 수 없는 것을 함께 내리는 규칙은 [CosmeticLoadoutModel.applyEquip]
/// 을 쓴다. 앱도 같은 것을 쓴다. 규칙을 여기 또 적으면 두 벌이 되고, 두 벌이
/// 어긋나면 저장할 때마다 눈앞의 개구리가 한 번 더 바뀐다.
class FakeCosmeticService implements CosmeticService {
  FakeCosmeticService({
    CosmeticLoadoutModel? catalog,
    this.failLoad = false,
    this.failEquip = false,
  }) : catalog =
            catalog ?? CosmeticMockData.catalogAt(CosmeticAbilityLevels.max) {
    equipped = Map<String, String>.from(this.catalog.equipped);
  }

  /// 서버가 들고 있는 카탈로그.
  CosmeticLoadoutModel catalog;

  /// 서버가 들고 있는 차림.
  late Map<String, String> equipped;

  /// 조회가 실패하는지. 404 나 연결 끊김을 흉내 낸다.
  bool failLoad;

  /// 장착이 실패하는지. `equip-all` 이 아직 배포되기 전을 흉내 낸다.
  bool failEquip;

  /// 조회가 몇 번 나갔는지.
  int loadCount = 0;

  /// `equip-all` 로 실제로 나간 차림들. 무엇을 보냈는지 잠그는 데 쓴다.
  final List<Map<String, String>> equipAllRequests = [];

  /// 다음 `equip-all` 응답에 실어 보낼 `unequippedSlots`.
  ///
  /// 진짜 서버는 요청에 담긴 것끼리 부딪혔을 때만 이 목록을 채운다. 가짜
  /// 서버는 겹침을 판정하지 않으므로 필요한 테스트가 직접 적어 준다.
  List<String> equipAllUnequippedSlots = const [];

  @override
  Future<CosmeticLoadoutModel?> getCosmetics() async {
    loadCount++;
    if (failLoad) return null;
    return catalog.withEquipped(equipped);
  }

  @override
  Future<CosmeticEquipResultModel?> equip({
    required String slot,
    String? itemKey,
  }) async {
    if (failEquip) return null;
    return _commit(catalog.applyEquip(equipped, slot: slot, itemKey: itemKey),
        requested: {slot});
  }

  @override
  Future<CosmeticEquipResultModel?> equipSet(String setId) async {
    if (failEquip) return null;

    var next = equipped;
    final requested = <String>{};
    for (final item in catalog.itemsOfSet(setId)) {
      next = catalog.applyEquip(next, slot: item.slot, itemKey: item.itemKey);
      requested.add(item.slot);
    }
    return _commit(next, requested: requested);
  }

  @override
  Future<CosmeticEquipResultModel?> equipAll(
    Map<String, String> equipped,
  ) async {
    equipAllRequests.add(Map<String, String>.from(equipped));
    if (failEquip) return null;

    // **전체 교체다.** 요청에 없는 자리는 비운다. 그렇게 비워진 자리는
    // 사용자가 일부러 뺀 것이라 `unequippedSlots` 에 담지 않는다. 여기 담기는
    // 것은 요청에 담겨 왔는데도 서버가 거절한 자리뿐이다.
    this.equipped = Map<String, String>.from(equipped);
    return CosmeticEquipResultModel(
      equipped: Map<String, String>.from(equipped),
      unequippedSlots: equipAllUnequippedSlots,
    );
  }

  /// 바뀐 차림을 받아들이고 응답을 만든다.
  ///
  /// `unequippedSlots` 에는 **충돌로 벗겨진 자리만** 담는다. 이번 요청이 직접
  /// 건드린 자리([requested])는 사용자가 그렇게 시킨 것이라 빼고 센다.
  CosmeticEquipResultModel _commit(
    Map<String, String> next, {
    required Set<String> requested,
  }) {
    final removed = [
      for (final slot in equipped.keys)
        if (!next.containsKey(slot) && !requested.contains(slot)) slot,
    ];
    equipped = Map<String, String>.from(next);

    return CosmeticEquipResultModel(
      equipped: Map<String, String>.from(next),
      unequippedSlots: removed,
    );
  }
}

/// 가짜 서버에서 옷장을 **받아 온** 프로바이더.
///
/// 앱에서 옷장이 채워지는 길과 같은 길을 탄다. 로그인 뒤 유저 정보가 들어오면
/// [CosmeticProvider.syncWithUser] 가 레벨을 맞추고 카탈로그를 받는다. 생성자로
/// 상태를 밀어 넣지 않는 것은, 그러면 조회가 빠진 길을 테스트하게 되기 때문이다.
Future<CosmeticProvider> loadedCosmeticProvider({
  CosmeticAbilityLevels? levels,
  FakeCosmeticService? service,
}) async {
  final at = levels ?? CosmeticMockData.demoLevels;
  final fake =
      service ?? FakeCosmeticService(catalog: CosmeticMockData.catalogAt(at));
  final provider = CosmeticProvider(cosmeticService: fake);
  await provider.syncWithUser(CosmeticMockData.userInfoAt(at));
  return provider;
}
