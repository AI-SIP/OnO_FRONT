class WeeklyReportModel {
  final int reportId;
  final String topMemberName;
  final int topMemberProblemCount;
  final String longestStreakName;
  final int longestStreakDays;
  final int totalProblems;
  final int challengesCompleted;
  final String cheerMessage;
  final DateTime? weekStart;
  final DateTime? weekEnd;
  bool isRead;

  WeeklyReportModel({
    required this.reportId,
    required this.topMemberName,
    required this.topMemberProblemCount,
    required this.longestStreakName,
    required this.longestStreakDays,
    required this.totalProblems,
    required this.challengesCompleted,
    required this.cheerMessage,
    this.weekStart,
    this.weekEnd,
    this.isRead = false,
  });

  factory WeeklyReportModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReportModel(
      reportId: ((json['reportId'] ?? 0) as num).toInt(),
      topMemberName: (json['topMemberName'] ?? '없음').toString(),
      topMemberProblemCount:
          ((json['topMemberProblemCount'] ?? 0) as num).toInt(),
      longestStreakName: (json['longestStreakName'] ?? '없음').toString(),
      longestStreakDays: ((json['longestStreakDays'] ?? 0) as num).toInt(),
      totalProblems: ((json['totalProblems'] ?? 0) as num).toInt(),
      challengesCompleted: ((json['challengesCompleted'] ?? 0) as num).toInt(),
      cheerMessage: (json['cheerMessage'] ?? '').toString(),
      weekStart: json['weekStart'] == null
          ? null
          : DateTime.tryParse(json['weekStart'] as String),
      weekEnd: json['weekEnd'] == null
          ? null
          : DateTime.tryParse(json['weekEnd'] as String),
      isRead: json['isRead'] == true,
    );
  }
}
