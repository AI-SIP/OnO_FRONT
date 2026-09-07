import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Tag/TagModel.dart';

void main() {
  group('TagModel.fromJson', () {
    test('모든 필드가 채워진 정상 응답을 파싱한다', () {
      final tag = TagModel.fromJson({'tagId': 1, 'name': '수학'});

      expect(tag.tagId, 1);
      expect(tag.name, '수학');
    });

    test('name 이 null 이면 빈 문자열로 기본값 처리된다', () {
      final tag = TagModel.fromJson({'tagId': 1, 'name': null});

      expect(tag.name, '');
    });

    test('name 키가 아예 없어도 빈 문자열로 기본값 처리된다', () {
      final tag = TagModel.fromJson({'tagId': 1});

      expect(tag.name, '');
    });

    test('tagId 가 없으면 예외가 난다 (필드가 non-nullable 이라 의도된 동작)', () {
      expect(
        () => TagModel.fromJson({'name': '수학'}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
