import 'package:intl/intl.dart';

class ProblemRepeatRegisterModel {
  final int problemId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? repeatImageUrlList;

  ProblemRepeatRegisterModel({
    required this.problemId,
    required this.createdAt,
    required this.updatedAt,
    this.repeatImageUrlList,
  });

  // 객체를 JSON 형식으로 변환하는 메서드 (서버로 전송할 때 사용)
  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'createdAt': _formatDateTime(createdAt),
      'updatedAt': _formatDateTime(updatedAt),
      'repeatImageUrlList': repeatImageUrlList ?? [],
    };
  }

  // 날짜 포맷팅 함수
  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}
