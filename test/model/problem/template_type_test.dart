import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/TemplateType.dart';

void main() {
  group('TemplateType', () {
    test('displayName 으로 TemplateType 을 역으로 찾는다', () {
      expect(TemplateTypeExtension.fromDisplayName('암기왕 템플릿'),
          TemplateType.simple);
      expect(
          TemplateTypeExtension.fromDisplayName('문풀왕 템플릿'), TemplateType.clean);
      expect(TemplateTypeExtension.fromDisplayName('길잡이 템플릿'),
          TemplateType.special);
    });

    test('알 수 없는 displayName 이면 null 을 돌려준다', () {
      expect(TemplateTypeExtension.fromDisplayName('없는 템플릿'), isNull);
    });

    test('templateTypeCode 로 TemplateType 을 역으로 찾는다', () {
      expect(
          TemplateTypeExtension.fromTemplateTypeCode(1), TemplateType.simple);
      expect(TemplateTypeExtension.fromTemplateTypeCode(2), TemplateType.clean);
      expect(
          TemplateTypeExtension.fromTemplateTypeCode(3), TemplateType.special);
    });

    test('알 수 없는 templateTypeCode 면 null 을 돌려준다', () {
      expect(TemplateTypeExtension.fromTemplateTypeCode(999), isNull);
    });

    test('각 타입의 templateTypeCode 가 고유하다', () {
      expect(TemplateType.simple.templateTypeCode, 1);
      expect(TemplateType.clean.templateTypeCode, 2);
      expect(TemplateType.special.templateTypeCode, 3);
    });

    test('hasEraseFeature 와 hasAnalysisFeature 가 타입별로 다르다', () {
      expect(TemplateType.simple.hasEraseFeature, isFalse);
      expect(TemplateType.simple.hasAnalysisFeature, isFalse);

      expect(TemplateType.clean.hasEraseFeature, isTrue);
      expect(TemplateType.clean.hasAnalysisFeature, isFalse);

      expect(TemplateType.special.hasEraseFeature, isTrue);
      expect(TemplateType.special.hasAnalysisFeature, isTrue);
    });

    test('hashTags 가 타입별로 비어 있지 않다', () {
      for (final type in TemplateType.values) {
        expect(type.hashTags, isNotEmpty);
      }
    });
  });
}
