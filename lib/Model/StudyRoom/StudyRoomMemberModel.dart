class StudyRoomMemberModel {
  final int userId;
  final String name;
  final String? profileImageUrl;
  final int totalStudyLevel;
  final int currentStreak;
  final int weeklyProblemCount;
  final int weeklyPracticeCount;
  final int? todayPracticeCount;
  final bool? practicedToday;
  final int? weeklyGoal;
  final int? goalProgress;

  const StudyRoomMemberModel({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    required this.totalStudyLevel,
    required this.currentStreak,
    required this.weeklyProblemCount,
    required this.weeklyPracticeCount,
    this.todayPracticeCount,
    this.practicedToday,
    this.weeklyGoal,
    this.goalProgress,
  });

  bool get hasPracticedToday =>
      practicedToday ?? ((todayPracticeCount ?? 0) > 0);

  int get displayTodayPracticeCount =>
      todayPracticeCount ?? (hasPracticedToday ? 1 : 0);

  factory StudyRoomMemberModel.fromJson(Map<String, dynamic> json) {
    return StudyRoomMemberModel(
      userId: ((json['userId'] ?? 0) as num).toInt(),
      name: (json['name'] ?? '알 수 없음').toString(),
      profileImageUrl: json['profileImageUrl'] as String?,
      totalStudyLevel: ((json['totalStudyLevel'] ?? 1) as num).toInt(),
      currentStreak: ((json['currentStreak'] ?? 0) as num).toInt(),
      weeklyProblemCount: ((json['weeklyProblemCount'] ?? 0) as num).toInt(),
      weeklyPracticeCount: ((json['weeklyPracticeCount'] ?? 0) as num).toInt(),
      todayPracticeCount: json['todayPracticeCount'] == null
          ? null
          : (json['todayPracticeCount'] as num).toInt(),
      practicedToday: json['practicedToday'] as bool?,
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
      profileImageUrl: profileImageUrl,
      totalStudyLevel: totalStudyLevel,
      currentStreak: currentStreak,
      weeklyProblemCount: weeklyProblemCount,
      weeklyPracticeCount: weeklyPracticeCount,
      todayPracticeCount: todayPracticeCount,
      practicedToday: practicedToday,
      weeklyGoal: weeklyGoal,
      goalProgress: goalProgress,
    );
  }
}
