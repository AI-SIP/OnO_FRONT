enum TemplateType {
  simple,
  clean,
  special,
}

extension TemplateTypeExtension on TemplateType {
  String get displayName {
    switch (this) {
      case TemplateType.simple:
        return '국어/영어 템플릿';
      case TemplateType.clean:
        return '사회 탐구 템플릿';
      case TemplateType.special:
        return '수학/과학 탐구 템플릿';
    }
  }

  List<String> get description {
    switch (this) {
      case TemplateType.simple:
        return ['필기 제거 X, 오답 분석 X', '-> 암기에 필요한 최소한의 요소만 빠르게 등록하는 기본 템플릿입니다.'];
      case TemplateType.clean:
        return ['필기 제거 O, 오답 분석 X', '-> 복습에 방해되는 필기를 제거하여 깔끔한 복습을 도와줍니다.'];
      case TemplateType.special:
        return ['필기 제거 O, 오답 분석 O', '-> 복습에 방해되는 필기를 제거하여 깔끔한 복습을 도와줍니다. \n교과과정 기반 문제 분석으로 나의 취약 개념 파악을 도와줍니다.'];
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