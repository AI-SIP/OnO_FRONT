class WeeklyReportModel {
  final int reportId;
  final String topMemberName;
  final int topMemberProblemCount;
  final String longestStreakName;
  final int longestStreakDays;
  final int totalProblems;
  final int challengesCompleted;
  final String cheerMessage;
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
    this.isRead = false,
  });
}
