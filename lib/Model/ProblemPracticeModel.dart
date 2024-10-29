import 'package:intl/intl.dart';

class ProblemPracticeModel {
  final int practiceId;
  final String practiceTitle;
  final int practiceCount;
  final int practiceSize;
  final DateTime createdAt;
  final DateTime? lastSolvedAt;

  ProblemPracticeModel({
    required this.practiceId,
    required this.practiceTitle,
    required this.practiceCount,
    required this.practiceSize,
    required this.createdAt,
    required this.lastSolvedAt,
  });

  factory ProblemPracticeModel.fromJson(Map<String, dynamic> json) {
    return ProblemPracticeModel(
      practiceId: json['practiceId'],
      practiceTitle: json['practiceTitle'] ?? '제목 없음',
      practiceCount: json['practiceCount'] ?? 0,
      practiceSize: json['practiceSize'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']).add(const Duration(hours: 9)),
      lastSolvedAt: json['lastSolvedAt'] != null ? DateTime.parse(json['lastSolvedAt']).add(const Duration(hours: 9)) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'practiceId': practiceId,
      'practiceTitle': practiceTitle,
      'practiceCount': practiceCount,
      'practiceSize': practiceSize,
      'createdAt': _formatDateTime(createdAt),
      'lastSolvedAt': _formatDateTime(lastSolvedAt),
    };
  }

  // 날짜 포맷팅 함수
  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}