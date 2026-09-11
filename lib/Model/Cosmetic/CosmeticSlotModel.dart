/// 개구리에 무언가를 걸 수 있는 자리 하나다.
///
/// 어떤 자리가 있는지, 어느 순서로 겹쳐 그릴지를 **전부 서버가 정한다.** 소품과
/// 옷은 계속 늘어날 예정이라 앱에 목록을 박아 두면 새 슬롯이 생길 때마다 앱을
/// 다시 내보내야 한다.
class CosmeticSlotModel {
  /// 서버가 쓰는 슬롯 키. `HEAD`, `BACKGROUND` 같은 값이다.
  ///
  /// 앱은 이 값을 해석하지 않는다. 맵의 키와 아이템의 소속을 맞추는 데만 쓴다.
  final String slot;

  /// 겹쳐 그리는 순서. 작을수록 뒤에 깔린다.
  final int layerOrder;

  /// 화면에 보여 줄 이름. `배경`, `머리` 처럼 사용자가 읽는 말이다.
  final String nameKo;

  const CosmeticSlotModel({
    required this.slot,
    required this.layerOrder,
    required this.nameKo,
  });

  /// 한 건을 읽는다. 슬롯 키가 없으면 쓸 수 없는 줄이라 null 이다.
  ///
  /// 모르는 필드가 섞여 오거나 타입이 어긋나도 그 한 줄만 버린다. 슬롯 하나
  /// 때문에 옷장 전체가 안 뜨는 쪽이 더 나쁘다.
  static CosmeticSlotModel? fromJsonOrNull(Object? json) {
    if (json is! Map) return null;

    final slot = json['slot'];
    if (slot is! String || slot.isEmpty) return null;

    return CosmeticSlotModel(
      slot: slot,
      layerOrder: _asInt(json['layerOrder']) ?? 0,
      nameKo: json['nameKo'] is String && (json['nameKo'] as String).isNotEmpty
          ? json['nameKo'] as String
          : slot,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() => 'CosmeticSlotModel($slot, $layerOrder)';
}
