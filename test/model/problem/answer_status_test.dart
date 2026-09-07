import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';

void main() {
  group('AnswerStatus', () {
    test('정상적인 값들을 각각 열거형으로 파싱한다', () {
      expect(AnswerStatusExtension.fromJson('CORRECT'), AnswerStatus.CORRECT);
      expect(AnswerStatusExtension.fromJson('WRONG'), AnswerStatus.WRONG);
      expect(AnswerStatusExtension.fromJson('PARTIAL'), AnswerStatus.PARTIAL);
      expect(AnswerStatusExtension.fromJson('UNKNOWN'), AnswerStatus.UNKNOWN);
    });

    test('서버가 모르는 값을 보내면 UNKNOWN 으로 떨어진다', () {
      expect(
        AnswerStatusExtension.fromJson('SOMETHING_NEW'),
        AnswerStatus.UNKNOWN,
      );
    });

    test('빈 문자열도 UNKNOWN 으로 떨어진다', () {
      expect(AnswerStatusExtension.fromJson(''), AnswerStatus.UNKNOWN);
    });

    test(
      'null 이 오면 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/Problem/AnswerStatus.dart:26 의
        // fromJson(String json) 이 non-nullable 파라미터라 null 이 들어오면
        // orElse 로 UNKNOWN 폴백되지 않고 바로 TypeError 로 죽는다.
        // 실제 응답에서 answerStatus 키 자체가 빠졌을 때(dynamic null) 벌어지는 상황을
        // 재현하기 위해, 정적으로 항상 실패가 보이는 `null as String` 대신
        // dynamic 값을 거쳐서 캐스팅한다.
        final Map<String, dynamic> jsonWithoutAnswerStatus = {};
        expect(
          () => AnswerStatusExtension.fromJson(
            jsonWithoutAnswerStatus['answerStatus'] as String,
          ),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );

    test('toJson 은 enum 이름 그대로를 돌려준다', () {
      expect(AnswerStatus.CORRECT.toJson(), 'CORRECT');
      expect(AnswerStatus.WRONG.toJson(), 'WRONG');
      expect(AnswerStatus.PARTIAL.toJson(), 'PARTIAL');
      expect(AnswerStatus.UNKNOWN.toJson(), 'UNKNOWN');
    });

    test('displayName 이 각 상태에 맞는 한글 문구를 준다', () {
      expect(AnswerStatus.CORRECT.displayName, '정답');
      expect(AnswerStatus.WRONG.displayName, '오답');
      expect(AnswerStatus.PARTIAL.displayName, '부분 정답');
      expect(AnswerStatus.UNKNOWN.displayName, '알 수 없음');
    });
  });
}
