import 'package:intl/intl.dart';

class ProblemDetailModel {
  final String? processImageUrl;
  final String? problemImageUrl;
  final String? solveImageUrl;
  final String? answerImageUrl;
  final String? memo;
  final String? reference;
  final DateTime? solvedAt;

  ProblemDetailModel({
    this.processImageUrl,
    this.problemImageUrl,
    this.solveImageUrl,
    this.answerImageUrl,
    this.memo,
    this.reference,
    this.solvedAt,
  });

  factory ProblemDetailModel.fromJson(Map<String, dynamic> json) {
    return ProblemDetailModel(
      problemImageUrl: json['problemImageUrl'],
      solveImageUrl: json['solveImageUrl'],
      answerImageUrl: json['answerImageUrl'],
      memo: json['memo'],
      reference: json['reference'],
      solvedAt: json['solvedAt'] != null ? DateTime.parse(json['solvedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'processImageUrl': processImageUrl,
      'problemImageUrl': problemImageUrl,
      'solveImageUrl': solveImageUrl,
      'answerImageUrl': answerImageUrl,
      'memo': memo,
      'reference': reference,
      'solvedAt': _formatDateTime(solvedAt),
    };
  }

  // 날짜 포맷팅 함수
  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return DateFormat('yyyy년MM월dd일 HH시mm분ss초').format(dateTime);
  }
}