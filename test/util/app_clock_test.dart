// lib/Util/AppClock.dart 검증.
//
// 앱에서는 늘 실제 시각이어야 하고, 테스트가 고정한 시계는 되돌리면 풀려야 한다.
// 풀리지 않으면 다음 테스트 파일까지 멈춘 시계로 돈다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Util/AppClock.dart';

void main() {
  tearDown(AppClock.resetForTest);

  test('고정하지 않으면 실제 시각을 돌려준다', () {
    final before = DateTime.now();
    final now = AppClock.now();
    final after = DateTime.now();

    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(after), isFalse);
  });

  test('고정하면 고정한 시각을 돌려준다', () {
    final fixed = DateTime(2026, 9, 10, 15, 0);
    AppClock.setForTest(() => fixed);

    expect(AppClock.now(), fixed);
  });

  test('되돌리면 다시 실제 시각이다', () {
    AppClock.setForTest(() => DateTime(2000));
    AppClock.resetForTest();

    expect(AppClock.now().year, greaterThan(2000));
  });
}
