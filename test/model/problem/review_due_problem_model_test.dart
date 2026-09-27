import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';

void main() {
  group('ReviewDueProblemModel.fromJson', () {
    test('모든 필드가 채워진 정상 응답을 파싱한다', () {
      final model = ReviewDueProblemModel.fromJson({
        'problemId': 7,
        'memo': '메모',
        'reference': '기출문제집',
        'nextReviewAt': '2026-01-20T09:00:00.000Z',
        'reviewInterval': 3,
        'consecutiveCorrectCount': 2,
      });

      expect(model.problemId, 7);
      expect(model.memo, '메모');
      expect(model.reference, '기출문제집');
      expect(model.nextReviewAt, DateTime.parse('2026-01-20T09:00:00.000Z'));
      expect(model.reviewInterval, 3);
      expect(model.consecutiveCorrectCount, 2);
    });

    test('memo, reference, nextReviewAt 이 null 이어도 파싱된다', () {
      final model = ReviewDueProblemModel.fromJson({
        'problemId': 7,
        'memo': null,
        'reference': null,
        'nextReviewAt': null,
        'reviewInterval': 1,
        'consecutiveCorrectCount': 0,
      });

      expect(model.memo, isNull);
      expect(model.reference, isNull);
      expect(model.nextReviewAt, isNull);
    });

    test('reviewInterval, consecutiveCorrectCount 키가 없으면 기본값(1, 0)으로 떨어진다', () {
      final model = ReviewDueProblemModel.fromJson({'problemId': 7});

      expect(model.reviewInterval, 1);
      expect(model.consecutiveCorrectCount, 0);
    });

    test('nextReviewAt 문자열이 파싱 불가능한 값이면 예외 없이 null 로 떨어진다', () {
      // DateTime.tryParse 를 쓰기 때문에 형식이 이상해도 죽지 않는다.
      final model = ReviewDueProblemModel.fromJson({
        'problemId': 7,
        'nextReviewAt': '이건-날짜가-아니다',
      });

      expect(model.nextReviewAt, isNull);
    });

    test(
      'reviewInterval 이 double(3.0)로 오면 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Problem/ReviewDueProblemModel.dart:26 에서
        // reviewInterval: json['reviewInterval'] as int? 로, num 이 아닌 int 로만
        // 캐스팅한다. ProblemModel.solveCount 처럼 (json[...] as num?)?.toInt() 를
        // 썼다면 안전했을 텐데, 여기는 서버가 3.0 같은 double 을 내려주면 죽는다.
        expect(
          () => ReviewDueProblemModel.fromJson({
            'problemId': 7,
            'reviewInterval': 3.0,
          }),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );
  });

  group('ReviewDueResponse.fromJson', () {
    test('data 래퍼가 있는 응답을 파싱한다', () {
      final response = ReviewDueResponse.fromJson({
        'errorCode': null,
        'message': null,
        'data': {
          'dueCount': 2,
          'overdueCount': 1,
          'problems': [
            {'problemId': 1, 'reviewInterval': 1, 'consecutiveCorrectCount': 0},
            {'problemId': 2, 'reviewInterval': 2, 'consecutiveCorrectCount': 1},
          ],
        },
      });

      expect(response.dueCount, 2);
      expect(response.overdueCount, 1);
      expect(response.problems, hasLength(2));
      expect(response.problems.first.problemId, 1);
    });

    test('data 래퍼가 없는 응답(최상위가 바로 데이터)도 파싱한다', () {
      final response = ReviewDueResponse.fromJson({
        'dueCount': 3,
        'overdueCount': 0,
        'problems': <Map<String, dynamic>>[],
      });

      expect(response.dueCount, 3);
      expect(response.overdueCount, 0);
      expect(response.problems, isEmpty);
    });

    test('dueCount, overdueCount, problems 키가 없으면 기본값으로 떨어진다', () {
      final response =
          ReviewDueResponse.fromJson({'data': <String, dynamic>{}});

      expect(response.dueCount, 0);
      expect(response.overdueCount, 0);
      expect(response.problems, isEmpty);
    });
  });
}
