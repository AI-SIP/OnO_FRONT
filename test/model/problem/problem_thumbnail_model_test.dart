import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ProblemImageDataModel.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Problem/ProblemThumbnailModel.dart';

void main() {
  group('ProblemThumbnailModel.fromJson', () {
    test('createdAt 을 뺀 나머지 필드는 정상적으로 파싱된다', () {
      // createdAt 은 별도 버그 테스트에서 다룬다. 여기서는 파싱 자체가
      // 죽지 않도록 키를 생략해 둔다 (null 은 nullable 필드라 문제 없다).
      final model = ProblemThumbnailModel.fromJson({
        'problemId': 7,
        'reference': '기출문제집 p.10',
        'problemImageUrl': 'https://cdn.test/1.png',
        'lastSolvedAt': '2026-01-12T09:00:00.000Z',
        'solveCount': 3,
      });

      expect(model.problemId, 7);
      expect(model.reference, '기출문제집 p.10');
      expect(model.problemImageUrl, 'https://cdn.test/1.png');
      expect(model.lastSolvedAt, DateTime.parse('2026-01-12T09:00:00.000Z'));
      expect(model.solveCount, 3);
      expect(model.createdAt, isNull);
    });

    test('reference, problemImageUrl, lastSolvedAt 이 null 이어도 파싱된다', () {
      final model = ProblemThumbnailModel.fromJson({
        'problemId': 7,
        'reference': null,
        'problemImageUrl': null,
        'lastSolvedAt': null,
      });

      expect(model.reference, isNull);
      expect(model.problemImageUrl, isNull);
      expect(model.lastSolvedAt, isNull);
    });

    test('solveCount 키가 없으면 0으로 기본값 처리된다', () {
      final model = ProblemThumbnailModel.fromJson({
        'problemId': 7,
        'reference': null,
        'problemImageUrl': null,
      });

      expect(model.solveCount, 0);
    });

    test('solveCount 가 double(3.0)로 와도 int 로 변환된다', () {
      final model = ProblemThumbnailModel.fromJson({
        'problemId': 7,
        'reference': null,
        'problemImageUrl': null,
        'solveCount': 3.0,
      });

      expect(model.solveCount, 3);
    });

    test(
      'createdAt 이 실제 서버 응답처럼 문자열로 오면 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Problem/ProblemThumbnailModel.dart:24 에서
        // createdAt: json['createdAt'] 를 DateTime.parse 없이 그대로 대입한다.
        // 모델 필드 타입은 DateTime? 인데 실제로는 서버가 ISO 문자열을 내려주므로,
        // 정상적인 응답에서조차 String 을 DateTime? 에 대입하다 TypeError 로 죽는다.
        // 바로 아래 lastSolvedAt 은 DateTime.parse 로 제대로 처리하는 것과 대조된다.
        expect(
          () => ProblemThumbnailModel.fromJson({
            'problemId': 7,
            'reference': '기출문제집',
            'problemImageUrl': 'https://cdn.test/1.png',
            'createdAt': '2026-01-09T09:00:00.000Z',
          }),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );
  });

  group('ProblemThumbnailModel.fromProblem', () {
    test('문제에 이미지가 있으면 첫 번째 이미지 URL 을 썸네일로 쓴다', () {
      final problem = ProblemModel(
        problemId: 7,
        reference: '기출문제집',
        createdAt: DateTime.parse('2026-01-09T09:00:00.000Z'),
        problemImageDataList: [
          ProblemImageDataModel(
            imageUrl: 'https://cdn.test/first.png',
            problemImageType: ProblemImageType.PROBLEM_IMAGE,
            createdAt: DateTime.parse('2026-01-09T09:00:00.000Z'),
          ),
        ],
      );

      final thumbnail = ProblemThumbnailModel.fromProblem(problem);

      expect(thumbnail.problemImageUrl, 'https://cdn.test/first.png');
      expect(thumbnail.problemId, 7);
      expect(thumbnail.reference, '기출문제집');
    });

    test('problemImageDataList 가 null 이면 problemImageUrl 도 null 이다', () {
      final problem = ProblemModel(
        problemId: 7,
        reference: '기출문제집',
        problemImageDataList: null,
      );

      final thumbnail = ProblemThumbnailModel.fromProblem(problem);

      expect(thumbnail.problemImageUrl, isNull);
    });

    test(
      'problemImageDataList 가 빈 배열([])이면 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Problem/ProblemThumbnailModel.dart:36-38 에서
        // problemImageDataList != null 만 확인하고 바로 [0] 으로 접근한다.
        // ProblemModel.fromJson 은 이미지가 없으면 null 이 아니라 빈 리스트([])를
        // 만들어 주므로, 이미지가 아직 없는(또는 전부 삭제된) 문제를 썸네일로 바꾸면
        // null 체크를 통과한 뒤 RangeError 로 죽는다.
        final problem = ProblemModel(
          problemId: 7,
          reference: '기출문제집',
          problemImageDataList: const [],
        );

        expect(
          () => ProblemThumbnailModel.fromProblem(problem),
          throwsA(isA<RangeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );
  });
}
