import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ProblemAnalysisModel.dart';
import 'package:ono/Model/Problem/ProblemAnalysisStatus.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';

Map<String, dynamic> _imageJson(String type,
    {String url = 'https://cdn.test/1.png'}) {
  return {
    'imageUrl': url,
    'problemImageType': type,
    'createdAt': '2026-01-10T00:00:00.000Z',
  };
}

void main() {
  group('ProblemModel.fromJson', () {
    test('모든 필드가 채워진 정상 응답을 파싱한다', () {
      final json = {
        'problemId': 7,
        'folderId': 3,
        'memo': '메모 내용',
        'reference': '수학의 정석 p.42',
        'solvedAt': '2026-01-10T09:00:00.000Z',
        'lastSolvedAt': '2026-01-12T09:00:00.000Z',
        'createdAt': '2026-01-09T09:00:00.000Z',
        'updatedAt': '2026-01-12T10:00:00.000Z',
        'solveCount': 2,
        'imageUrlList': [
          _imageJson('PROBLEM_IMAGE'),
          _imageJson('ANSWER_IMAGE'),
          _imageJson('SOLVE_IMAGE'),
        ],
        'analysis': {'id': 1, 'status': 'COMPLETED'},
        'tagIdList': [1, 2, 3],
        'tags': [
          {'tagId': 1, 'name': '수학'},
        ],
      };

      final model = ProblemModel.fromJson(json);

      expect(model.problemId, 7);
      expect(model.folderId, 3);
      expect(model.memo, '메모 내용');
      expect(model.reference, '수학의 정석 p.42');
      expect(model.solvedAt, DateTime.parse('2026-01-10T09:00:00.000Z'));
      expect(model.lastSolvedAt, DateTime.parse('2026-01-12T09:00:00.000Z'));
      expect(model.createdAt, DateTime.parse('2026-01-09T09:00:00.000Z'));
      // JSON 키는 updatedAt 인데 모델 필드명은 updateAt 이다.
      expect(model.updateAt, DateTime.parse('2026-01-12T10:00:00.000Z'));
      expect(model.solveCount, 2);
      expect(model.problemImageDataList, hasLength(1));
      expect(model.answerImageDataList, hasLength(1));
      expect(model.solveImageDataList, hasLength(1));
      expect(model.analysis?.status, ProblemAnalysisStatus.COMPLETED);
      expect(model.tagIdList, [1, 2, 3]);
      expect(model.tags, hasLength(1));
      expect(model.tags.first.name, '수학');
    });

    test('nullable 필드가 전부 null 이어도 파싱된다', () {
      final json = {
        'problemId': 1,
        // folderId 는 null 이면 그 자체로 알려진 버그(#174)를 건드리므로
        // 별도 테스트에서 다루고, 여기서는 값을 채워 다른 nullable 필드에 집중한다.
        'folderId': 1,
        'memo': null,
        'reference': null,
        'solvedAt': null,
        'lastSolvedAt': null,
        'createdAt': null,
        'updatedAt': null,
        'solveCount': null,
        'imageUrlList': null,
        'analysis': null,
        'tagIdList': null,
        'tags': null,
      };

      final model = ProblemModel.fromJson(json);

      expect(model.memo, isNull);
      expect(model.solvedAt, isNull);
      expect(model.createdAt, isNull);
      expect(model.updateAt, isNull);
      expect(model.solveCount, 0); // solveCount 는 null 이면 0 으로 기본값 처리된다.
      expect(model.problemImageDataList, isEmpty);
      expect(model.answerImageDataList, isEmpty);
      expect(model.solveImageDataList, isEmpty);
      expect(model.analysis, isNull);
      expect(model.tagIdList, isEmpty);
      expect(model.tags, isEmpty);
    });

    test('키가 아예 빠져 있어도 기본값으로 떨어진다', () {
      final model = ProblemModel.fromJson({'problemId': 1, 'folderId': 1});

      expect(model.memo, isNull);
      expect(model.solveCount, 0);
      expect(model.problemImageDataList, isEmpty);
      expect(model.tagIdList, isEmpty);
      expect(model.tags, isEmpty);
      expect(model.analysis, isNull);
    });

    test(
      'folderId 에 null 이 오면 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Problem/ProblemModel.dart:74 의
        // folderId: json['folderId'] as int 가 non-null 캐스팅인데,
        // 정작 필드 타입은 int? (nullable) 이다. 백엔드가 folderId 없이
        // (또는 null 로) 응답하면 여기서 바로 TypeError 로 죽는다.
        expect(
          () => ProblemModel.fromJson({'problemId': 1, 'folderId': null}),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );

    test(
      'folderId 키가 아예 없어도 예외가 난다',
      () {
        // TODO(#174): 위와 같은 버그. 키가 없을 때도 json['folderId'] 는 null 이 되어
        // 동일하게 TypeError 로 죽는다.
        expect(
          () => ProblemModel.fromJson({'problemId': 1}),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );

    test('solveCount 가 double(2.0)으로 와도 int 로 변환된다', () {
      final model = ProblemModel.fromJson({
        'problemId': 1,
        'folderId': 1,
        'solveCount': 2.0,
      });

      expect(model.solveCount, 2);
      expect(model.solveCount, isA<int>());
    });

    test('imageUrlList 가 빈 배열이면 세 이미지 리스트 모두 빈 배열이다', () {
      final model = ProblemModel.fromJson({
        'problemId': 1,
        'folderId': 1,
        'imageUrlList': <Map<String, dynamic>>[],
      });

      expect(model.problemImageDataList, isEmpty);
      expect(model.answerImageDataList, isEmpty);
      expect(model.solveImageDataList, isEmpty);
    });

    test('PROCESS_IMAGE 타입은 세 리스트 중 어디에도 담기지 않는다', () {
      final model = ProblemModel.fromJson({
        'problemId': 1,
        'folderId': 1,
        'imageUrlList': [_imageJson('PROCESS_IMAGE')],
      });

      expect(model.problemImageDataList, isEmpty);
      expect(model.answerImageDataList, isEmpty);
      expect(model.solveImageDataList, isEmpty);
    });

    test('이미지 타입별로 여러 장이면 각각의 리스트에 모두 담긴다', () {
      final model = ProblemModel.fromJson({
        'problemId': 1,
        'folderId': 1,
        'imageUrlList': [
          _imageJson('PROBLEM_IMAGE', url: 'https://cdn.test/p1.png'),
          _imageJson('PROBLEM_IMAGE', url: 'https://cdn.test/p2.png'),
          _imageJson('ANSWER_IMAGE', url: 'https://cdn.test/a1.png'),
        ],
      });

      expect(model.problemImageDataList, hasLength(2));
      expect(model.answerImageDataList, hasLength(1));
      expect(model.solveImageDataList, isEmpty);
    });

    test('tagIdList 와 tags 키가 아예 없으면 빈 리스트다', () {
      final model = ProblemModel.fromJson({'problemId': 1, 'folderId': 1});

      expect(model.tagIdList, isEmpty);
      expect(model.tags, isEmpty);
    });

    test('analysis 가 있으면 ProblemAnalysisModel 로 파싱된다', () {
      final model = ProblemModel.fromJson({
        'problemId': 1,
        'folderId': 1,
        'analysis': {
          'id': 5,
          'problemId': 1,
          'status': 'FAILED',
          'errorMessage': '분석 실패',
        },
      });

      expect(model.analysis, isNotNull);
      expect(model.analysis?.id, 5);
      expect(model.analysis?.status, ProblemAnalysisStatus.FAILED);
      expect(model.analysis?.errorMessage, '분석 실패');
    });
  });

  group('ProblemModel.updateAnalysis', () {
    test('analysis 필드만 바뀌고 나머지 필드는 그대로 복사된다', () {
      final original = ProblemModel.fromJson({
        'problemId': 1,
        'folderId': 1,
        'memo': '원래 메모',
        'solveCount': 3,
        'tagIdList': [1],
      });

      final newAnalysis = ProblemAnalysisModel(
        id: 99,
        status: ProblemAnalysisStatus.COMPLETED,
      );

      final updated = original.updateAnalysis(newAnalysis);

      expect(updated.problemId, original.problemId);
      expect(updated.memo, original.memo);
      expect(updated.solveCount, original.solveCount);
      expect(updated.tagIdList, original.tagIdList);
      expect(updated.analysis, newAnalysis);
      expect(updated.analysis?.id, 99);
      // 원본은 변경되지 않는다 (불변 객체로 다뤄지는지 확인).
      expect(original.analysis, isNull);
    });
  });
}
