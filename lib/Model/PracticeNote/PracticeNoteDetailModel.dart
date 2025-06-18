import 'package:intl/intl.dart';
import 'package:ono/Model/PracticeNote/PracticeNotificationModel.dart';

class PracticeNoteDetailModel {
  final int practiceId;
  final String practiceTitle;
  int practiceCount;
  final int practiceSize;
  final DateTime createdAt;
  final DateTime? lastSolvedAt;
  final PracticeNotificationModel? practiceNotificationModel;
  List<int> problemIdList = [];

  PracticeNoteDetailModel({
    required this.practiceId,
    required this.practiceTitle,
    required this.practiceCount,
    required this.practiceSize,
    required this.createdAt,
    required this.lastSolvedAt,
    this.practiceNotificationModel,
    required this.problemIdList,
  });

  factory PracticeNoteDetailModel.fromJson(Map<String, dynamic> json) {
    final problemIdDynamic = json['problemIdList'] as List<dynamic>? ?? [];
    final problemIdList = problemIdDynamic.map((e) => e as int).toList();
    final practiceNotificationModel = json['practiceNotification'] != null
        ? PracticeNotificationModel.fromJson(json['practiceNotification'])
        : null;

    return PracticeNoteDetailModel(
      practiceId: json['practiceNoteId'],
      practiceTitle: json['practiceTitle'] ?? '제목 없음',
      practiceCount: json['practiceCount'] ?? 0,
      practiceSize: json['practiceSize'] ?? 0,
      createdAt:
          DateTime.parse(json['createdAt']).add(const Duration(hours: 9)),
      lastSolvedAt: json['lastSolvedAt'] != null
          ? DateTime.parse(json['lastSolvedAt']).add(const Duration(hours: 9))
          : null,
      practiceNotificationModel: practiceNotificationModel,
      problemIdList: problemIdList,
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
