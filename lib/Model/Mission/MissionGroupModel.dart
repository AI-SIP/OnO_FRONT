import 'MissionModel.dart';

/// 한 기간(오늘 하루, 이번 주)의 미션 묶음이다.
///
/// [periodKey] 는 일일이 `2026-09-09`, 주간이 `2026-W37` 이다. 서버가 이 키로
/// 기간을 가르기 때문에 앱은 리셋을 계산하지 않는다.
class MissionGroupModel {
  final String periodKey;
  final List<MissionModel> missions;

  const MissionGroupModel({
    required this.periodKey,
    required this.missions,
  });

  static const MissionGroupModel empty =
      MissionGroupModel(periodKey: '', missions: []);

  /// 읽지 못한 미션은 조용히 빠진다. 나머지는 그대로 살린다.
  factory MissionGroupModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return empty;

    final rawMissions = json['missions'];
    final missions = rawMissions is List
        ? rawMissions
            .map(MissionModel.fromJsonOrNull)
            .whereType<MissionModel>()
            .toList()
        : <MissionModel>[];

    return MissionGroupModel(
      periodKey: (json['periodKey'] as String?) ?? '',
      missions: missions,
    );
  }

  int get completedCount => missions.where((m) => m.completed).length;

  int get claimableCount => missions.where((m) => m.isClaimable).length;
}

/// `GET /api/missions` 응답 전체다. 일일과 주간 두 묶음으로 온다.
class MissionBoardModel {
  final MissionGroupModel daily;
  final MissionGroupModel weekly;

  const MissionBoardModel({
    required this.daily,
    required this.weekly,
  });

  factory MissionBoardModel.fromJson(Map<String, dynamic> json) {
    return MissionBoardModel(
      daily: MissionGroupModel.fromJson(json['daily']),
      weekly: MissionGroupModel.fromJson(json['weekly']),
    );
  }

  /// 보여 줄 미션이 하나도 없으면 배너와 화면을 숨긴다.
  bool get isEmpty => daily.missions.isEmpty && weekly.missions.isEmpty;

  int get claimableCount => daily.claimableCount + weekly.claimableCount;

  /// 받기 결과를 반영해 그 미션만 바꾼 새 보드를 만든다.
  MissionBoardModel markClaimed(int progressId) {
    return MissionBoardModel(
      daily: _markGroup(daily, progressId),
      weekly: _markGroup(weekly, progressId),
    );
  }

  static MissionGroupModel _markGroup(MissionGroupModel group, int progressId) {
    return MissionGroupModel(
      periodKey: group.periodKey,
      missions: group.missions
          .map(
              (m) => m.progressId == progressId ? m.copyWith(claimed: true) : m)
          .toList(),
    );
  }
}
