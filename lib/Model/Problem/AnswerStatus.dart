enum AnswerStatus {
  CORRECT, // 정답
  WRONG, // 오답
  PARTIAL, // 부분 정답
  UNKNOWN // 알 수 없음 (레거시 마이그레이션용)
}

extension AnswerStatusExtension on AnswerStatus {
  String get displayName {
    switch (this) {
      case AnswerStatus.CORRECT:
        return '정답';
      case AnswerStatus.WRONG:
        return '오답';
      case AnswerStatus.PARTIAL:
        return '부분 정답';
      case AnswerStatus.UNKNOWN:
        return '알 수 없음';
    }
  }

  String toJson() {
    return name;
  }

  static AnswerStatus fromJson(String json) {
    return AnswerStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => AnswerStatus.UNKNOWN,
    );
  }
}