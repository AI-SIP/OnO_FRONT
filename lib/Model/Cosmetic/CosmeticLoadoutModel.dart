import 'CosmeticItemModel.dart';
import 'CosmeticSlotModel.dart';

/// 겹쳐 그릴 그림 한 장이다.
///
/// 모든 파츠가 같은 좌표계(512×512)로 그려져 있어서 위치를 계산할 필요가 없다.
/// 같은 크기로 포개면 맞는다.
class CosmeticLayerModel {
  /// 그림의 위치. `http` 로 시작하면 네트워크, 아니면 에셋이다.
  final String imageUrl;

  /// 작을수록 뒤에 깔린다.
  final int layerOrder;

  /// 이 층이 어느 슬롯의 것인지. 개구리 본체면 null 이다.
  final String? slot;

  /// 이 층이 어느 아이템의 것인지. 개구리 본체면 null 이다.
  final String? itemKey;

  const CosmeticLayerModel({
    required this.imageUrl,
    required this.layerOrder,
    this.slot,
    this.itemKey,
  });

  /// 개구리 본체인지.
  bool get isBase => itemKey == null;

  @override
  String toString() => 'CosmeticLayerModel($itemKey ?? BASE, $layerOrder)';
}

/// `GET /api/cosmetics` 의 응답 전체다.
///
/// 개구리는 이제 레벨마다 그림이 바뀌지 않는다. 고정 포즈 한 장(`BASE`) 위에
/// 치장 파츠를 겹쳐 그린다. 슬롯 목록, 레이어 순서, 아이템 정의가 전부 여기에
/// 들어 있고 앱에는 아무것도 박혀 있지 않다.
class CosmeticLoadoutModel {
  /// 서버가 아직 아무것도 주지 못했을 때 쓰는 개구리 한 장.
  ///
  /// 로그인 직후나 이 API 가 배포되기 전에도 개구리 자리가 비어 있으면 안 된다.
  /// **기본값이지 기준값이 아니다.** 서버가 [baseImageUrl] 을 주면 그쪽을 쓴다.
  static const String defaultBaseImageUrl = 'assets/Cosmetic/BASE.png';

  /// 머리만 있는 개구리.
  ///
  /// 전신 의상([CosmeticItemModel.fullBody])을 입었을 때 [defaultBaseImageUrl]
  /// 대신 깐다. 그 옷에는 소매와 바짓단이 이미 그려져 있어서, 전신 개구리를
  /// 뒤에 두면 원래 팔다리가 옷 밖으로 삐져나온다.
  static const String defaultBaseHeadImageUrl = 'assets/Cosmetic/BASE_HEAD.png';

  /// 고정 포즈 개구리 그림.
  final String baseImageUrl;

  /// 걸 수 있는 자리들. 서버가 준 순서를 그대로 들고 있는다.
  ///
  /// 옷장의 탭 순서가 이 순서다. 정렬하지 않는다. 무엇을 먼저 보여 줄지는
  /// 서버가 정하는 편이 낫다.
  final List<CosmeticSlotModel> slots;

  /// 아이템 전부. 가진 것과 아직 못 가진 것이 함께 온다.
  final List<CosmeticItemModel> items;

  /// 지금 걸려 있는 것. 슬롯 키 → 아이템 키다.
  final Map<String, String> equipped;

  /// 개구리 본체를 몇 번째 층에 둘지.
  ///
  /// 서버가 `baseLayerOrder` 를 주면 그 값이다. **주지 않으면** 슬롯 중 가장
  /// 작은 [CosmeticSlotModel.layerOrder] 와 같은 층에 두고, 같은 층에서는
  /// 슬롯을 먼저 그린다. 가장 뒤에 깔리는 슬롯은 배경이고 개구리는 그 앞에
  /// 서기 때문이다. 슬롯이 하나도 없으면 0 이다.
  ///
  /// 이 추측이 필요 없게 하려면 서버가 `baseLayerOrder` 를 내려주면 된다.
  final int? baseLayerOrder;

  const CosmeticLoadoutModel({
    required this.baseImageUrl,
    required this.slots,
    required this.items,
    required this.equipped,
    this.baseLayerOrder,
  });

  /// 서버가 아직 아무것도 주지 못했을 때의 차림. 개구리 한 장뿐이다.
  static const CosmeticLoadoutModel empty = CosmeticLoadoutModel(
    baseImageUrl: defaultBaseImageUrl,
    slots: [],
    items: [],
    equipped: {},
  );

