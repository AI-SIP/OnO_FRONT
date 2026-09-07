import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ProblemThumbnailModelWithTemplate.dart';

void main() {
  group('ProblemThumbnailModelWithTemplate.fromJson', () {
    test('createdAt 을 뺀 나머지 필드는 정상적으로 파싱된다', () {
      final model = ProblemThumbnailModelWithTemplate.fromJson({
        'problemId': 7,
        'reference': '기출문제집 p.10',
        'processImageUrl': 'https://cdn.test/process.png',
      });

      expect(model.problemId, 7);
      expect(model.reference, '기출문제집 p.10');
      expect(model.processImageUrl, 'https://cdn.test/process.png');
      expect(model.createdAt, isNull);
    });

    test(
      'createdAt 이 실제 서버 응답처럼 문자열로 오면 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Problem/ProblemThumbnailModelWithTemplate.dart:19 에서
        // createdAt: json['createdAt'] 를 DateTime.parse 없이 그대로 대입한다.
        // ProblemThumbnailModel 의 같은 문제(줄 24)와 동일한 패턴이다.
        expect(
          () => ProblemThumbnailModelWithTemplate.fromJson({
            'problemId': 7,
            'reference': '기출문제집',
            'processImageUrl': 'https://cdn.test/process.png',
            'createdAt': '2026-01-09T09:00:00.000Z',
          }),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );

    test('reference 가 없으면 예외가 난다 (필드가 non-nullable 이라 의도된 동작)', () {
      expect(
        () => ProblemThumbnailModelWithTemplate.fromJson({
          'problemId': 7,
          'processImageUrl': 'https://cdn.test/process.png',
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('processImageUrl 이 없으면 예외가 난다 (필드가 non-nullable 이라 의도된 동작)', () {
      expect(
        () => ProblemThumbnailModelWithTemplate.fromJson({
          'problemId': 7,
          'reference': '기출문제집',
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
