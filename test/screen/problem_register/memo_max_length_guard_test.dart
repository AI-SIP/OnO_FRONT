// 메모 입력의 길이 제한을 잠근다.
//
// 서버 problem.memo 컬럼은 1000자다. 프론트가 더 긴 글을 그대로 보내면 DB 에서
// Data truncation 이 나고 앱에는 500 이 떨어져, 사용자는 "서버 내부 오류가
// 발생했습니다" 스낵바만 보고 작성한 내용을 잃는다(Sentry FLUTTER-13Z /
// FLUTTER-11W). 그래서 입력 단계에서 막는다.
//
// 두 등록 화면 모두 안에서 ProblemService 를 직접 만들어 써서 화면째로 띄워
// 검증하기가 어렵다. 그래서 호출부의 모양을 소스에서 확인한다. 화면 테스트를
// 붙일 수 있게 되면 이 파일은 지워도 된다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ProblemRegisterModel.dart';

String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path 가 없다');
  return file.readAsStringSync();
}

/// `label: '메모'` 가 들어 있는 LabeledTextField 호출 한 덩어리를 잘라 낸다.
String _memoFieldSource(String source) {
  final labelAt = source.indexOf("label: '메모'");
  expect(labelAt, greaterThan(-1), reason: '메모 입력 필드를 찾지 못했다');

  final open = source.lastIndexOf('LabeledTextField(', labelAt);
  expect(open, greaterThan(-1), reason: '메모 필드가 LabeledTextField 가 아니다');

  final close = source.indexOf('),', labelAt);
  expect(close, greaterThan(open));
  return source.substring(open, close);
}

void main() {
  test('서버 memo 컬럼 길이와 같은 값을 쓴다', () {
    expect(ProblemRegisterModel.memoMaxLength, 1000);
  });

  const callSites = <String>[
    'lib/Screen/ProblemRegister/ProblemRegisterTemplate.dart',
    'lib/Screen/ProblemRegister/MultiProblemRegisterScreen.dart',
  ];

  for (final path in callSites) {
    test('$path 의 메모 필드는 길이 제한을 건다', () {
      final field = _memoFieldSource(_read(path));

      expect(
        field.contains('maxLength: ProblemRegisterModel.memoMaxLength'),
        isTrue,
        reason: '제한이 없으면 1000자를 넘긴 메모가 그대로 나가 저장이 500 으로 실패한다',
      );
    });
  }
}
