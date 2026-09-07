import 'package:flutter/material.dart';

import 'AppMotion.dart';

/// 앱의 바텀시트를 띄우는 공용 함수다.
///
/// 지금은 화면마다 `showModalBottomSheet` 를 직접 부르면서 모서리 둥글기와
/// 드래그 여부, 배경색을 각자 다르게 주고 있다. 이것을 쓰면 손잡이와 모서리,
/// 올라오는 속도가 어디서나 같아진다.
///
/// ```dart
/// final picked = await showTossSheet<String>(
///   context: context,
///   builder: (context) => const TagPickerSheet(),
/// );
/// ```
///
/// [isScrollControlled] 는 기본이 true 다. 내용이 화면 절반을 넘거나 안에
/// 입력칸이 있으면 false 로 두면 잘리기 때문이다. 대신 내용이 짧아도 시트가
/// 화면 전체를 덮지 않도록 자식 쪽에서 높이를 정해야 한다.
Future<T?> showTossSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,

  /// 위쪽 가운데의 회색 손잡이. 드래그로 닫을 수 없는 시트에서는 끈다.
  bool showHandle = true,

  /// 바깥을 눌러서 닫을 수 있는지.
  bool isDismissible = true,

  /// 아래로 끌어서 닫을 수 있는지.
  bool enableDrag = true,
  bool isScrollControlled = true,

  /// 화면 위에 또 다른 Navigator 가 있을 때 가장 바깥 것에 띄운다.
  bool useRootNavigator = false,
  Color? backgroundColor,
  double borderRadius = 24.0,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: true,
    backgroundColor: backgroundColor ?? Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
    ),
    sheetAnimationStyle: const AnimationStyle(
      duration: AppMotion.sheet,
      curve: AppMotion.enter,
      reverseDuration: AppMotion.normal,
      reverseCurve: AppMotion.exit,
    ),
    builder: (sheetContext) {
      final content = builder(sheetContext);
      if (!showHandle) return content;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TossSheetHandle(),
          Flexible(child: content),
        ],
      );
    },
  );
}

/// 바텀시트 위쪽 가운데에 놓이는 손잡이다.
///
/// [showTossSheet] 이 알아서 붙이므로 화면에서 직접 쓸 일은 없다.
/// `showModalBottomSheet` 를 아직 직접 부르는 곳에서만 가져다 쓴다.
class TossSheetHandle extends StatelessWidget {
  const TossSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
