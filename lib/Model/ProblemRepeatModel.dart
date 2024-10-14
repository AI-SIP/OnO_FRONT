import 'package:intl/intl.dart';

class ProblemRepeatModel {
  final int id;
  final String? solveImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProblemRepeatModel({
    required this.id,
    required this.solveImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // 서버에서 받은 JSON 데이터를 기반으로 객체를 생성하는 팩토리 메서드
  factory ProblemRepeatModel.fromJson(Map<String, dynamic> json) {
    return ProblemRepeatModel(
      id: json['id'],
      solveImageUrl: json['solveImageUrl'],
      createdAt: DateTime.parse(json['createdAt']).add(const Duration(hours: 9)),
      updatedAt: DateTime.parse(json['updatedAt']).add(const Duration(hours: 9)),
    );
  }

  // 객체를 JSON 형식으로 변환하는 메서드 (서버로 전송할 때 사용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'solveImageUrl' : solveImageUrl,
      'createdAt': _formatDateTime(createdAt),
      'updatedAt': _formatDateTime(updatedAt),
    };
  }

  // 날짜 포맷팅 함수
  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}