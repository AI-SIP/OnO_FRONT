import 'ChallengeMemberProgressModel.dart';

class ChallengeModel {
  final int challengeId;
  final String title;
  final String type; // individual | group | streak
  final String metric; // problem_count | practice_count | attendance
  final String? period; // daily | weekly | monthly
  final int targetValue;
  final DateTime? startAt;
  final DateTime endAt;
  String status; // in_progress | completed | failed | expired
  final List<ChallengeMemberProgressModel> memberProgress;
  final int? groupCurrent;

  ChallengeModel({
    required this.challengeId,
    required this.title,
    required this.type,
    required this.metric,
    this.period,
    required this.targetValue,
    this.startAt,
    required this.endAt,
    required this.status,
    required this.memberProgress,
    this.groupCurrent,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    final progressJson = json['memberProgress'];
    return ChallengeModel(
      challengeId: ((json['challengeId'] ?? 0) as num).toInt(),
      title: (json['title'] ?? '').toString(),
      type: (json['type'] ?? 'individual').toString(),
      metric: (json['metric'] ?? 'problem_count').toString(),
      period: json['period']?.toString(),
      targetValue: ((json['targetValue'] ?? 0) as num).toInt(),
      startAt: DateTime.tryParse((json['startAt'] ?? '').toString()),
      endAt:
          DateTime.tryParse((json['endAt'] ?? '').toString()) ?? DateTime.now(),
      status: (json['status'] ?? 'in_progress').toString(),
      memberProgress: progressJson is List
          ? progressJson
              .whereType<Map<String, dynamic>>()
              .map(ChallengeMemberProgressModel.fromJson)
              .toList()
          : <ChallengeMemberProgressModel>[],
      groupCurrent: json['groupCurrent'] == null
          ? null
          : (json['groupCurrent'] as num).toInt(),
    );
  }

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  int get clearedCount => memberProgress.where((m) => m.cleared).length;
}
