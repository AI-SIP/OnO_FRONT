import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Model/Problem/ImprovementType.dart';
import 'package:ono/Model/Problem/ProblemSolveUpdateDto.dart';

void main() {
  group('ProblemSolveUpdateDto.toJson', () {
    test('모든 필드가 채워지면 서버가 받는 키 이름으로 직렬화된다', () {
      final dto = ProblemSolveUpdateDto(
        problemSolveId: 10,
        answerStatus: AnswerStatus.PARTIAL,
        reflection: '조금 아쉬웠다',
        improvements: const [
          ImprovementType.BETTER_UNDERSTANDING,
          ImprovementType.NO_REPEAT_MISTAKE,
        ],
        timeSpentSeconds: 200,
      );

      expect(dto.toJson(), {
        'problemSolveId': 10,
        'answerStatus': 'PARTIAL',
        'reflection': '조금 아쉬웠다',
        'improvements': ['BETTER_UNDERSTANDING', 'NO_REPEAT_MISTAKE'],
        'timeSpentSeconds': 200,
      });
    });

    test('reflection, timeSpentSeconds 가 null 이어도 null 로 직렬화된다', () {
      final dto = ProblemSolveUpdateDto(
        problemSolveId: 10,
        answerStatus: AnswerStatus.CORRECT,
        improvements: const [],
      );

      final json = dto.toJson();

      expect(json['reflection'], isNull);
      expect(json['timeSpentSeconds'], isNull);
      expect(json['improvements'], isEmpty);
    });
  });
}
