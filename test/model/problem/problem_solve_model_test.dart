import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Model/Problem/ImprovementType.dart';
import 'package:ono/Model/Problem/ProblemSolveModel.dart';

void main() {
  group('ProblemSolveModel.fromJson', () {
    test('모든 필드가 채워진 정상 응답을 파싱한다', () {
      final json = {
        'problemSolveId': 10,
        'problemId': 7,
        'userId': 1,
        'practicedAt': '2026-01-10T09:00:00.000Z',
        'answerStatus': 'CORRECT',
        'reflection': '이번엔 잘 풀었다',
        'improvements': ['NO_REPEAT_MISTAKE', 'FASTER_SOLVING'],
        'timeSpentSeconds': 120,
        'migratedFromLegacy': false,
        'imageUrls': ['https://cdn.test/1.png'],
        'createdAt': '2026-01-10T09:05:00.000Z',
        'updatedAt': '2026-01-10T09:05:00.000Z',
      };

      final model = ProblemSolveModel.fromJson(json);

      expect(model.problemSolveId, 10);
      expect(model.problemId, 7);
      expect(model.userId, 1);
      expect(model.practicedAt, DateTime.parse('2026-01-10T09:00:00.000Z'));
      expect(model.answerStatus, AnswerStatus.CORRECT);
      expect(model.reflection, '이번엔 잘 풀었다');
      expect(model.improvements, [
        ImprovementType.NO_REPEAT_MISTAKE,
        ImprovementType.FASTER_SOLVING,
      ]);
      expect(model.timeSpentSeconds, 120);
      expect(model.migratedFromLegacy, isFalse);
      expect(model.imageUrls, ['https://cdn.test/1.png']);
      expect(model.createdAt, DateTime.parse('2026-01-10T09:05:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-01-10T09:05:00.000Z'));
    });

    test('reflection, timeSpentSeconds 가 null 이어도 파싱된다', () {
      final json = {
        'problemSolveId': 10,
        'problemId': 7,
        'userId': 1,
        'practicedAt': '2026-01-10T09:00:00.000Z',
        'answerStatus': 'WRONG',
        'reflection': null,
        'improvements': <String>[],
        'timeSpentSeconds': null,
        'migratedFromLegacy': false,
        'imageUrls': <String>[],
        'createdAt': '2026-01-10T09:05:00.000Z',
        'updatedAt': '2026-01-10T09:05:00.000Z',
      };

      final model = ProblemSolveModel.fromJson(json);

      expect(model.reflection, isNull);
      expect(model.timeSpentSeconds, isNull);
    });

    test('improvements, imageUrls, migratedFromLegacy 키가 없으면 기본값으로 떨어진다', () {
      final model = ProblemSolveModel.fromJson({
        'problemSolveId': 10,
        'problemId': 7,
        'userId': 1,
        'practicedAt': '2026-01-10T09:00:00.000Z',
        'answerStatus': 'PARTIAL',
        'createdAt': '2026-01-10T09:05:00.000Z',
        'updatedAt': '2026-01-10T09:05:00.000Z',
      });

      expect(model.improvements, isEmpty);
      expect(model.imageUrls, isEmpty);
      expect(model.migratedFromLegacy, isFalse);
    });

    test('improvements 안에 서버가 모르는 값이 있으면 NO_REPEAT_MISTAKE 로 폴백된다', () {
      final model = ProblemSolveModel.fromJson({
        'problemSolveId': 10,
        'problemId': 7,
        'userId': 1,
        'practicedAt': '2026-01-10T09:00:00.000Z',
        'answerStatus': 'CORRECT',
        'improvements': ['ALIEN_IMPROVEMENT'],
        'createdAt': '2026-01-10T09:05:00.000Z',
        'updatedAt': '2026-01-10T09:05:00.000Z',
      });

      expect(model.improvements, [ImprovementType.NO_REPEAT_MISTAKE]);
    });

    test('answerStatus 에 서버가 모르는 값이 오면 UNKNOWN 으로 떨어진다', () {
      final model = ProblemSolveModel.fromJson({
        'problemSolveId': 10,
        'problemId': 7,
        'userId': 1,
        'practicedAt': '2026-01-10T09:00:00.000Z',
        'answerStatus': 'ALIEN_STATUS',
        'createdAt': '2026-01-10T09:05:00.000Z',
        'updatedAt': '2026-01-10T09:05:00.000Z',
      });

      expect(model.answerStatus, AnswerStatus.UNKNOWN);
    });

    test(
      'answerStatus 키가 아예 없으면 UNKNOWN 폴백 대신 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Problem/ProblemSolveModel.dart:39 에서
        // AnswerStatusExtension.fromJson(json['answerStatus']) 를 그대로 호출하는데,
        // fromJson 의 파라미터가 non-nullable String 이라 키가 없어 null 이 들어오면
        // "모르는 값은 UNKNOWN 으로" 라는 설계 의도와 다르게 TypeError 로 죽는다.
        expect(
          () => ProblemSolveModel.fromJson({
            'problemSolveId': 10,
            'problemId': 7,
            'userId': 1,
            'practicedAt': '2026-01-10T09:00:00.000Z',
            'createdAt': '2026-01-10T09:05:00.000Z',
            'updatedAt': '2026-01-10T09:05:00.000Z',
          }),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );

    test(
      'problemSolveId 가 double(10.0)로 오면 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Problem/ProblemSolveModel.dart:35 에서
        // problemSolveId: json['problemSolveId'] 를 캐스팅 없이 그대로 대입한다.
        // ProblemModel.solveCount 는 (json['solveCount'] as num?)?.toInt() 로
        // 방어적으로 처리하는 것과 달리, 여기는 서버가 숫자를 double 로 내려주면
        // (예: JSON 상 10.0) TypeError 로 죽는다.
        expect(
          () => ProblemSolveModel.fromJson({
            'problemSolveId': 10.0,
            'problemId': 7,
            'userId': 1,
            'practicedAt': '2026-01-10T09:00:00.000Z',
            'answerStatus': 'CORRECT',
            'createdAt': '2026-01-10T09:05:00.000Z',
            'updatedAt': '2026-01-10T09:05:00.000Z',
          }),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );

    test('practicedAt, createdAt, updatedAt 이 없으면 예외가 난다', () {
      expect(
        () => ProblemSolveModel.fromJson({
          'problemSolveId': 10,
          'problemId': 7,
          'userId': 1,
          'answerStatus': 'CORRECT',
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('ProblemSolveModel.toJson', () {
    test('서버가 받는 키 이름으로 정확히 직렬화되고 round-trip 된다', () {
      final original = {
        'problemSolveId': 10,
        'problemId': 7,
        'userId': 1,
        'practicedAt': '2026-01-10T09:00:00.000Z',
        'answerStatus': 'CORRECT',
        'reflection': '이번엔 잘 풀었다',
        'improvements': ['FASTER_SOLVING'],
        'timeSpentSeconds': 120,
        'migratedFromLegacy': false,
        'imageUrls': ['https://cdn.test/1.png'],
        'createdAt': '2026-01-10T09:05:00.000Z',
        'updatedAt': '2026-01-10T09:05:00.000Z',
      };

      final roundTripped = ProblemSolveModel.fromJson(original).toJson();

      expect(roundTripped, original);
    });
  });
}
