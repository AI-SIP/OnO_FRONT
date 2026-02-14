enum ImprovementType {
  NO_REPEAT_MISTAKE,
  FOUND_NEW_SOLUTION,
  BETTER_UNDERSTANDING,
  FASTER_SOLVING
}

extension ImprovementTypeExtension on ImprovementType {
  String get description {
    switch (this) {
      case ImprovementType.NO_REPEAT_MISTAKE:
        return '이전 실수를 반복하지 않았어요';
      case ImprovementType.FOUND_NEW_SOLUTION:
        return '새로운 풀이법을 찾았어요';
      case ImprovementType.BETTER_UNDERSTANDING:
        return '개념을 더 명확히 이해했어요';
      case ImprovementType.FASTER_SOLVING:
        return '풀이 시간이 단축됐어요';
    }
  }

  String toJson() {
    return name;
  }

  static ImprovementType fromJson(String json) {
    return ImprovementType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ImprovementType.NO_REPEAT_MISTAKE,
    );
  }
}