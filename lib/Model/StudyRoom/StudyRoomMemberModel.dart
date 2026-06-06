class StudyRoomMemberModel {
  final int userId;
  final String name;
  final int totalStudyLevel;
  final int currentStreak;
  final int weeklyProblemCount;
  final int weeklyPracticeCount;
  final int? weeklyGoal;
  final int? goalProgress;

  const StudyRoomMemberModel({
    required this.userId,
    required this.name,
    required this.totalStudyLevel,
    required this.currentStreak,
    required this.weeklyProblemCount,
    required this.weeklyPracticeCount,
    this.weeklyGoal,
    this.goalProgress,
  });
}
