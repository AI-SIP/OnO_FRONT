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

    final periodKey = json['periodKey'];
    return MissionGroupModel(
      periodKey: periodKey is String ? periodKey : '',
      missions: missions,
    );
  }

  int get completedCount => missions.where((m) => m.completed).length;

  int get claimableCount => missions.where((m) => m.isClaimable).length;
}

/// `GET /api/missions` 응답 전체다.
///
/// 일일, 주간, 그리고 지난 기간에 완료했지만 아직 받지 않은 [expired] 세
/// 묶음으로 온다. [expired] 가 없으면 기간을 넘긴 미수령 보상을 꺼낼 방법이
/// 없다. 일요일 밤에 주간 미션을 채우고 앱을 닫으면 월요일에 사라진다.
class MissionBoardModel {
  final MissionGroupModel daily;
  final MissionGroupModel weekly;

  /// 지난 기간에 완료했지만 아직 안 받은 미션들.
  ///
  /// 여러 기간이 섞이므로 묶음의 `periodKey` 는 비어 있고, 기간은 미션마다
  /// 붙어 온다. 백엔드에 아직 이 그룹이 없을 수 있어서 키가 없으면 빈 묶음이다.
  final MissionGroupModel expired;

  const MissionBoardModel({
    required this.daily,
    required this.weekly,
    this.expired = MissionGroupModel.empty,
  });

  factory MissionBoardModel.fromJson(Map<String, dynamic> json) {
    return MissionBoardModel(
      daily: MissionGroupModel.fromJson(json['daily']),
      weekly: MissionGroupModel.fromJson(json['weekly']),
      expired: MissionGroupModel.fromJson(json['expired']),
    );
  }

  /// 보여 줄 미션이 하나도 없으면 배너와 화면을 숨긴다.
  ///
  /// 지난 미션만 남아 있어도 보여 줘야 한다. 그게 받을 수 있는 보상이다.
  bool get isEmpty =>
      daily.missions.isEmpty &&
      weekly.missions.isEmpty &&
      expired.missions.isEmpty;

  int get claimableCount =>
      daily.claimableCount + weekly.claimableCount + expired.claimableCount;

  /// 받기 결과를 반영해 그 미션만 바꾼 새 보드를 만든다.
  MissionBoardModel markClaimed(int progressId) {
    return MissionBoardModel(
      daily: _markGroup(daily, progressId),
      weekly: _markGroup(weekly, progressId),
      expired: _markGroup(expired, progressId),
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
