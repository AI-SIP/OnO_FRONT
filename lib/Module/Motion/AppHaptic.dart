import 'package:flutter/services.dart';

/// 어떤 상황에 어떤 세기의 진동을 줄지 정해 둔 것이다.
///
/// 화면에서 `HapticFeedback` 을 직접 부르지 않고 이 세 가지 중 하나를 고른다.
/// 세기를 판단하는 기준을 한 곳에 모아 두려는 것이고, 나중에 설정에서 햅틱을
/// 끄는 기능을 넣게 되면 여기만 손보면 된다.
abstract final class AppHaptic {
  /// 되돌리기 어렵거나 흐름이 끝나는 액션. 등록 완료, 삭제 확정, 제출.
  static Future<void> primary() => HapticFeedback.mediumImpact();

  /// 화면을 넘기거나 항목을 여는 정도의 일반적인 탭.
  static Future<void> secondary() => HapticFeedback.lightImpact();

  /// 값이 바뀌는 것. 토글, 탭 전환, 칩 선택, 날짜 고르기.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// [level] 에 해당하는 진동을 준다. [PressableScale] 이 쓴다.
  static Future<void> of(HapticLevel level) {
    switch (level) {
      case HapticLevel.none:
        return Future<void>.value();
      case HapticLevel.primary:
        return primary();
      case HapticLevel.secondary:
        return secondary();
      case HapticLevel.selection:
        return selection();
    }
  }
}

/// [AppHaptic] 의 세 가지를 위젯 파라미터로 넘기기 위한 것이다.
enum HapticLevel {
  /// 진동을 주지 않는다. 목록을 스크롤하다 누르는 항목처럼 잦은 탭에 쓴다.
  none,

  /// [AppHaptic.primary]
  primary,

  /// [AppHaptic.secondary]
  secondary,

  /// [AppHaptic.selection]
  selection,
}