  static CosmeticLoadoutModel? fromJsonOrNull(Object? json) {
    if (json is! Map) return null;

    final baseImageUrl = json['baseImageUrl'];

    return CosmeticLoadoutModel(
      baseImageUrl: baseImageUrl is String && baseImageUrl.isNotEmpty
          ? baseImageUrl
          : defaultBaseImageUrl,
      slots: _slotsFrom(json['slots']),
      items: _itemsFrom(json['items']),
      equipped: equippedFrom(json['equipped']),
      baseLayerOrder: _asInt(json['baseLayerOrder']),
    );
  }

  static List<CosmeticSlotModel> _slotsFrom(Object? json) {
    if (json is! List) return const [];
    return [
      for (final entry in json)
        if (CosmeticSlotModel.fromJsonOrNull(entry) case final slot?) slot,
    ];
  }

  static List<CosmeticItemModel> _itemsFrom(Object? json) {
    if (json is! List) return const [];
    return [
      for (final entry in json)
        if (CosmeticItemModel.fromJsonOrNull(entry) case final item?) item,
    ];
  }

  /// `equipped` 맵을 읽는다. 장착/해제 응답도 이 모양이라 함께 쓴다.
  ///
  /// 값이 null 인 칸은 "그 자리에 아무것도 없다"는 뜻이라 빼고 담는다.
  static Map<String, String> equippedFrom(Object? json) {
    if (json is! Map) return const {};

    final result = <String, String>{};
    json.forEach((key, value) {
      if (key is! String || key.isEmpty) return;
      if (value is! String || value.isEmpty) return;
      result[key] = value;
    });
    return result;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 슬롯 키로 슬롯을 찾는다. 없으면 null 이다.
  CosmeticSlotModel? slotOf(String slot) {
    for (final entry in slots) {
      if (entry.slot == slot) return entry;
    }
    return null;
  }

  /// 아이템 키로 아이템을 찾는다. 없으면 null 이다.
  CosmeticItemModel? itemOf(String? itemKey) {
    if (itemKey == null) return null;
    for (final item in items) {
      if (item.itemKey == itemKey) return item;
    }
    return null;
  }

  /// 이 슬롯에 들어가는 아이템들. 서버가 준 순서를 지킨다.
  List<CosmeticItemModel> itemsOfSlot(String slot) => [
        for (final item in items)
          if (item.slot == slot) item
      ];

  /// 이 슬롯에 지금 걸려 있는 아이템 키. 없으면 null 이다.
  String? equippedItemKeyOf(String slot) => equipped[slot];

  /// 이 세트에 묶인 아이템들.
  List<CosmeticItemModel> itemsOfSet(String setId) => [
        for (final item in items)
          if (item.setId == setId) item
      ];

  /// 개구리 본체를 두는 층. [baseLayerOrder] 의 설명대로 정한다.
  int get resolvedBaseLayerOrder {
    final given = baseLayerOrder;
    if (given != null) return given;
    if (slots.isEmpty) return 0;

    var lowest = slots.first.layerOrder;
    for (final slot in slots) {
      if (slot.layerOrder < lowest) lowest = slot.layerOrder;
    }
    return lowest;
  }

  /// 지금 차림을 뒤에서 앞 순서로 펼친다.
  ///
  /// 개구리 본체와 걸려 있는 파츠를 [CosmeticSlotModel.layerOrder] 오름차순으로
  /// 놓는다. 같은 층이면 서버가 준 순서를 지키고, 본체는 같은 층의 슬롯보다
  /// 뒤에 그린다.
  ///
  /// 서버가 지운 아이템이나 앱이 모르는 슬롯이 `equipped` 에 남아 있으면 그
  /// 칸만 조용히 건너뛴다. 그림 한 장 때문에 개구리가 통째로 안 그려지면 안 된다.
  ///
  /// [extra] 를 주면 그 아이템들도 함께 걸어 그린다. 해금 연출에서 방금 얻은
  /// 것을 서버 왕복 없이 미리 입혀 보여 주는 데 쓴다.
  List<CosmeticLayerModel> resolveLayers({
    Map<String, String>? equippedOverride,
    List<CosmeticUnlockModel> extra = const [],
  }) {
    final current = equippedOverride ?? equipped;

    // 전신 의상을 입고 있으면 본체를 머리만 있는 그림으로 바꾼다. 자리마다
    // 하나씩만 걸리므로 그런 옷은 많아야 하나다.
    final wearsFullBody = current.values.any(
      (itemKey) => itemOf(itemKey)?.fullBody ?? false,
    );
    final resolvedBaseImageUrl =
        wearsFullBody && baseImageUrl == defaultBaseImageUrl
            ? defaultBaseHeadImageUrl
            : baseImageUrl;

    // (층, 같은 층 안에서의 순서) 로 정렬한다. Dart 의 sort 는 안정 정렬이
    // 아니라서 같은 값이 나오면 순서가 흐트러진다. 순번을 직접 매긴다.
    final entries = <_OrderedLayer>[];
    var sequence = 0;

    entries.add(
      _OrderedLayer(
        order: resolvedBaseLayerOrder,
        // 같은 층에서는 슬롯(0)을 먼저 그리고 본체(1)를 그 위에 올린다.
        tieBreak: 1,
        sequence: sequence++,
        layer: CosmeticLayerModel(
          imageUrl: resolvedBaseImageUrl,
          layerOrder: resolvedBaseLayerOrder,
        ),
      ),
    );

    for (final slot in slots) {
      final itemKey = current[slot.slot];
      final item = itemOf(itemKey);
      if (item == null || item.imageUrl.isEmpty) continue;

      entries.add(
        _OrderedLayer(
          order: slot.layerOrder,
          tieBreak: 0,
          sequence: sequence++,
          layer: CosmeticLayerModel(
            imageUrl: item.imageUrl,
            layerOrder: slot.layerOrder,
            slot: slot.slot,
            itemKey: item.itemKey,
          ),
        ),
      );
    }

    for (final unlock in extra) {
      if (unlock.imageUrl.isEmpty) continue;
      // 같은 아이템이 이미 걸려 있으면 두 번 그리지 않는다.
      if (entries.any((entry) => entry.layer.itemKey == unlock.itemKey)) {
        continue;
      }

      final slot = slotOf(unlock.slot);
      entries.add(
        _OrderedLayer(
          // 슬롯을 모르면 맨 앞에 둔다. 새로 얻은 것은 보여야 한다.
          order: slot?.layerOrder ?? _maxLayerOrder + 1,
          tieBreak: 0,
          sequence: sequence++,
          layer: CosmeticLayerModel(
            imageUrl: unlock.imageUrl,
            layerOrder: slot?.layerOrder ?? _maxLayerOrder + 1,
            slot: unlock.slot,
            itemKey: unlock.itemKey,
          ),
        ),
      );
    }

    entries.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      final byTie = a.tieBreak.compareTo(b.tieBreak);
      if (byTie != 0) return byTie;
      return a.sequence.compareTo(b.sequence);
    });

