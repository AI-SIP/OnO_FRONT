import 'package:flutter/foundation.dart';

/// 화면에 날짜나 시각을 보여 줄 때 읽는 시계.
///
/// `N일 전`, `오늘 마감`, 이번 달 달력처럼 **지금 시각에 따라 문구가 달라지는
/// 자리**는 `DateTime.now()` 대신 이것을 읽는다. 앱에서는 늘 `DateTime.now()` 와
/// 같다. 테스트에서만 시계를 고정할 수 있게 열어 둔다.
///
/// 골든 테스트는 화면을 이미지로 떠 두고 다음 실행과 비교하는데, 문구가 실행하는
/// 날짜에 매여 있으면 날마다 깨진다. 연타를 막으려고 시각을 재는 것처럼 화면에
/// 안 나오는 곳은 바꿀 필요가 없다.
///
/// 이 클래스는 전부 static 이라 생성자 주입을 쓸 수 없어 `AppErrorReporter` 의
/// 전송기와 같은 방식으로 연다.
class AppClock {
  const AppClock._();

  static DateTime Function() _now = DateTime.now;

  static DateTime now() => _now();

  /// 시계를 고정한다. 쓴 쪽이 tearDown 에서 [resetForTest] 로 되돌린다.
  @visibleForTesting
  static void setForTest(DateTime Function() now) => _now = now;

  @visibleForTesting
  static void resetForTest() => _now = DateTime.now;
}
