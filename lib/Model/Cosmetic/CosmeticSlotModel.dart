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

  /// 개구리 합성에 들어가는 자리인지.
  ///
  /// **false 면 개구리 그림에 겹치지 않는다.** `FRAME` 처럼 원형 프로필 사진
  /// 둘레에만 두르는 자리가 그렇다. [layerOrder] 가 있어도 그건 그 자리들끼리의
  /// 순서일 뿐이라, 이 값을 안 보면 프로필 테두리가 개구리 얼굴 위를 덮는다.
  ///
  /// 서버가 안 내려주면 true 다. 겹쳐 그리는 것이 여태까지의 모든 자리이고,
  /// 새 자리가 생겼다고 개구리가 헐벗는 쪽이 더 나쁘다.
  final bool composited;

  const CosmeticSlotModel({
    required this.slot,
    required this.layerOrder,
    required this.nameKo,
    this.composited = true,
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
      composited:
          json['composited'] is bool ? json['composited'] as bool : true,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() => 'CosmeticSlotModel($slot, $layerOrder, 합성 $composited)';
}
