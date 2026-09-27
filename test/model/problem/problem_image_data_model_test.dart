import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/Problem/ProblemImageDataModel.dart';

void main() {
  group('ProblemImageDataModel.fromJsonOrNull', () {
    test('모든 필드가 채워진 정상 응답을 파싱한다', () {
      final json = {
        'imageUrl': 'https://cdn.test/problem.png',
        'problemImageType': 'PROBLEM_IMAGE',
        'createdAt': '2026-01-15T09:30:00.000Z',
      };

      final model = ProblemImageDataModel.fromJsonOrNull(json)!;

      expect(model.imageUrl, 'https://cdn.test/problem.png');
      expect(model.problemImageType, ProblemImageType.PROBLEM_IMAGE);
      expect(model.createdAt, DateTime.parse('2026-01-15T09:30:00.000Z'));
    });

    test('ANSWER_IMAGE, SOLVE_IMAGE, PROCESS_IMAGE 타입도 각각 파싱된다', () {
      for (final type in ProblemImageType.values) {
        final model = ProblemImageDataModel.fromJsonOrNull({
          'imageUrl': 'https://cdn.test/a.png',
          'problemImageType': type.name,
          'createdAt': '2026-01-15T09:30:00.000Z',
        });

        expect(model?.problemImageType, type);
      }
    });

    test('서버가 모르는 타입 문자열을 보내면 PROBLEM_IMAGE 로 폴백한다', () {
      final model = ProblemImageDataModel.fromJsonOrNull({
        'imageUrl': 'https://cdn.test/a.png',
        'problemImageType': 'ALIEN_TYPE',
        'createdAt': '2026-01-15T09:30:00.000Z',
      });

      expect(model?.problemImageType, ProblemImageType.PROBLEM_IMAGE);
    });

    test('UTC 타임존(Z)과 오프셋 타임존 문자열을 모두 파싱한다', () {
      final utc = ProblemImageDataModel.fromJsonOrNull({
        'imageUrl': 'https://cdn.test/a.png',
        'problemImageType': 'PROBLEM_IMAGE',
        'createdAt': '2026-01-15T09:30:00.000Z',
      })!;
      final offset = ProblemImageDataModel.fromJsonOrNull({
        'imageUrl': 'https://cdn.test/a.png',
        'problemImageType': 'PROBLEM_IMAGE',
        'createdAt': '2026-01-15T18:30:00+09:00',
      })!;

      expect(utc.createdAt.isUtc, isTrue);
      expect(utc.createdAt.toUtc(), offset.createdAt.toUtc());
    });

    // 서버 컬럼에 not null 제약이 없어서 값이 빠진 줄이 섞일 수 있다. 예전에는
    // non-null 캐스팅이라 그런 줄 하나가 문제 상세·폴더 목록·태그 목록·검색을
    // 전부 파싱 단계에서 죽였다 (#259).
    test('imageUrl 이 없으면 예외 없이 그 줄을 버린다', () {
      expect(
        ProblemImageDataModel.fromJsonOrNull({
          'problemImageType': 'PROBLEM_IMAGE',
          'createdAt': '2026-01-15T09:30:00.000Z',
        }),
        isNull,
      );
      expect(
        ProblemImageDataModel.fromJsonOrNull({
          'imageUrl': '',
          'problemImageType': 'PROBLEM_IMAGE',
          'createdAt': '2026-01-15T09:30:00.000Z',
        }),
        isNull,
      );
    });

    test('problemImageType 이 없으면 PROBLEM_IMAGE 로 떨어진다', () {
      final model = ProblemImageDataModel.fromJsonOrNull({
        'imageUrl': 'https://cdn.test/a.png',
        'createdAt': '2026-01-15T09:30:00.000Z',
      });

      expect(model?.problemImageType, ProblemImageType.PROBLEM_IMAGE);
    });

    test('createdAt 이 없거나 읽을 수 없으면 줄을 버리지 않고 지금 시각으로 채운다', () {
      final before = DateTime.now();

      final missing = ProblemImageDataModel.fromJsonOrNull({
        'imageUrl': 'https://cdn.test/a.png',
        'problemImageType': 'PROBLEM_IMAGE',
      });
      final broken = ProblemImageDataModel.fromJsonOrNull({
        'imageUrl': 'https://cdn.test/a.png',
        'problemImageType': 'PROBLEM_IMAGE',
        'createdAt': '날짜 아님',
      });

      expect(missing?.imageUrl, 'https://cdn.test/a.png');
      expect(broken?.imageUrl, 'https://cdn.test/a.png');
      // 읽은 시각으로 채운다. 어차피 화면에 쓰이지 않는 값이라 줄만 살리면 된다.
      expect(
        missing!.createdAt.difference(before).abs(),
        lessThan(const Duration(minutes: 1)),
      );
      expect(
        broken!.createdAt.difference(before).abs(),
        lessThan(const Duration(minutes: 1)),
      );
    });

    test('Map 이 아닌 값은 null 이다', () {
      expect(ProblemImageDataModel.fromJsonOrNull(null), isNull);
      expect(ProblemImageDataModel.fromJsonOrNull('문자열'), isNull);
    });
  });

  group('ProblemImageDataModel.listFrom', () {
    test('읽지 못한 줄만 버리고 나머지는 살린다', () {
      final images = ProblemImageDataModel.listFrom([
        {
          'imageUrl': 'https://cdn.test/a.png',
          'problemImageType': 'PROBLEM_IMAGE',
          'createdAt': '2026-01-15T09:30:00.000Z',
        },
        // imageUrl 이 빠진 줄. 이것 하나로 목록 전체가 죽으면 안 된다.
        {
          'problemImageType': 'ANSWER_IMAGE',
          'createdAt': '2026-01-15T09:30:00.000Z',
        },
        {
          'imageUrl': 'https://cdn.test/b.png',
          'problemImageType': 'ANSWER_IMAGE',
          'createdAt': '2026-01-15T09:30:00.000Z',
        },
      ]);

      expect(
        images.map((image) => image.imageUrl),
        ['https://cdn.test/a.png', 'https://cdn.test/b.png'],
      );
    });

    test('목록이 아니면 빈 목록이다', () {
      expect(ProblemImageDataModel.listFrom(null), isEmpty);
      expect(ProblemImageDataModel.listFrom({'imageUrl': 'x'}), isEmpty);
    });
  });

  group('ProblemImageDataModel.toJson', () {
    test(
      'problemImageType 이 문자열이 아니라 enum 객체 그대로 직렬화된다',
      () {
        // TODO(#174): 실제 버그. ProblemImageDataModel.toJson 에서
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
