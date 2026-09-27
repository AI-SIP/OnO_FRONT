import 'CosmeticAbilityLevels.dart';

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
  /// 어느 능력치의 레벨인지는 [requiredAbility] 가 정한다. 둘은 늘 짝으로
  /// 읽어야 한다. 이 숫자만 떼어 놓으면 `Lv.9` 가 무엇의 9 인지 알 수 없다.
  final int requiredLevel;

  /// [requiredLevel] 을 어느 능력치에서 세는지. **null 이면 총 학습 레벨**이다.
  ///
  /// 예전에는 해금 기준이 총 학습 레벨 하나였다. 지금은 아이템마다 제 능력치가
  /// 있어서, 출석만 올린 사람에게는 배경과 효과가 열리고 복습만 한 사람에게는
  /// 안경과 모자가 열린다.
  final CosmeticAbility? requiredAbility;

  /// 세트로 묶인 아이템이면 그 세트 키. 아니면 null 이다.
  final String? setId;

  /// 세트 이름. [setId] 가 null 이면 이것도 null 이다.
  ///
  /// 키를 화면에 쓸 수는 없어서 이름이 따로 온다. 앱이 `graduate` 를 `학사
  /// 세트` 로 옮기는 표를 들고 있으면 세트가 하나 늘 때마다 앱을 다시 내보내야
  /// 한다.
  final String? setNameKo;

  /// 같이 걸 수 없는 아이템들의 키.
  ///
  /// 슬롯이 달라도 겹쳐 그리면 이상해지는 조합이 있다(모자와 왕관처럼). 이쪽을
  /// 걸면 저쪽은 내려야 한다.
  final List<String> conflictsWith;

  /// 지금 사용자가 가지고 있는지.
  final bool owned;

  /// 개구리 몸 전체를 덮는 의상인지.
  ///
  /// 소매와 바짓단까지 그려져 있어서, 뒤에 전신 개구리를 두면 원래 팔다리가
  /// 옷 밖으로 삐져나온다. 그래서 이런 옷을 입었을 때는 본체를 머리만 있는
  /// [CosmeticLoadoutModel.defaultBaseHeadImageUrl] 로 바꿔 깐다.
  final bool fullBody;

  /// 이 아이템만 따로 쓰는 그리는 층. 비어 있으면 자리의 값을 쓴다.
  ///
  /// **자리 하나에 그리는 층이 둘인 경우가 있다.** 가방이 그렇다. 등에 메는
  /// 배낭은 개구리 뒤(200)에, 앞으로 메는 가방은 옷 위(450)에 그려야 하는데
  /// 사용자에게는 둘 다 `가방` 한 자리다. 자리를 둘로 나누면 탭이 하나 늘고
  /// 그중 하나만 걸 수 있다는 것이 안 보인다. 자리는 하나로 두고 **아이템이
  /// 층만 덮어쓴다.**
  ///
  /// 서버가 `items[].layerOrder` 로 내려준다. 앱은 어떤 아이템이 예외인지
  /// 모른다. 그 판단은 그림을 그린 쪽이 한다.
  final int? layerOrder;

  const CosmeticItemModel({
    required this.itemKey,
    required this.slot,
    required this.nameKo,
    required this.imageUrl,
    required this.requiredLevel,
    required this.setId,
    required this.conflictsWith,
    required this.owned,
    this.requiredAbility,
    this.setNameKo,
    this.fullBody = false,
    this.layerOrder,
  });

  /// 한 건을 읽는다. 키나 슬롯이 없으면 쓸 수 없는 줄이라 null 이다.
  static CosmeticItemModel? fromJsonOrNull(Object? json) {
    if (json is! Map) return null;

    final itemKey = json['itemKey'];
    final slot = json['slot'];
    if (itemKey is! String || itemKey.isEmpty) return null;
    if (slot is! String || slot.isEmpty) return null;

    final setId = json['setId'];
    final setNameKo = json['setNameKo'];

    return CosmeticItemModel(
      itemKey: itemKey,
      slot: slot,
      nameKo: json['nameKo'] is String && (json['nameKo'] as String).isNotEmpty
          ? json['nameKo'] as String
          : itemKey,
      imageUrl: json['imageUrl'] is String ? json['imageUrl'] as String : '',
      // 레벨이 없으면 처음부터 열려 있는 것으로 본다. 실제로 가졌는지는
      // 서버가 `owned` 로 내려주므로, 이 값은 잠긴 칸에 조건을 적는 데만 쓴다.
      requiredLevel:
          _asInt(json['requiredLevel']) ?? CosmeticAbilityLevels.minLevel,
      requiredAbility: CosmeticAbility.fromKeyOrNull(json['requiredAbility']),
      setId: setId is String && setId.isNotEmpty ? setId : null,
      setNameKo: setId is String &&
              setId.isNotEmpty &&
              setNameKo is String &&
              setNameKo.isNotEmpty
          ? setNameKo
          : null,
      conflictsWith: _asStringList(json['conflictsWith']),
      owned: json['owned'] == true,
      fullBody: json['fullBody'] == true,
      layerOrder: _asInt(json['layerOrder']),
    );
  }

  /// 이 아이템을 그릴 층. 제 값이 있으면 그것을, 없으면 [slotOrder] 를 쓴다.
  int layerOrderOr(int slotOrder) => layerOrder ?? slotOrder;

  /// 이 아이템을 걸 수 있는지. 가지고 있지 않으면 못 건다.
  bool get isEquippable => owned;

  /// 이 레벨들에서 열려 있는지.
  ///
  /// 제 능력치의 레벨만 본다. 다른 능력치를 아무리 올려도 이쪽은 안 열린다.
  bool isUnlockedAt(CosmeticAbilityLevels levels) =>
      levels.levelOf(requiredAbility) >= requiredLevel;

  /// 열리기까지 이 능력치를 몇 레벨 더 올려야 하는지. 이미 열렸으면 0 이다.
  ///
  /// **"다음에 열릴 것"을 고르는 기준이다.** 필요 레벨만 비교하면 능력치가
  /// 섞였을 때 뜻이 어긋난다. 출석 Lv.3 짜리와 복습 Lv.4 짜리가 나란히 있어도
  /// 내 출석이 Lv.2 이고 복습이 Lv.10 이면 가까운 쪽은 출석이다.
  int remainingLevelsAt(CosmeticAbilityLevels levels) {
    final remaining = requiredLevel - levels.levelOf(requiredAbility);
    return remaining < 0 ? 0 : remaining;
  }

  CosmeticItemModel copyWith({bool? owned}) {
    return CosmeticItemModel(
      itemKey: itemKey,
      slot: slot,
      nameKo: nameKo,
      imageUrl: imageUrl,
      requiredLevel: requiredLevel,
      requiredAbility: requiredAbility,
      setId: setId,
      setNameKo: setNameKo,
      conflictsWith: conflictsWith,
      owned: owned ?? this.owned,
      fullBody: fullBody,
      layerOrder: layerOrder,
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
