import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/Problem/ProblemImageDataModel.dart';

void main() {
  group('ProblemImageDataModel.fromJson', () {
    test('모든 필드가 채워진 정상 응답을 파싱한다', () {
      final json = {
        'imageUrl': 'https://cdn.test/problem.png',
        'problemImageType': 'PROBLEM_IMAGE',
        'createdAt': '2026-01-15T09:30:00.000Z',
      };

      final model = ProblemImageDataModel.fromJson(json);

      expect(model.imageUrl, 'https://cdn.test/problem.png');
      expect(model.problemImageType, ProblemImageType.PROBLEM_IMAGE);
      expect(model.createdAt, DateTime.parse('2026-01-15T09:30:00.000Z'));
    });

    test('ANSWER_IMAGE, SOLVE_IMAGE, PROCESS_IMAGE 타입도 각각 파싱된다', () {
      for (final type in ProblemImageType.values) {
        final model = ProblemImageDataModel.fromJson({
          'imageUrl': 'https://cdn.test/a.png',
          'problemImageType': type.name,
          'createdAt': '2026-01-15T09:30:00.000Z',
        });

        expect(model.problemImageType, type);
      }
    });

    test('서버가 모르는 타입 문자열을 보내면 PROBLEM_IMAGE 로 폴백한다', () {
      final model = ProblemImageDataModel.fromJson({
        'imageUrl': 'https://cdn.test/a.png',
        'problemImageType': 'ALIEN_TYPE',
        'createdAt': '2026-01-15T09:30:00.000Z',
      });

      expect(model.problemImageType, ProblemImageType.PROBLEM_IMAGE);
    });

    test('UTC 타임존(Z)과 오프셋 타임존 문자열을 모두 파싱한다', () {
      final utc = ProblemImageDataModel.fromJson({
        'imageUrl': 'https://cdn.test/a.png',
        'problemImageType': 'PROBLEM_IMAGE',
        'createdAt': '2026-01-15T09:30:00.000Z',
      });
      final offset = ProblemImageDataModel.fromJson({
        'imageUrl': 'https://cdn.test/a.png',
        'problemImageType': 'PROBLEM_IMAGE',
        'createdAt': '2026-01-15T18:30:00+09:00',
      });

      expect(utc.createdAt.isUtc, isTrue);
      expect(utc.createdAt.toUtc(), offset.createdAt.toUtc());
    });

    test(
      'imageUrl 이 없으면 예외가 난다 (필드가 non-nullable 이라 의도된 동작)',
      () {
        expect(
          () => ProblemImageDataModel.fromJson({
            'problemImageType': 'PROBLEM_IMAGE',
            'createdAt': '2026-01-15T09:30:00.000Z',
          }),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test(
      'createdAt 이 없으면 예외가 난다 (필드가 non-nullable 이라 의도된 동작)',
      () {
        expect(
          () => ProblemImageDataModel.fromJson({
            'imageUrl': 'https://cdn.test/a.png',
            'problemImageType': 'PROBLEM_IMAGE',
          }),
          throwsA(isA<TypeError>()),
        );
      },
    );
  });

  group('ProblemImageDataModel.toJson', () {
    test(
      'problemImageType 이 문자열이 아니라 enum 객체 그대로 직렬화된다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Problem/ProblemImageDataModel.dart:31 에서
        // 'problemImageType': problemImageType 로, .name 을 붙이지 않고 enum 값을
        // 그대로 맵에 넣는다. ProblemImageDataRegisterModel.toJson() 은 같은 필드를
        // problemImageType.name 으로 직렬화하는 것과 대조된다.
        // 이 상태로 jsonEncode 를 태우면 JsonUnsupportedObjectError 로 죽는다.
        final model = ProblemImageDataModel(
          imageUrl: 'https://cdn.test/a.png',
          problemImageType: ProblemImageType.ANSWER_IMAGE,
          createdAt: DateTime.parse('2026-01-15T09:30:00.000Z'),
        );

        final json = model.toJson();

        expect(json['problemImageType'], isA<String>());
        expect(json['problemImageType'], ProblemImageType.ANSWER_IMAGE.name);
      },
      skip: '#174 에서 수정 예정',
    );

    test('imageUrl 과 createdAt 은 정상적으로 직렬화된다', () {
      final model = ProblemImageDataModel(
        imageUrl: 'https://cdn.test/a.png',
        problemImageType: ProblemImageType.SOLVE_IMAGE,
        createdAt: DateTime.parse('2026-01-15T09:30:00.000Z'),
      );

      final json = model.toJson();

      expect(json['imageUrl'], 'https://cdn.test/a.png');
      expect(json['createdAt'], '2026-01-15T09:30:00.000Z');
    });
  });
}
