class StudySessionModel {
  final int userId;
  final String name;
  final DateTime startedAt;
  final int? sessionId;
  final DateTime? endedAt;
  final int? durationMinutes;

  const StudySessionModel({
    required this.userId,
    required this.name,
    required this.startedAt,
    this.sessionId,
    this.endedAt,
    this.durationMinutes,
  });

  factory StudySessionModel.fromActiveJson(Map<String, dynamic> json) {
    return StudySessionModel(
      userId: ((json['userId'] ?? 0) as num).toInt(),
      name: (json['name'] ?? '알 수 없음').toString(),
      startedAt: DateTime.tryParse((json['startedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
