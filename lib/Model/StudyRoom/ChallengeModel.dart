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

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  int get clearedCount => memberProgress.where((m) => m.cleared).length;
}
