import 'package:intl/intl.dart';

import 'ProblemModel.dart';

class ProblemPracticeModel {
  final int practiceId;
  final String practiceTitle;
  final int practiceCount;
  final int practiceSize;
  final DateTime createdAt;
  final DateTime? lastSolvedAt;
  List<ProblemModel> problems = [];
  final List<int>? problemIds; // 추가된 필드

  ProblemPracticeModel({
    required this.practiceId,
    required this.practiceTitle,
    required this.practiceCount,
    required this.practiceSize,
    required this.createdAt,
    required this.lastSolvedAt,
    required this.problems,
    this.problemIds,
  });

  factory ProblemPracticeModel.fromJson(Map<String, dynamic> json) {
    return ProblemPracticeModel(
      practiceId: json['practiceId'],
      practiceTitle: json['practiceTitle'] ?? '제목 없음',
      practiceCount: json['practiceCount'] ?? 0,
      practiceSize: json['practiceSize'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']).add(const Duration(hours: 9)),
      lastSolvedAt: json['lastSolvedAt'] != null ? DateTime.parse(json['lastSolvedAt']).add(const Duration(hours: 9)) : null,
      problems: (json['problems'] as List?)?.map((e) => ProblemModel.fromJson(e)).toList() ?? [], // null 체크
      problemIds: json['problemIds'] != null
          ? List<int>.from(json['problemIds']) // problemIds 파싱
          : [],
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
      'problems': problems.map((e) => e.toJson()).toList(),
      'problemIds': problemIds, // 추가된 필드
    };
  }

  // 날짜 포맷팅 함수
  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}