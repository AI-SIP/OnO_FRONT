import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/Problem/ProblemImageDataRegisterModel.dart';

void main() {
  group('ProblemImageDataRegisterModel.toJson', () {
    test('서버가 받는 키 이름과 타입 이름(name)으로 직렬화된다', () {
      final model = ProblemImageDataRegisterModel(
        problemId: 7,
        imageUrl: 'https://cdn.test/a.png',
        problemImageType: ProblemImageType.PROBLEM_IMAGE,
      );

      expect(model.toJson(), {
        'problemId': 7,
        'imageUrl': 'https://cdn.test/a.png',
        'problemImageType': 'PROBLEM_IMAGE',
      });
    });

    test('problemId 가 null 이어도 toJson 에서 null 로 직렬화된다', () {
      final model = ProblemImageDataRegisterModel(
        problemId: null,
        imageUrl: 'https://cdn.test/a.png',
        problemImageType: ProblemImageType.ANSWER_IMAGE,
      );

      expect(model.toJson()['problemId'], isNull);
      expect(model.toJson()['problemImageType'], 'ANSWER_IMAGE');
    });

    test('네 가지 타입 모두 name 문자열로 직렬화된다', () {
      for (final type in ProblemImageType.values) {
        final model = ProblemImageDataRegisterModel(
          problemId: 1,
          imageUrl: 'https://cdn.test/a.png',
          problemImageType: type,
        );

        expect(model.toJson()['problemImageType'], type.name);
      }
    });
  });
}
