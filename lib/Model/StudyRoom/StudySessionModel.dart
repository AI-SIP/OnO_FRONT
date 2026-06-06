class StudySessionModel {
  final int userId;
  final String name;
  final DateTime startedAt;

  const StudySessionModel({
    required this.userId,
    required this.name,
    required this.startedAt,
  });
}
