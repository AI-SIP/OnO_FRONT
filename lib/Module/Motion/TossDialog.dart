import 'package:flutter/material.dart';

import 'AppMotion.dart';

/// 앱의 다이얼로그를 띄우는 공용 함수다.
///
/// `showDialog` 는 기본적으로 아주 짧게 흐려지며 나타나서, 눌렀을 때 화면이
/// 툭 바뀌는 느낌을 준다. 이것을 쓰면 조금 작은 상태에서 제 크기로 커지며
/// 올라와 어디서 나온 것인지가 보인다.
///
/// ```dart
/// final ok = await showTossDialog<bool>(
///   context: context,
///   builder: (context) => ConfirmDialog(...),
/// );
/// ```
///
/// 내용과 모양은 그대로 두고 등장하는 방식만 맞추는 것이라, 기존
/// `showDialog` 자리를 이름만 바꿔 끼우면 된다.
Future<T?> showTossDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black54,
    useRootNavigator: useRootNavigator,
    transitionDuration: AppMotion.normal,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
      );

      return FadeTransition(
        opacity: curved,
        child: Transform.scale(
          // 0.94 에서 제 크기로 커진다. 더 작게 시작하면 튀어나오는 것처럼
          // 보이고, 더 크면 변화가 눈에 안 들어온다.
          scale: 0.94 + 0.06 * curved.value,
          child: child,
        ),
      );
    },
  );
}
