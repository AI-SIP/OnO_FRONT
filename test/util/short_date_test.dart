import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Util/ShortDate.dart';

void main() {
  final now = DateTime(2026, 10, 5);

  test('올해 날짜는 월/일만 쓴다', () {
    expect(shortDate(DateTime(2026, 3, 5), now: now), '3/5');
  });

  test('다른 해면 연도 두 자리를 붙인다', () {
    expect(shortDate(DateTime(2024, 3, 5), now: now), '24/3/5');
  });
}
