import 'package:flutter/widgets.dart';

/// 아래에 있는 게이지와 등장 모션을 처음부터 다시 재생시키는 장치다.
///
/// 홈 화면은 탭 넷을 `IndexedStack` 으로 들고 있어서, 앱을 켜는 순간 마이
/// 페이지까지 함께 만들어진다. 그래서 게이지는 탭을 누르기도 전에 이미 다
/// 차 있고, 정작 화면에 들어갔을 때는 아무것도 움직이지 않는다.
///
/// 탭이 다시 선택될 때마다 [token] 을 바꾸면 그 아래 모든 게이지와 등장
/// 모션이 0 에서 다시 시작한다.
///
/// ```dart
/// MotionReplayScope(
///   token: _visitSequence,
///   child: ListView(children: [UserLevelCard(...), StreakCard(...)]),
/// )
/// ```
///
/// 화면 쪽에서는 감싸기만 하면 되고, 안에 있는 위젯은 이것을 몰라도 된다.
class MotionReplayScope extends InheritedWidget {
  /// 이 값이 바뀔 때마다 아래 모션이 다시 재생된다.
  final Object token;

  const MotionReplayScope({
    super.key,
    required this.token,
    required super.child,
  });

  /// 위쪽에 [MotionReplayScope] 가 없으면 null 을 준다. 감싸지 않은 화면에서도
  /// 게이지가 그대로 동작해야 하므로 없는 것이 정상인 경우다.
  static Object? maybeTokenOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MotionReplayScope>()
        ?.token;
  }

  @override
  bool updateShouldNotify(MotionReplayScope oldWidget) {
    return token != oldWidget.token;
  }
}

/// [MotionReplayScope] 의 토큰이 바뀌면 애니메이션을 처음부터 다시 트는
/// State 들이 공유하는 부분이다.
///
/// 토큰이 바뀌면 [replaySeed] 가 늘어난다. 이 값을 애니메이션 위젯의 key 에
/// 넣어 두면 위젯이 새로 만들어지면서 시작값부터 다시 그려진다. 값만 0 으로
/// 되돌리면 되돌아가는 과정까지 애니메이션으로 보인다.
mixin MotionReplayMixin<T extends StatefulWidget> on State<T> {
  Object? _token;
  bool _tokenRead = false;
  int _replaySeed = 0;

  /// 애니메이션 위젯의 key 에 넣을 값.
  int get replaySeed => _replaySeed;

  /// 토큰이 바뀌어 다시 재생해야 할 때 불린다. 구현하는 쪽에서 시작 상태로
  /// 되돌리면 된다.
  void onMotionReplay();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = MotionReplayScope.maybeTokenOf(context);
    final isFirstRead = !_tokenRead;
    _tokenRead = true;

    if (isFirstRead) {
      _token = token;
      return;
    }
    if (token == _token) return;

    _token = token;
    _replaySeed++;
    onMotionReplay();
  }
}
