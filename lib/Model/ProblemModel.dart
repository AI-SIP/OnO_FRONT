import 'package:intl/intl.dart';

class ProblemModel {
  final int? problemId;
  final String? processImageUrl;
  final String? problemImageUrl;
  final String? solveImageUrl;
  final String? answerImageUrl;
  final String? memo;
  final String? reference;
  final String? folder;
  final DateTime? solvedAt;

  ProblemModel({
    this.problemId,
    this.processImageUrl,
    this.problemImageUrl,
    this.solveImageUrl,
    this.answerImageUrl,
    this.memo,
    this.reference,
    this.solvedAt,
    this.folder,
  });

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    return ProblemModel(
      problemId: json['problemId'],
      problemImageUrl: json['problemImageUrl'],
      solveImageUrl: json['solveImageUrl'],
      answerImageUrl: json['answerImageUrl'],
      processImageUrl: json['processImageUrl'],
      memo: json['memo'],
      reference: json['reference'],
      solvedAt:
          json['solvedAt'] != null ? DateTime.parse(json['solvedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'processImageUrl': processImageUrl,
      'problemImageUrl': problemImageUrl,
      'solveImageUrl': solveImageUrl,
      'answerImageUrl': answerImageUrl,
      'memo': memo,
      'reference': reference,
      'solvedAt': _formatDateTime(solvedAt),
      'folder': folder,
    };
  }

  // 날짜 포맷팅 함수
  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}
