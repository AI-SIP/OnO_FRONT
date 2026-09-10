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

  group('서버 컬럼 길이 한도', () {
    test('memo 는 1000자, reference 는 255자다', () {
      expect(ProblemRegisterModel.memoMaxLength, 1000);
      expect(ProblemRegisterModel.referenceMaxLength, 255);
    });

    test('한도 안이면 그대로 둔다', () {
      expect(ProblemRegisterModel.clampMemo('짧은 메모'), '짧은 메모');
      expect(ProblemRegisterModel.clampReference('짧은 제목'), '짧은 제목');
      expect(
        ProblemRegisterModel.clampMemo('가' * 1000).length,
        1000,
      );
    });

    test('한도를 넘으면 잘라 낸다', () {
      expect(ProblemRegisterModel.clampMemo('가' * 1001).length, 1000);
      expect(ProblemRegisterModel.clampReference('가' * 256).length, 255);
    });

    test('이모지처럼 두 칸을 차지하는 글자도 UTF-16 길이로 센다', () {
      // 입력 필드의 maxLength 는 자소 단위라 이모지 255개를 통과시키지만,
      // 서버·DB 는 UTF-16 단위로 세서 510 이 되어 한도를 넘는다.
      final emojis = '😀' * 255;
      expect(emojis.length, 510);

      final clamped = ProblemRegisterModel.clampReference(emojis);
      expect(clamped.length, lessThanOrEqualTo(255));
    });

    test('서로게이트 쌍 한가운데를 자르지 않는다', () {
      // 254자 + 이모지(2칸) = 256. 255 에서 그냥 자르면 이모지가 반쪽만 남는다.
      final value = '${'가' * 254}😀';
      expect(value.length, 256);

      final clamped = ProblemRegisterModel.clampReference(value);
      expect(clamped.length, 254);
      expect(clamped, '가' * 254);
      // 반쪽짜리 서로게이트가 남지 않았는지 확인한다.
      expect(clamped.runes.length, 254);
    });

    test('자동 생성 제목처럼 긴 폴더 이름이 들어와도 한도를 넘기지 않는다', () {
      final autoTitle = '${'긴폴더이름' * 60} 1';
      expect(autoTitle.length, greaterThan(255));

      expect(
        ProblemRegisterModel.clampReference(autoTitle).length,
        255,
      );
    });
  });
}
