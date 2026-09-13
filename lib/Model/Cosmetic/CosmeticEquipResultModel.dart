import 'CosmeticLoadoutModel.dart';

/// 장착·해제 요청의 응답이다.
///
/// `PUT /api/cosmetics/equip`, `/equip-set`, `/equip-all` 이 모두 이 모양으로
/// 답한다. 한 자리만 바꿔 달라고 했어도 **차림 전체**가 돌아온다. 서버가
/// 겹치는 것을 함께 내리거나 못 가진 것을 걷어 낼 수 있어서, 요청만 보고는
/// 결과를 알 수 없기 때문이다.
///
/// 그래서 이 응답은 앱이 되돌아갈 기준이기도 하다. 저장에 실패했을 때
/// 되돌릴 곳은 마지막으로 서버가 준 [equipped] 다.
class CosmeticEquipResultModel {
  /// 이 요청 뒤의 차림 전체. 슬롯 키 → 아이템 키.
  final Map<String, String> equipped;

  /// 이번에 **서버가 벗긴** 자리들.
  ///
  /// 겹쳐 걸 수 없는 것을 걸었거나, 못 가진 것이 섞여 있었을 때 채워져 온다.
  /// 비어 있지 않으면 사용자에게 알려야 한다. 저장을 눌렀는데 고른 것 중
  /// 일부가 조용히 사라지면 저장이 안 된 것으로 읽힌다.
  final List<String> unequippedSlots;

  const CosmeticEquipResultModel({
    required this.equipped,
    required this.unequippedSlots,
  });

  /// 한 건을 읽는다. 맵이 아니면 쓸 수 없는 응답이라 null 이다.
  static CosmeticEquipResultModel? fromJsonOrNull(Object? json) {
    if (json is! Map) return null;

    return CosmeticEquipResultModel(
      equipped: CosmeticLoadoutModel.equippedFrom(json['equipped']),
      unequippedSlots: _slotsFrom(json['unequippedSlots']),
    );
  }

  static List<String> _slotsFrom(Object? json) {
    if (json is! List) return const [];
    return [
      for (final entry in json)
        if (entry is String && entry.isNotEmpty) entry,
    ];
  }

  @override
  String toString() =>
      'CosmeticEquipResultModel($equipped, 벗김 $unequippedSlots)';
}
