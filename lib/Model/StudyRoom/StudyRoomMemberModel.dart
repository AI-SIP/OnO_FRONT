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

  factory StudyRoomMemberModel.fromJson(Map<String, dynamic> json) {
    return StudyRoomMemberModel(
      userId: ((json['userId'] ?? 0) as num).toInt(),
      name: (json['name'] ?? '알 수 없음').toString(),
      totalStudyLevel: ((json['totalStudyLevel'] ?? 1) as num).toInt(),
      currentStreak: ((json['currentStreak'] ?? 0) as num).toInt(),
      weeklyProblemCount: ((json['weeklyProblemCount'] ?? 0) as num).toInt(),
      weeklyPracticeCount: ((json['weeklyPracticeCount'] ?? 0) as num).toInt(),
      weeklyGoal: json['weeklyGoal'] == null
          ? null
          : (json['weeklyGoal'] as num).toInt(),
      goalProgress: json['goalProgress'] == null
          ? null
          : (json['goalProgress'] as num).toInt(),
    );
  }

  StudyRoomMemberModel copyWith({
    int? weeklyGoal,
    int? goalProgress,
  }) {
    return StudyRoomMemberModel(
      userId: userId,
      name: name,
      totalStudyLevel: totalStudyLevel,
      currentStreak: currentStreak,
      weeklyProblemCount: weeklyProblemCount,
      weeklyPracticeCount: weeklyPracticeCount,
      weeklyGoal: weeklyGoal,
      goalProgress: goalProgress,
    );
  }
}
