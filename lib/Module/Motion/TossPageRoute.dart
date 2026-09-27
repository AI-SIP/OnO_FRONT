import 'package:flutter/cupertino.dart';

import 'AppMotion.dart';
import 'ScreenEnterTransition.dart';

/// 앱의 모든 화면 전환에 쓰는 라우트다.
///
/// `MaterialPageRoute` 는 Android 에서 아래에서 위로 페이드되고 iOS 에서는
/// 좌우로 밀려서, 같은 화면이 기기마다 다르게 열린다. 이것은 어느 쪽에서든
/// 오른쪽에서 밀려 들어오고 뒤 화면은 왼쪽으로 물러나면서 어두워진다.
///
/// ```dart
/// Navigator.push(
///   context,
///   TossPageRoute(builder: (_) => const ProblemDetailScreen(problemId: 1)),
/// );
/// ```
///
/// [CupertinoRouteTransitionMixin] 을 쓰는 이유는 화면 왼쪽 가장자리를 끌어
/// 뒤로 가는 제스처 때문이다. 전환만 직접 그리면 그 제스처가 사라지는데,
/// iOS 사용자에게는 뒤로가기 버튼보다 이쪽이 더 익숙하다. 대신 기본 전환
/// 시간이 500ms 로 느려서 [AppMotion.page] 로 줄였다.
class TossPageRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  /// 열릴 화면.
  final WidgetBuilder builder;

  TossPageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
    super.fullscreenDialog,
  });

  @override
  Widget buildContent(BuildContext context) {
    // 밀려 들어오는 것만으로는 도착한 뒤가 정지 화면처럼 보인다. 내용이
    // 아주 살짝 커지며 자리를 잡게 해서 떴다는 느낌을 준다.
    return ScreenEnterTransition(child: builder(context));
  }

  /// 뒤로가기 제스처 중에 뜨는 이전 화면 제목이다. 앱에서 쓰지 않는다.
  @override
  String? get title => null;

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
