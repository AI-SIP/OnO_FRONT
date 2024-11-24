enum TemplateType {
  simple,
  clean,
  special,
}

extension TemplateTypeExtension on TemplateType {
  String get displayName {
    switch (this) {
      case TemplateType.simple:
        return '암기왕 템플릿';
      case TemplateType.clean:
        return '문풀왕 템플릿';
      case TemplateType.special:
        return '길잡이 템플릿';
    }
  }

  String get description {
    switch (this) {
      case TemplateType.simple:
        return '오답노트를 쉽고 빠르게 작성해요!\n필기 제거가 필요없는 암기 문제에 좋아요.';
      case TemplateType.clean:
        return '진정한 복습을 위해 공부한 흔적을 가려보아요!\n필기가 중요한 힌트인 문제에 좋아요.';
      case TemplateType.special:
        return '문제 분석을 통해 나의 취약점을 알아보아요!\n오답노트의 효과를 제대로 경험할 수 있어요.';
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
        return ['#간편한', "#빠른", '#영단어',];
      case TemplateType.clean:
        return ['#필기 제거', '#국어', '#영어','#사회'];
      case TemplateType.special:
        return ['#AI 분석', '#필기 제거', '#수학', '#과학'];
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