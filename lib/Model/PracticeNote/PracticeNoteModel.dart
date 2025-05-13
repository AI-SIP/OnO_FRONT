import 'package:intl/intl.dart';

import '../Problem/ProblemModel.dart';

class PracticeNoteModel {
  final int practiceId;
  final String practiceTitle;
  final int practiceCount;
  final int practiceSize;
  final DateTime createdAt;
  final DateTime? lastSolvedAt;
  List<ProblemModel> problems = [];

  PracticeNoteModel({
    required this.practiceId,
    required this.practiceTitle,
    required this.practiceCount,
    required this.practiceSize,
    required this.createdAt,
    required this.lastSolvedAt,
    required this.problems,
  });

  factory PracticeNoteModel.fromJson(Map<String, dynamic> json) {
    return PracticeNoteModel(
      practiceId: json['practiceNoteId'],
      practiceTitle: json['practiceTitle'] ?? '제목 없음',
      practiceCount: json['practiceCount'] ?? 0,
      practiceSize: json['practiceSize'] ?? 0,
      createdAt:
          DateTime.parse(json['createdAt']).add(const Duration(hours: 9)),
      lastSolvedAt: json['lastSolvedAt'] != null
          ? DateTime.parse(json['lastSolvedAt']).add(const Duration(hours: 9))
          : null,
      problems: (json['problemResponseDtoList'] as List?)
              ?.map((e) => ProblemModel.fromJson(e))
              .toList() ??
          [], // null 체크
    );
  }

  // 날짜 포맷팅 함수
  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}