    return [for (final entry in entries) entry.layer];
  }

  int get _maxLayerOrder {
    var max = resolvedBaseLayerOrder;
    for (final slot in slots) {
      if (slot.layerOrder > max) max = slot.layerOrder;
    }
    return max;
  }

  /// `equipped` 만 갈아 끼운 새 차림.
  CosmeticLoadoutModel withEquipped(Map<String, String> next) {
    return CosmeticLoadoutModel(
      baseImageUrl: baseImageUrl,
      slots: slots,
      items: items,
      equipped: Map<String, String>.unmodifiable(next),
      baseLayerOrder: baseLayerOrder,
    );
  }

  /// 이 아이템들을 가진 것으로 바꾼 새 차림.
  ///
  /// 미션 보상으로 방금 열린 아이템을 서버에 다시 묻지 않고도 옷장에서 바로
  /// 쓸 수 있게 한다. 다음 조회가 오면 서버 값으로 덮인다.
  CosmeticLoadoutModel withOwned(Iterable<String> itemKeys) {
    final keys = itemKeys.toSet();
    if (keys.isEmpty) return this;

    return CosmeticLoadoutModel(
      baseImageUrl: baseImageUrl,
      slots: slots,
      items: [
        for (final item in items)
          keys.contains(item.itemKey) && !item.owned
              ? item.copyWith(owned: true)
              : item,
      ],
      equipped: equipped,
      baseLayerOrder: baseLayerOrder,
    );
  }
}

/// 정렬하는 동안만 쓰는 묶음.
class _OrderedLayer {
  final int order;
  final int tieBreak;
  final int sequence;
  final CosmeticLayerModel layer;

  const _OrderedLayer({
    required this.order,
    required this.tieBreak,
    required this.sequence,
    required this.layer,
  });
}
