import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/Problem/ProblemImageDataRegisterModel.dart';
import 'package:ono/Model/Problem/ProblemRegisterModel.dart';

void main() {
  group('ProblemRegisterModel.toJson', () {
    test('모든 필드가 채워지면 서버가 받는 키 이름으로 직렬화된다', () {
      final model = ProblemRegisterModel(
        problemId: 1,
        memo: '메모',
        reference: '기출문제집',
        folderId: 3,
        solvedAt: DateTime.parse('2026-01-10T09:00:00.000Z'),
        imageDataDtoList: [
          ProblemImageDataRegisterModel(
            problemId: 1,
            imageUrl: 'https://cdn.test/a.png',
            problemImageType: ProblemImageType.PROBLEM_IMAGE,
          ),
        ],
        tagIds: [1, 2],
      );

      expect(model.toJson(), {
        'problemId': 1,
        'memo': '메모',
        'reference': '기출문제집',
        'folderId': 3,
        'solvedAt': '2026-01-10T09:00:00.000Z',
        'imageDataDtoList': [
          {
            'problemId': 1,
            'imageUrl': 'https://cdn.test/a.png',
            'problemImageType': 'PROBLEM_IMAGE',
          },
        ],
        'tagIds': [1, 2],
      });
    });

    test('모든 필드가 비어 있으면 전부 null 로 직렬화된다', () {
      final model = ProblemRegisterModel();

      expect(model.toJson(), {
        'problemId': null,
        'memo': null,
        'reference': null,
        'folderId': null,
        'solvedAt': null,
        'imageDataDtoList': null,
        'tagIds': null,
      });
    });

    test('solvedAt 이 null 이면 toJson 에서도 null 이다 (예외 없이 처리)', () {
      final model = ProblemRegisterModel(solvedAt: null);

      expect(model.toJson()['solvedAt'], isNull);
    });
  });
}
