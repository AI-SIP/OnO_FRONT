import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';

void main() {
  group('ProblemImageType', () {
    // 서버와 문자열로 주고받는 계약이므로, name 이 그대로 서버 전송 값이 된다.
    // 이름이 실수로 바뀌면 서버와 어긋나므로 고정해 둔다.
    test('PROBLEM_IMAGE, ANSWER_IMAGE, SOLVE_IMAGE, PROCESS_IMAGE 네 값을 갖는다',
        () {
      expect(ProblemImageType.values.map((e) => e.name), [
        'PROBLEM_IMAGE',
        'ANSWER_IMAGE',
        'SOLVE_IMAGE',
        'PROCESS_IMAGE',
      ]);
    });

    test('name 으로 값을 다시 찾을 수 있다 (서버 문자열 round-trip)', () {
      for (final type in ProblemImageType.values) {
        final found =
            ProblemImageType.values.firstWhere((e) => e.name == type.name);
        expect(found, type);
      }
    });
  });
}
