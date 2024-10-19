enum TemplateType {
  simple,
  clean,
  special,
}

extension TemplateTypeExtension on TemplateType {
  String get displayName {
    switch (this) {
      case TemplateType.simple:
        return '심플 템플릿';
      case TemplateType.clean:
        return '클린 템플릿';
      case TemplateType.special:
        return '스페셜 템플릿';
    }
  }

  List<String> get description {
    switch (this) {
      case TemplateType.simple:
        return ['**추천 과목 : 국어, 영어**', '빠르게 오답노트를 작성하고, 편리한 복습을 하고 싶은 분들을 위한 템플릿입니다.\n(필기 제거 X, 오답 분석 X)'];
      case TemplateType.clean:
        return ['**추천 과목 : 사회 탐구**', '**필기 제거 기능**을 통해 효율적인 복습을 하고 싶은 분들을 위한 템플릿입니다.\n(필기 제거O, 오답 분석 X)'];
      case TemplateType.special:
        return ['**추천 과목 : 수학, 과학 탐구**', '**필기 제거 기능**과 **AI 분석 기능**을 통해 고도화된 복습을 하고 싶은 분들을 위한 템플릿입니다.\n(필기 제거O, 오답 분석 O)'];
    }
  }

  int get templateTypeCode {
    switch (this) {
      case TemplateType.simple:
        return 1;
      case TemplateType.clean:
        return 2;
      case TemplateType.special:
        return 3;
    }
  }

  // displayName을 통해 TemplateType을 반환하는 메서드
  static TemplateType? fromDisplayName(String name) {
    for (TemplateType type in TemplateType.values) {
      if (type.displayName == name) {
        return type;
      }
    }
    return null; // 찾을 수 없으면 null 반환
  }

  // templateTypeCode를 통해 TemplateType을 반환하는 메서드
  static TemplateType? fromTemplateTypeCode(int code) {
    for (TemplateType type in TemplateType.values) {
      if (type.templateTypeCode == code) {
        return type;
      }
    }
    return null; // 찾을 수 없으면 null 반환
  }
}