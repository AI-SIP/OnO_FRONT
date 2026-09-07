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
        'moodEmojiKey': null,
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

    test('기분 이모지를 고르면 키 문자열로 실린다', () {
      // 유니코드 이모지 문자가 아니라 키를 보내야 한다. 서버가 화이트리스트로
      // 검사해서 이모지 문자를 보내면 400 / errorCode 11001 로 떨어진다.
      final dto = ProblemSolveRegisterDto(
        problemId: 7,
        practicedAt: DateTime.parse('2026-01-10T09:00:00.000Z'),
        answerStatus: AnswerStatus.WRONG,
        improvements: const [],
        moodEmojiKey: 'stressed_bomb',
      );

      expect(dto.toJson()['moodEmojiKey'], 'stressed_bomb');
    });

    test('기분을 안 고르면 null 로 실린다', () {
      final dto = ProblemSolveRegisterDto(
        problemId: 7,
        practicedAt: DateTime.parse('2026-01-10T09:00:00.000Z'),
        answerStatus: AnswerStatus.CORRECT,
        improvements: const [],
      );

      expect(dto.toJson().containsKey('moodEmojiKey'), isTrue);
      expect(dto.toJson()['moodEmojiKey'], isNull);
    });
  });
}
