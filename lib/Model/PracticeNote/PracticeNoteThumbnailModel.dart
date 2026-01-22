import 'package:intl/intl.dart';

class PracticeNoteThumbnails {
  final int practiceId;
  final String practiceTitle;
  int practiceCount;
  final DateTime? lastSolvedAt;

  PracticeNoteThumbnails({
    required this.practiceId,
    required this.practiceTitle,
    required this.practiceCount,
    required this.lastSolvedAt,
  });

  factory PracticeNoteThumbnails.fromJson(Map<String, dynamic> json) {
    return PracticeNoteThumbnails(
      practiceId: json['practiceNoteId'],
      practiceTitle: json['practiceTitle'] ?? '제목 없음',
      practiceCount: json['practiceCount'] ?? 0,
      lastSolvedAt: json['lastSolvedAt'] != null
          ? DateTime.parse(json['lastSolvedAt'])
          : null,
    );
  }

  // 날짜 포맷팅 함수
  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  void addPracticeCount() {
    practiceCount += 1;
  }
}
