import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ImprovementType.dart';

void main() {
  group('ImprovementType', () {
    test('정상적인 값들을 각각 열거형으로 파싱한다', () {
      expect(
        ImprovementTypeExtension.fromJson('NO_REPEAT_MISTAKE'),
        ImprovementType.NO_REPEAT_MISTAKE,
      );
      expect(
        ImprovementTypeExtension.fromJson('FOUND_NEW_SOLUTION'),
        ImprovementType.FOUND_NEW_SOLUTION,
      );
      expect(
        ImprovementTypeExtension.fromJson('BETTER_UNDERSTANDING'),
        ImprovementType.BETTER_UNDERSTANDING,
      );
      expect(
        ImprovementTypeExtension.fromJson('FASTER_SOLVING'),
        ImprovementType.FASTER_SOLVING,
      );
    });

    test('서버가 모르는 값을 보내면 NO_REPEAT_MISTAKE 로 떨어진다', () {
      // AnswerStatus 의 UNKNOWN 과 달리 이 enum 에는 전용 폴백 값이 없어서,
      // orElse 가 목록의 첫 번째 값으로 떨어진다. 의도한 동작인지는 불명확하지만
      // 최소한 예외 없이 파싱은 된다.
      expect(
        ImprovementTypeExtension.fromJson('SOMETHING_NEW'),
        ImprovementType.NO_REPEAT_MISTAKE,
      );
    });

    test('toJson 은 enum 이름 그대로를 돌려준다', () {
      expect(ImprovementType.NO_REPEAT_MISTAKE.toJson(), 'NO_REPEAT_MISTAKE');
      expect(ImprovementType.FASTER_SOLVING.toJson(), 'FASTER_SOLVING');
    });

    test('description 이 각 값에 맞는 한글 문구를 준다', () {
      expect(ImprovementType.NO_REPEAT_MISTAKE.description, '이전 실수를 반복하지 않았어요');
      expect(ImprovementType.FOUND_NEW_SOLUTION.description, '새로운 풀이법을 찾았어요');
      expect(
          ImprovementType.BETTER_UNDERSTANDING.description, '개념을 더 명확히 이해했어요');
      expect(ImprovementType.FASTER_SOLVING.description, '풀이 시간이 단축됐어요');
    });
  });
}
