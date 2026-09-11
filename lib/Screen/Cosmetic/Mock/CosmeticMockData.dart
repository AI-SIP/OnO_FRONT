import '../../../Model/Cosmetic/CosmeticLoadoutModel.dart';

/// 백엔드가 붙기 전까지 쓰는 옷장 더미 카탈로그다.
///
/// **서버 응답과 똑같은 모양으로 들고 있는다.** [rawResponse] 는
/// `GET /api/cosmetics` 가 내려줄 JSON 그대로라서, 나중에 API 가 생기면 이
/// 맵을 실제 응답으로 갈아 끼우기만 하면 된다. 화면과 프로바이더는 전부
/// [CosmeticLoadoutModel] 만 보고 있어서 그 위쪽은 손댈 것이 없다.
///
/// 그래서 여기에 Dart 객체를 직접 만들어 두지 않고 굳이 Map 을 거친다. 파싱까지
/// 같은 길을 타야 교체했을 때 다른 데서 터지지 않는다.
class CosmeticMockData {
  const CosmeticMockData._();

  /// 더미에서 다룰 수 있는 가장 높은 레벨. 레벨 슬라이더의 오른쪽 끝이다.
  static const int maxLevel = 15;

  /// 개구리 본체 그림.
  static const String baseImageUrl = 'assets/Cosmetic/BASE.png';

  /// 개구리 본체가 들어가는 층. 배경(100)·가방(200) 뒤, 옷(400) 앞이다.
  static const int baseLayerOrder = 300;

  /// `GET /api/cosmetics` 응답과 같은 모양의 더미다.
  ///
  /// `equipped` 는 비워 둔다. 처음에 무엇을 입고 있을지는 레벨에 따라 달라져서
  /// `CosmeticProvider` 가 정한다. 서버가 붙으면 서버가 준 값이 그대로 쓰인다.
  static Map<String, Object?> get rawResponse => {
        'baseImageUrl': baseImageUrl,
        'baseLayerOrder': baseLayerOrder,
        'slots': _slots,
        'items': _items,
        'equipped': <String, String>{},
      };

  /// 파싱까지 끝낸 더미. 매번 같은 것을 쓴다.
  static final CosmeticLoadoutModel loadout =
      CosmeticLoadoutModel.fromJsonOrNull(rawResponse) ??
          CosmeticLoadoutModel.empty;

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

  // ── 아래는 서버가 내려줄 원본 모양 ──────────────────────────────────

  /// 겹쳐 그리는 자리들. `layerOrder` 가 작을수록 뒤에 깔린다.
  ///
  /// 이 순서가 옷장 탭의 순서이기도 하다.
  static const List<Map<String, Object?>> _slots = [
    {'slot': 'BACKGROUND', 'layerOrder': 100, 'nameKo': '배경'},
    // 등에 메는 가방이라 개구리 뒤에 깔린다. 앞으로 메는 것은 BAG(450) 이다.
    {'slot': 'BACK', 'layerOrder': 200, 'nameKo': '등짐'},
    {'slot': 'OUTFIT', 'layerOrder': 400, 'nameKo': '옷'},
    // 가방 세 종이 전부 앞으로 메는 그림이라 개구리 뒤(200)에 두면 몸통이 덮어
    // 끈 조각만 보인다. 옷 위(450)로 올린다. 등에 메는 그림이 생기면 그때
    // 뒤쪽 자리를 따로 낸다.
    {'slot': 'BAG', 'layerOrder': 450, 'nameKo': '가방'},
    {'slot': 'NECK', 'layerOrder': 500, 'nameKo': '목'},
    {'slot': 'FACE', 'layerOrder': 600, 'nameKo': '얼굴'},
    {'slot': 'HEAD', 'layerOrder': 700, 'nameKo': '머리'},
    {'slot': 'HAND', 'layerOrder': 800, 'nameKo': '손'},
    {'slot': 'BADGE', 'layerOrder': 850, 'nameKo': '뱃지'},
    // 개구리 앞에 흩날리는 것들. 무엇과도 겹치지 않는다.
    {'slot': 'EFFECT', 'layerOrder': 900, 'nameKo': '효과'},
  ];

