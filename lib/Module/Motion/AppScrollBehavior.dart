import 'package:flutter/material.dart';

/// 앱 전체의 스크롤 감각을 한 가지로 맞춘다.
///
/// Android 는 끝에 닿으면 광택이 번지며 딱 멈추고 iOS 는 튕겨 나온다.
/// 같은 앱인데 기기마다 스크롤이 다르게 느껴지는 것이라, 어느 쪽이든 튕기는
/// 쪽으로 통일한다. 화면에서 물리를 따로 지정한 곳은 그 값이 우선이므로
/// 여기 설정은 지정하지 않은 곳에만 걸린다.
///
/// `MaterialApp(scrollBehavior: const AppScrollBehavior())` 로 넘긴다.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  /// 끝에 닿을 때 번지는 광택을 없앤다. 튕기는 동작과 함께 나오면 지저분하다.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
