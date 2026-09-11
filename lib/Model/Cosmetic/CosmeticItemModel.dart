/// 개구리에 입힐 수 있는 치장 아이템 하나다.
///
/// 정의를 앱에 두지 않는다. 아이템은 계속 늘어나기 때문에, 새 아이템이 나올
/// 때마다 앱을 다시 내보내야 하면 늘리는 의미가 없다.
class CosmeticItemModel {
  /// 서버가 쓰는 아이템 키. 장착 요청에 이 값을 그대로 보낸다.
  final String itemKey;

  /// 이 아이템이 들어가는 자리. [CosmeticSlotModel.slot] 과 같은 값이다.
  final String slot;

  /// 화면에 보여 줄 이름.
  final String nameKo;

  /// 그림의 위치.
  ///
  /// `http` 로 시작하면 네트워크에서, 아니면 앱에 들어 있는 에셋에서 읽는다.
  /// 지금은 전부 번들 경로로 내려오지만 나중에 S3 로 옮길 때 서버 값만 바꾸면
  /// 앱을 다시 내보내지 않고도 넘어갈 수 있다.
  final String imageUrl;

  /// 이 아이템이 열리는 레벨. 못 가진 아이템에 이 숫자를 보여 준다.
  ///
  /// **null 이면 레벨로는 열리지 않는다.** 미션 보상처럼 다른 조건으로만 얻는
  /// 것들이다. 0 으로 깔아 두면 "Lv.0 부터"라는 없는 말을 화면에 쓰게 된다.
  final int? requiredLevel;

  /// 세트로 묶인 아이템이면 그 세트 키. 아니면 null 이다.
  final String? setId;

  /// 같이 걸 수 없는 아이템들의 키.
  ///
  /// 슬롯이 달라도 겹쳐 그리면 이상해지는 조합이 있다(모자와 왕관처럼). 이쪽을
  /// 걸면 저쪽은 내려야 한다.
  final List<String> conflictsWith;

  /// 지금 사용자가 가지고 있는지.
  final bool owned;

  const CosmeticItemModel({
    required this.itemKey,
    required this.slot,
    required this.nameKo,
    required this.imageUrl,
    required this.requiredLevel,
    required this.setId,
    required this.conflictsWith,
    required this.owned,
  });

  /// 한 건을 읽는다. 키나 슬롯이 없으면 쓸 수 없는 줄이라 null 이다.
  static CosmeticItemModel? fromJsonOrNull(Object? json) {
    if (json is! Map) return null;

    final itemKey = json['itemKey'];
    final slot = json['slot'];
    if (itemKey is! String || itemKey.isEmpty) return null;
    if (slot is! String || slot.isEmpty) return null;

    final setId = json['setId'];

    return CosmeticItemModel(
      itemKey: itemKey,
      slot: slot,
      nameKo: json['nameKo'] is String && (json['nameKo'] as String).isNotEmpty
          ? json['nameKo'] as String
          : itemKey,
      imageUrl: json['imageUrl'] is String ? json['imageUrl'] as String : '',
      requiredLevel: _asInt(json['requiredLevel']),
      setId: setId is String && setId.isNotEmpty ? setId : null,
      conflictsWith: _asStringList(json['conflictsWith']),
      owned: json['owned'] == true,
    );
  }

  /// 이 아이템을 걸 수 있는지. 가지고 있지 않으면 못 건다.
  bool get isEquippable => owned;

  /// 레벨을 올리면 언젠가 열리는 것인지. 아니면 미션 보상이다.
  bool get unlocksByLevel => requiredLevel != null;

  /// 이 레벨에서 열려 있는지.
  bool isUnlockedAt(int level) {
    final required = requiredLevel;
    return required != null && required <= level;
  }

  CosmeticItemModel copyWith({bool? owned}) {
    return CosmeticItemModel(
      itemKey: itemKey,
      slot: slot,
      nameKo: nameKo,
      imageUrl: imageUrl,
      requiredLevel: requiredLevel,
      setId: setId,
      conflictsWith: conflictsWith,
      owned: owned ?? this.owned,
    );
  }

  static List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return [
      for (final entry in value)
        if (entry is String && entry.isNotEmpty) entry,
    ];
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() => 'CosmeticItemModel($itemKey, $slot)';
}

/// 미션 보상으로 이번에 열린 아이템 한 건이다.
///
/// `MissionClaimResponseDto.unlockedCosmetics` 에 실려 온다. 옷장의
/// [CosmeticItemModel] 보다 필드가 적다. 해금 연출에 필요한 것만 온다.
class CosmeticUnlockModel {
  final String itemKey;
  final String nameKo;
  final String slot;
  final String imageUrl;

  const CosmeticUnlockModel({
    required this.itemKey,
    required this.nameKo,
    required this.slot,
    required this.imageUrl,
  });

  static CosmeticUnlockModel? fromJsonOrNull(Object? json) {
    if (json is! Map) return null;

    final itemKey = json['itemKey'];
    if (itemKey is! String || itemKey.isEmpty) return null;

    final slot = json['slot'];

    return CosmeticUnlockModel(
      itemKey: itemKey,
      nameKo: json['nameKo'] is String && (json['nameKo'] as String).isNotEmpty
          ? json['nameKo'] as String
          : itemKey,
      slot: slot is String ? slot : '',
      imageUrl: json['imageUrl'] is String ? json['imageUrl'] as String : '',
    );
  }

  /// 여러 건을 읽는다. 읽지 못한 줄은 버린다.
  static List<CosmeticUnlockModel> listFrom(Object? json) {
    if (json is! List) return const [];
    return [
      for (final entry in json)
        if (fromJsonOrNull(entry) case final item?) item,
    ];
  }

  @override
  String toString() => 'CosmeticUnlockModel($itemKey, $slot)';
}
