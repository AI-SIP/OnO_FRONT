/// 미션이 하루짜리인지 한 주짜리인지.
///
/// 서버가 내려주는 문자열을 그대로 쓴다. 나중에 서버에 종류가 늘어날 수
/// 있으므로 모르는 값이 오면 [from] 이 null 을 돌려주고, 그 미션은 목록에서
/// 건너뛴다. 구버전 앱이 새 미션 때문에 죽는 것을 막는 것이 목적이다.
enum MissionCategory {
  daily('DAILY'),
  weekly('WEEKLY');

  const MissionCategory(this.raw);

  /// 서버가 쓰는 문자열.
  final String raw;

  static MissionCategory? from(String? value) {
    if (value == null) return null;
    final normalized = value.toUpperCase();
    return MissionCategory.values
        .cast<MissionCategory?>()
        .firstWhere((e) => e!.raw == normalized, orElse: () => null);
  }
}

/// 미션 보상의 종류.
///
/// 1차는 XP 뿐이다. 테마나 칭호가 2차에 붙으면 여기에 값이 는다.
/// [MissionCategory] 와 같은 이유로 모르는 값은 null 이다.
enum MissionRewardType {
  xp('XP');

  const MissionRewardType(this.raw);

  final String raw;

  static MissionRewardType? from(String? value) {
    if (value == null) return null;
    final normalized = value.toUpperCase();
    return MissionRewardType.values
        .cast<MissionRewardType?>()
        .firstWhere((e) => e!.raw == normalized, orElse: () => null);
  }
}

/// 미션 한 줄이다.
///
/// [progressId] 는 진행도 행이 아직 없을 때 서버가 비워 보낼 수 있다.
/// 받기는 이 값이 있어야 부를 수 있으므로 nullable 로 둔다. 서버 계약상
/// 완료된 미션에는 반드시 들어 있다.
class MissionModel {
  final int? progressId;
  final String code;
  final String title;
  final String description;

  /// 아이콘 에셋을 고르는 키. 모르는 키는 화면에서 기본 아이콘으로 떨어진다.
  final String iconKey;
  final MissionCategory category;
  final int current;
  final int target;
  final bool completed;
  final bool claimed;
  final MissionRewardType rewardType;
  final int rewardValue;

  const MissionModel({
    required this.progressId,
    required this.code,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.category,
    required this.current,
    required this.target,
    required this.completed,
    required this.claimed,
    required this.rewardType,
    required this.rewardValue,
  });

  /// 읽을 수 없는 미션이면 null 을 돌려준다.
  ///
  /// 모르는 [category] 나 [rewardType] 이 오면 그 미션만 버린다. 예외를 던지면
  /// 서버가 미션을 하나 추가한 순간 구버전 앱의 미션 화면이 통째로 비어 버린다.
  static MissionModel? fromJsonOrNull(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    final category = MissionCategory.from(json['category'] as String?);
    if (category == null) return null;

    final rewardType = MissionRewardType.from(json['rewardType'] as String?);
    if (rewardType == null) return null;

    final code = (json['code'] as String?) ?? '';
    if (code.isEmpty) return null;

    return MissionModel(
      progressId: _asInt(json['progressId']),
      code: code,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      iconKey: (json['iconKey'] as String?) ?? 'default',
      category: category,
      current: _asInt(json['current']) ?? 0,
      target: _asInt(json['target']) ?? 0,
      completed: (json['completed'] as bool?) ?? false,
      claimed: (json['claimed'] as bool?) ?? false,
      rewardType: rewardType,
      rewardValue: _asInt(json['rewardValue']) ?? 0,
    );
  }

  /// 0 과 1 사이의 진행률. 진행바 길이에 쓴다.
  double get progressRatio {
    if (target <= 0) return completed ? 1.0 : 0.0;
    return (current / target).clamp(0.0, 1.0);
  }

  /// 완료했는데 아직 안 받은 것. 받기 버튼이 열리는 조건이다.
  bool get isClaimable => completed && !claimed && progressId != null;

  MissionModel copyWith({bool? claimed}) {
    return MissionModel(
      progressId: progressId,
      code: code,
      title: title,
      description: description,
      iconKey: iconKey,
      category: category,
      current: current,
      target: target,
      completed: completed,
      claimed: claimed ?? this.claimed,
      rewardType: rewardType,
      rewardValue: rewardValue,
    );
  }

  /// 서버가 정수를 문자열이나 double 로 흘려도 읽는다.
  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
