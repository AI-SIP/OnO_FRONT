import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ProblemAnalysisStatus.dart';

void main() {
  group('ProblemAnalysisStatus', () {
    test('정상적인 값들을 각각 열거형으로 파싱한다', () {
      expect(
        ProblemAnalysisStatus.fromString('NOT_STARTED'),
        ProblemAnalysisStatus.NOT_STARTED,
      );
      expect(
        ProblemAnalysisStatus.fromString('PROCESSING'),
        ProblemAnalysisStatus.PROCESSING,
      );
      expect(
        ProblemAnalysisStatus.fromString('COMPLETED'),
        ProblemAnalysisStatus.COMPLETED,
      );
      expect(
        ProblemAnalysisStatus.fromString('FAILED'),
        ProblemAnalysisStatus.FAILED,
      );
      expect(
        ProblemAnalysisStatus.fromString('NO_IMAGE'),
        ProblemAnalysisStatus.NO_IMAGE,
      );
    });

    test('null 이 오면 null 을 돌려준다 (예외를 던지지 않는다)', () {
      expect(ProblemAnalysisStatus.fromString(null), isNull);
    });

    test('서버가 모르는 값을 보내면 null 을 돌려준다', () {
      expect(ProblemAnalysisStatus.fromString('SOMETHING_NEW'), isNull);
    });

    test('빈 문자열도 null 을 돌려준다', () {
      expect(ProblemAnalysisStatus.fromString(''), isNull);
    });

    test('toJson 은 enum 이름 그대로를 돌려준다', () {
      expect(ProblemAnalysisStatus.NOT_STARTED.toJson(), 'NOT_STARTED');
      expect(ProblemAnalysisStatus.COMPLETED.toJson(), 'COMPLETED');
      expect(ProblemAnalysisStatus.NO_IMAGE.toJson(), 'NO_IMAGE');
    });
  });
}
