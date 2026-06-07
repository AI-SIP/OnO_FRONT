import 'ChallengeMemberProgressModel.dart';

class ChallengeModel {
  final int challengeId;
  final String title;
  final String type; // individual | group | streak
  final String metric; // weekly_problem_count | weekly_practice_count | streak
  final int targetValue;
  final DateTime endAt;
  String status; // in_progress | completed | failed | expired
  final List<ChallengeMemberProgressModel> memberProgress;
  final int? groupCurrent;

  ChallengeModel({
    required this.challengeId,
    required this.title,
    required this.type,
    required this.metric,
    required this.targetValue,
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
      metric: (json['metric'] ?? 'weekly_problem_count').toString(),
      targetValue: ((json['targetValue'] ?? 0) as num).toInt(),
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
