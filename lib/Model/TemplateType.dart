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
        return ['추천 과목 : 국어, 영어', '빠르게 오답노트를 등록하고, 편리한 복습을 하고 싶은 분들을 위한 템플릿입니다.'];
      case TemplateType.clean:
        return ['추천 과목 : 사회 탐구, 과학 탐구', '필기 제거 기능을 통해 효율적인 복습을 하고 싶은 분들을 위한 템플릿입니다.'];
      case TemplateType.special:
        return ['추천 과목 : 수학', '필기 제거 기능과 AI 문제 분석 기능을 통해 고도화된 복습을 하고 싶은 분들을 위한 템플릿입니다'];
    }
  }
}