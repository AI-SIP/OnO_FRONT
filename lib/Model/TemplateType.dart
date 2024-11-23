enum TemplateType {
  simple,
  clean,
  special,
}

extension TemplateTypeExtension on TemplateType {
  String get displayName {
    switch (this) {
      case TemplateType.simple:
        return '빠른 작성';
      case TemplateType.clean:
        return '필기 지우개';
      case TemplateType.special:
        return '필기 지우개 & 문제 분석';
    }
  }

  String get description {
    switch (this) {
      case TemplateType.simple:
        return '빠르고 간편하게 오답노트를 작성하세요.';
      case TemplateType.clean:
        return '문제 이미지의 필기를 제거해\n깔끔한 복습을 해보세요.';
      case TemplateType.special:
        return '필기 제거와 문제 분석을 통해\n한층 더 고도화된 복습을 해보세요.';
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

  bool get hasEraseFeature{
    switch (this) {
      case TemplateType.simple:
        return false;
      case TemplateType.clean:
        return true;
      case TemplateType.special:
        return true;
    }
  }

  bool get hasAnalysisFeature{
    switch (this) {
      case TemplateType.simple:
        return false;
      case TemplateType.clean:
        return false;
      case TemplateType.special:
        return true;
    }
  }

  String get templateThumbnailImage{
    switch (this) {
      case TemplateType.simple:
        return "assets/Icon/Pencil.svg";
      case TemplateType.clean:
        return "assets/Icon/Eraser.svg";
      case TemplateType.special:
        return "assets/Icon/Glass.svg";
    }
  }

  String get templateDetailImage{
    switch (this) {
      case TemplateType.simple:
        return "assets/Icon/PencilDetail.svg";
      case TemplateType.clean:
        return "assets/Icon/EraserDetail.svg";
      case TemplateType.special:
        return "assets/Icon/GlassDetail.svg";
    }
  }

  List<String> get hashTags {
    switch (this) {
      case TemplateType.simple:
        return ['#국어', '#영어'];
      case TemplateType.clean:
        return ['#사회', '#역사'];
      case TemplateType.special:
        return ['#수학', '#과학'];
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