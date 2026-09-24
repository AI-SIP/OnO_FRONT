import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 알림이 다시 화면 아래에서 올라오지 않도록 잠가 둔다.
///
/// 앱의 알림은 위에서 내려오는 `AppToast` 로 통일했다. 그런데 화면을 새로
/// 만들면서 `SnackBar` 를 직접 띄우면 그 화면에서만 예전처럼 아래에서
/// 올라오고, 하단 버튼이나 탭 바를 가린다. 실제로 복습 세트 삭제와 스터디룸
/// 문제 공유 두 곳이 그렇게 남아 있었다 (#279).
///
/// `SnackBarDialog.showSnackBar` 와 `AppSnackBar.showError` 는 이름만
/// 스낵바고 안쪽은 `AppToast` 를 부른다. 호출부를 한꺼번에 고치지 않으려고
/// 이름을 남겨 둔 것이라 여기서 걸리지 않는다. 이 검사가 잡는 것은
/// `SnackBar` 위젯을 직접 만드는 코드뿐이다.
void main() {
  /// `SnackBar(` 를 만드는 자리만 찾는다. 앞에 글자나 점이 붙어 있으면
  /// `showSnackBar(` 이나 `SnackBarDialog` 처럼 다른 이름의 일부이므로 뺀다.
  final snackBarConstruction = RegExp(r'(?<![\w.])SnackBar\(');

  List<File> dartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  test('검사할 소스를 찾는다', () {
    // 경로가 어긋나 아무것도 못 읽으면 아래 검사가 그냥 통과한다.
    expect(dartFiles().length, greaterThan(100));
  });

  test('lib 안에서 SnackBar 를 직접 띄우지 않는다', () {
    final offenders = <String>[];
    for (final file in dartFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (snackBarConstruction.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: '알림은 AppToast 로 띄운다. SnackBar 를 직접 만든 곳: ${offenders.join(', ')}',
    );
  });
}
