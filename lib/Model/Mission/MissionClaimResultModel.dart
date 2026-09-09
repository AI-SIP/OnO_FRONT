import 'MissionModel.dart';

/// `POST /api/missions/{progressId}/claim` 의 응답이다.
///
/// [rewardType] 은 모르는 값이 올 수 있어 nullable 이다. 받기 자체는 이미
/// 성공한 뒤이므로, 종류를 모른다고 결과를 통째로 버리지 않는다. 이 경우
/// 화면은 XP 문구 대신 일반적인 문구를 띄운다.
class MissionClaimResultModel {
  final int progressId;
  final MissionRewardType? rewardType;
  final int rewardValue;

  /// 받은 뒤의 학습 레벨.
  final int? totalStudyLevel;

  /// 이번 보상으로 레벨이 올랐는지.
  final bool leveledUp;

  const MissionClaimResultModel({
    required this.progressId,
    required this.rewardType,
    required this.rewardValue,
    required this.totalStudyLevel,
    required this.leveledUp,
  });

  static MissionClaimResultModel? fromJsonOrNull(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    final progressId = _asInt(json['progressId']);
    if (progressId == null) return null;

    return MissionClaimResultModel(
      progressId: progressId,
      rewardType: MissionRewardType.from(json['rewardType'] as String?),
      rewardValue: _asInt(json['rewardValue']) ?? 0,
      totalStudyLevel: _asInt(json['totalStudyLevel']),
      leveledUp: (json['leveledUp'] as bool?) ?? false,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
