import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Model/Problem/ImprovementType.dart';
import 'package:ono/Model/Problem/ProblemSolveRegisterDto.dart';

void main() {
  group('ProblemSolveRegisterDto.toJson', () {
    test('모든 필드가 채워지면 서버가 받는 키 이름으로 직렬화된다', () {
      final dto = ProblemSolveRegisterDto(
        problemId: 7,
        practicedAt: DateTime.parse('2026-01-10T09:00:00.000Z'),
        answerStatus: AnswerStatus.CORRECT,
        reflection: '잘 풀었다',
        improvements: const [ImprovementType.FASTER_SOLVING],
        timeSpentSeconds: 90,
      );

      expect(dto.toJson(), {
        'problemId': 7,
        'practicedAt': '2026-01-10T09:00:00.000Z',
        'answerStatus': 'CORRECT',
        'reflection': '잘 풀었다',
        'improvements': ['FASTER_SOLVING'],
        'timeSpentSeconds': 90,
      });
    });

    test('reflection, timeSpentSeconds 가 null 이어도 null 로 직렬화된다', () {
      final dto = ProblemSolveRegisterDto(
        problemId: 7,
        practicedAt: DateTime.parse('2026-01-10T09:00:00.000Z'),
        answerStatus: AnswerStatus.WRONG,
        improvements: const [],
      );

      final json = dto.toJson();

      expect(json['reflection'], isNull);
      expect(json['timeSpentSeconds'], isNull);
      expect(json['improvements'], isEmpty);
    });
  });
}
