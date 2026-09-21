/// 훈장 한 개다. `GET /api/achievements` 의 `achievements` 한 줄과 같다.
///
/// 레벨과 치장은 "얼마나 많이 했나" 하나로 뭉뚱그린다. 오답노트를 백 개 모은
/// 것도, 틀렸던 문제를 기어이 맞힌 것도, 서른 날을 안 빼먹은 것도 전부 같은
/// 포인트가 된다. 훈장은 그런 순간을 따로 남기는 자리라, 이름과 설명과 조건이
/// 훈장마다 다르고 **그 말은 전부 서버가 준다.** 앱에는 목록이 박혀 있지 않다.
/// 문서 `docs/훈장/훈장표.md` 가 계약이고 서버 시드가 거기서 나온다.
class AchievementModel {
  /// 서버와 앱이 같이 쓰는 식별자. `archivist` 처럼 소문자다.
  final String key;

  /// 화면에 적는 이름. `기록광`.
  final String nameKo;

  /// 화면에 적는 한 줄 설명. `오답노트를 100개 작성했어요`.
  final String descriptionKo;

  /// 훈장 그림. 치장과 같이 **앱 번들 경로**(`assets/Medal/<key>.png`)다.
  final String imageUrl;

  /// 받았는지.
  final bool earned;

  /// 언제 받았는지. 아직 못 받았으면 null 이다.
  final DateTime? earnedAt;

  /// 지금 몇까지 왔는지. 진행도가 없는 훈장이면 null 이다.
  final int? current;

  /// 몇이면 받는지. 진행도가 없는 훈장이면 null 이다.
  ///
  /// **불사조와 첫 걸음은 둘 다 null 로 온다.** 0 아니면 1이라 눈금으로
  /// 보여 줄 것이 없다. 그 둘을 진행도가 있는 것과 같은 틀에 넣으면 늘 비어
  /// 있거나 늘 가득 찬 눈금이 남는데, 빈 눈금은 "아직 하나도 못 했다"로
  /// 읽혀서 사실과 다른 말을 한다.
  final int? target;

  const AchievementModel({
    required this.key,
    required this.nameKo,
    required this.descriptionKo,
    required this.imageUrl,
    required this.earned,
    this.earnedAt,
    this.current,
    this.target,
  });

  /// 못 읽으면 null 이다. 한 줄이 깨져도 나머지 열한 개는 그려야 한다.
  ///
  /// [key] 가 없으면 그 줄은 통째로 버린다. 키가 없으면 그림 경로도 못 찾고
  /// 새로 받은 것과 맞춰 볼 수도 없어서 화면에 세울 자리가 없다.
  static AchievementModel? fromJsonOrNull(Object? json) {
    if (json is! Map) return null;

    final key = _asString(json['key']);
    if (key == null || key.isEmpty) return null;

    return AchievementModel(
      key: key,
      nameKo: _asString(json['nameKo']) ?? '',
      descriptionKo: _asString(json['descriptionKo']) ?? '',
      imageUrl: _asString(json['imageUrl']) ?? '',
      // 서버가 빠뜨렸으면 **못 받은 것으로 본다.** 없는 훈장을 받았다고
      // 말하는 쪽이 반대보다 나쁘다.
      earned: json['earned'] == true,
      earnedAt: _asDate(json['earnedAt']),
      current: _asInt(json['current']),
      target: _asInt(json['target']),
    );
  }

  /// 눈금으로 보여 줄 진행도가 있는지.
  ///
  /// 둘 다 있어야 한다. 한쪽만 오면 `87 / ?` 가 되어 말이 안 된다.
  bool get hasProgress => current != null && target != null && target! > 0;

  /// 0 에서 1 사이. 진행도가 없으면 받았을 때 1, 아니면 0 이다.
  double get progressRatio {
    if (!hasProgress) return earned ? 1.0 : 0.0;
    return (current! / target!).clamp(0.0, 1.0);
  }

  /// 몇이 남았는지. 진행도가 없거나 이미 넘었으면 0 이다.
  int get remaining {
    if (!hasProgress) return 0;
    final left = target! - current!;
    return left > 0 ? left : 0;
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 날짜를 읽는다. 서버가 `2026-09-14T01:23:45` 로 준다.
  ///
  /// 못 읽으면 null 이다. 날짜 한 줄 때문에 훈장이 사라지면 안 된다.
  static DateTime? _asDate(Object? value) {
    final raw = _asString(value);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  @override
  String toString() => 'AchievementModel($key, earned: $earned)';
}
