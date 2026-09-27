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
        'moodEmojiKey': null,
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

    test('PATCH 는 전체 교체라 기분 이모지도 항상 실린다', () {
      // 이 키를 빼고 보내면 서버가 null 로 덮어써서 이모지가 지워진다.
      // 바꿀 생각이 없어도 기존 값을 그대로 실어야 한다.
      final keep = ProblemSolveUpdateDto(
        problemSolveId: 10,
        answerStatus: AnswerStatus.CORRECT,
        improvements: const [],
        moodEmojiKey: 'excited_happy',
      );

      expect(keep.toJson()['moodEmojiKey'], 'excited_happy');
    });

    test('이모지를 해제할 때는 null 을 실어 보낸다', () {
      // 따로 해제 API 는 없다.
      final clear = ProblemSolveUpdateDto(
        problemSolveId: 10,
        answerStatus: AnswerStatus.CORRECT,
        improvements: const [],
        moodEmojiKey: null,
      );

      expect(clear.toJson().containsKey('moodEmojiKey'), isTrue);
      expect(clear.toJson()['moodEmojiKey'], isNull);
    });
  });
}
