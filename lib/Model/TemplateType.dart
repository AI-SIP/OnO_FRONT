enum TemplateType {
  simple,
  clean,
  special,
}

extension TemplateTypeExtension on TemplateType {
  String get displayName {
    switch (this) {
      case TemplateType.simple:
        return '국어, 영어 템플릿';
      case TemplateType.clean:
        return '사회 탐구 템플릿';
      case TemplateType.special:
        return '수학, 과학 탐구 템플릿';
    }
  }

  List<String> get description {
    switch (this) {
      case TemplateType.simple:
        return ['**필기 제거 X, 오답 분석 X**', '빠르게 오답노트를 작성하고, 편리한 복습을 하고 싶은 분들을 위한 템플릿입니다.'];
      case TemplateType.clean:
        return ['**필기 제거 O, 오답 분석 X**', '필기 제거 기능을 통해 효율적인 복습을 하고 싶은 분들을 위한 템플릿입니다.'];
      case TemplateType.special:
        return ['**필기 제거 O, 오답 분석 O**', '필기 제거 기능과 AI 분석 기능을 통해 고도화된 복습을 하고 싶은 분들을 위한 템플릿입니다.'];
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