  /// 아이템 전부.
  ///
  /// `requiredLevel` 이 숫자면 그 레벨에서 열리고, null 이면 레벨로는 열리지
  /// 않는 것(미션 보상)이다. 옷장에서는 둘을 다르게 보여 줘야 한다.
  static final List<Map<String, Object?>> _items = [
    // ── 레벨로 열리는 것들 ──
    _item('headband_sprout', 'HEAD', '새싹 머리띠', level: 2),
    _item('bg_spring', 'BACKGROUND', '봄', level: 3),
    _item('glasses_round', 'FACE', '동그란 안경', level: 4),
    _item('scarf', 'NECK', '목도리', level: 5),
    _item('hat_beanie', 'HEAD', '비니', level: 6),
    _item('bg_study', 'BACKGROUND', '공부방', level: 7),
    _item('bag_mini_backpack', 'BAG', '미니 백팩', level: 8),
    _item('outfit_cardigan', 'OUTFIT', '가디건', level: 9, fullBody: true),
    _item('prop_study', 'HAND', '공부 소품', level: 10),
    _item('glasses_sun', 'FACE', '선글라스', level: 11),
    _item('hat_bucket', 'HEAD', '버킷햇', level: 12),
    _item('bg_night', 'BACKGROUND', '밤하늘', level: 13),
    _item('hat_crown', 'HEAD', '왕관', level: 14),
    _item('hat_graduate', 'HEAD', '학사모', level: 15, setId: 'graduate'),
    _item('outfit_graduate', 'OUTFIT', '학사복',
        level: 15, setId: 'graduate', fullBody: true),
    _item('prop_diploma', 'HAND', '졸업장', level: 15, setId: 'graduate'),

    // ── 레벨로는 열리지 않는 것들(미션 보상) ──
    _item('hat_beret', 'HEAD', '베레모'),
    _item('headphone', 'HEAD', '헤드폰'),
    _item('glasses_heart', 'FACE', '하트 안경'),
    _item('bowtie', 'NECK', '나비넥타이'),
    _item('neck_medal', 'NECK', '메달'),
    _item('neck_camera', 'NECK', '카메라'),
    _item('outfit_school', 'OUTFIT', '교복', fullBody: true),
    _item('outfit_hoodie', 'OUTFIT', '후드티', fullBody: true),
    _item('outfit_raincoat', 'OUTFIT', '비옷', fullBody: true),
    _item('bag_waist_pouch', 'BAG', '허리 가방'),
    _item('bag_crossbody_satchel', 'BAG', '크로스백'),
    _item('badge_star', 'BADGE', '별 뱃지'),
    _item('badge_heart', 'BADGE', '하트 뱃지'),
    _item('badge_flame', 'BADGE', '불꽃 뱃지'),
    _item('badge_music', 'BADGE', '음표 뱃지'),
    _item('badge_snowflake', 'BADGE', '눈꽃 뱃지'),
    _item('effect_sparkle', 'EFFECT', '반짝임'),
    _item('effect_petals', 'EFFECT', '꽃잎'),
    _item('effect_snow', 'EFFECT', '눈'),
    _item('effect_fireflies', 'EFFECT', '반딧불'),
    _item('bg_summer', 'BACKGROUND', '여름'),
    _item('back_backpack_navy', 'BACK', '남색 책가방'),
    _item('back_backpack_canvas', 'BACK', '캔버스 책가방'),
    _item('face_cheek_stickers', 'FACE', '볼 스티커'),
    _item('face_eye_patch', 'FACE', '안대'),
    _item('face_moustache', 'FACE', '콧수염'),
    _item('head_earmuffs_winter', 'HEAD', '겨울 귀마개'),
    _item('neck_scarf_coral', 'NECK', '코랄 목도리'),
    _item('prop_lantern', 'HAND', '랜턴'),
    _item('prop_notebook', 'HAND', '공책'),
    _item('prop_tumbler', 'HAND', '텀블러'),
    _item('prop_bouquet', 'HAND', '꽃다발'),
    _item('prop_umbrella', 'HAND', '우산'),
    _item('badge_leaf_star', 'BADGE', '나뭇잎 별'),
    _item('bg_autumn', 'BACKGROUND', '가을'),
    _item('bg_rainy', 'BACKGROUND', '비 오는 날'),
    _item('bg_space', 'BACKGROUND', '우주'),
    _item('bg_sunset', 'BACKGROUND', '노을'),
    _item('bg_winter', 'BACKGROUND', '겨울'),
  ];

  /// 아이템 한 줄을 서버 응답 모양으로 만든다.
  ///
  /// `owned` 는 넣지 않는다. 더미에서는 가진 것인지를 레벨로 판단하기 때문에
  /// `CosmeticProvider` 가 지금 레벨을 보고 매번 다시 매긴다.
  static Map<String, Object?> _item(
    String itemKey,
    String slot,
    String nameKo, {
    int? level,
    String? setId,
    bool fullBody = false,
  }) {
    return {
      'itemKey': itemKey,
      'slot': slot,
      'nameKo': nameKo,
      'imageUrl': 'assets/Cosmetic/$itemKey.png',
      'requiredLevel': level,
      'setId': setId,
      'conflictsWith': const <String>[],
      // 소매와 바짓단이 그려진 옷이다. 뒤에 전신 개구리를 두면 원래 팔다리가
      // 옷 밖으로 삐져나와서, 본체를 머리만 있는 그림으로 바꿔 깐다.
      'fullBody': fullBody,
    };
  }
}
