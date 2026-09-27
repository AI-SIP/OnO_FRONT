// 미션 재조회를 부르는 자리를 잠근다.
//
// 이 두 가지는 위젯으로 재현하기가 어렵다. 복습 저장 화면은 안에서
// `ProblemSolveService()` 를 직접 만들어 써서 가짜를 끼울 수 없고, 앱 복귀
// 처리는 `main.dart` 의 `MyApp` 안에 있어서 Firebase 초기화까지 따라온다.
// 그래서 호출부의 모양을 소스에서 확인한다. 다른 방법으로 검증할 수 있게
// 되면 이 파일은 지워도 된다.
//
// 잠그는 것은 두 가지다.
//
// 1. 행동 화면들은 미션 조회를 **기다리지 않는다.** 서버에 아직 미션 API 가
//    없어서 이 요청은 반드시 실패하는데, 기다리면 저장이 끝난 뒤에도 GET
//    타임아웃(30초)만큼 로딩이 더 떠 있는다.
// 2. 앱 복귀 조회는 **로그인 상태일 때만** 나간다. 토큰이 없는 채로 요청을
//    보내면 인증 실패 처리를 괜히 건드린다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path 가 없다');
  return file.readAsStringSync();
}

void main() {
  group('행동이 끝난 뒤의 미션 재조회', () {
    const callSites = <String>[
      'lib/Screen/ProblemSolve/ProblemSolveRegisterScreen.dart',
      'lib/Screen/ProblemRegister/ProblemRegisterTemplate.dart',
      'lib/Screen/PracticeNote/PracticeCompletionScreen.dart',
    ];

    for (final path in callSites) {
      test('$path 는 미션 조회를 기다리지 않는다', () {
        final source = _read(path);

        expect(
          source.contains('fetchMissions()'),
          isTrue,
          reason: '행동이 끝난 뒤 미션을 다시 조회해야 진행도가 바로 반영된다',
        );
        expect(
          RegExp(r'\bawait\b[^;]*fetchMissions\(\)').hasMatch(source),
          isFalse,
          reason: '기다리면 저장이 끝난 뒤에도 미션 조회 타임아웃만큼 로딩이 더 떠 있는다',
        );
        expect(source.contains('unawaited('), isTrue);
      });
    }
  });

  group('앱 복귀 조회', () {
    test('로그인 상태일 때만 미션을 조회한다', () {
      final source = _read('lib/main.dart');
      final start = source.indexOf('didChangeAppLifecycleState');
      expect(start, greaterThan(-1));

      final body = source.substring(start, source.indexOf('@override', start));
      expect(body.contains('fetchMissions()'), isTrue);
      expect(
        body.contains('LoginStatus.login'),
        isTrue,
        reason: '로그아웃 상태로 복귀하면 인증 실패 처리를 건드리는 경로가 생긴다',
      );
    });
  });
}
