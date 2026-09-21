import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 코드에 적힌 Analytics 이벤트 이름이 Firebase 규칙 안에 드는지 잠가 둔다.
///
/// Firebase 는 규칙을 어긴 이벤트를 에러 없이 버린다. 40자가 넘는 이름 셋이
/// 그렇게 한 번도 콘솔에 들어가지 못했는데, 앱에서는 아무 표시가 없어서
/// 콘솔과 코드를 대조하기 전까지 몰랐다 (#275).
void main() {
  // logEvent(name: '...') 와 TutorialProvider 의 _logEvent('...') 둘 다 잡는다.
  final pattern = RegExp(
    r"""(?:logEvent\(\s*name:\s*|_logEvent\()'([^']*)'""",
  );
  // 이름에 변수를 붙이는 곳은 변수 앞 고정 부분만 본다.
  final interpolation = RegExp(r'\$');
  final valid = RegExp(r'^[A-Za-z][A-Za-z0-9_]*$');

  List<(String, String)> collectEventNames() {
    final names = <(String, String)>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      for (final match in pattern.allMatches(file.readAsStringSync())) {
        names.add((file.path, match.group(1)!));
      }
    }
    return names;
  }

  test('이벤트 이름을 하나 이상 찾는다', () {
    // 정규식이 어긋나 아무것도 못 찾으면 아래 검사가 전부 그냥 통과한다.
    expect(collectEventNames().length, greaterThan(50));
  });

  test('이벤트 이름은 40자를 넘지 않는다', () {
    final tooLong = [
      for (final (path, name) in collectEventNames())
        if (name.length > 40) '$path: $name (${name.length}자)',
    ];

    expect(tooLong, isEmpty);
  });

  test('이벤트 이름은 영문자로 시작하고 영문자, 숫자, 밑줄만 쓴다', () {
    final invalid = [
      for (final (path, name) in collectEventNames())
        if (!valid.hasMatch(name.split(interpolation).first)) '$path: $name',
    ];

    expect(invalid, isEmpty);
  });

  test('firebase_, google_, ga_ 로 시작하는 이름은 쓰지 않는다', () {
    final reserved = [
      for (final (path, name) in collectEventNames())
        if (name.startsWith('firebase_') ||
            name.startsWith('google_') ||
            name.startsWith('ga_'))
          '$path: $name',
    ];

    expect(reserved, isEmpty);
  });
}
