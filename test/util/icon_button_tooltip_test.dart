import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 아이콘만 있는 버튼은 스크린 리더가 이름 없는 버튼으로 읽는다.
/// `IconButton` 을 새로 만들 때 `tooltip` 을 빠뜨리지 않게 막는다.
void main() {
  test('lib 의 IconButton 은 모두 tooltip 을 가진다', () {
    final missing = <String>[];
    final start = RegExp(r'(?<![A-Za-z_])IconButton\(');
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final match in start.allMatches(source)) {
        var depth = 1;
        var i = match.end;
        while (depth > 0 && i < source.length) {
          final c = source[i];
          if (c == '(') depth++;
          if (c == ')') depth--;
          i++;
        }
        final body = source.substring(match.start, i);
        if (!body.contains('tooltip')) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          missing.add('${entity.path}:${line + 1}');
        }
      }
    }
    expect(missing, isEmpty, reason: 'tooltip 이 없는 IconButton:\n$missing');
  });
}
