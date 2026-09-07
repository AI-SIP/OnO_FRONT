import 'package:flutter/material.dart';

import '../../Constants/ErrorMessages.dart';
import '../../Util/ErrorMessageMapper.dart';
import '../Design/AppToast.dart';

/// 화면에서 결과를 알릴 때 쓴다.
///
/// 부르는 쪽이 넘기던 [backgroundColor] 는 이제 배경을 칠하는 데 쓰지 않고,
/// 성공인지 실패인지 가르는 데만 쓴다. 흰 바탕에 테두리와 아이콘으로 구분한다.
/// 호출부 48곳을 고치지 않으려고 인자는 그대로 받는다.
class SnackBarDialog {
  static void showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
  }) {
    final safeMessage = ErrorMessageMapper.sanitizeRawMessage(
      message,
      fallback: ErrorMessages.unknown,
      allowRawMessage: true,
    );

    AppToast.show(
      message: safeMessage,
      type: _typeOf(backgroundColor),
      context: context,
      duration: const Duration(seconds: 2),
    );
  }

  /// 넘어온 색으로 성격을 짐작한다. 빨강 계열이면 오류, 주황이면 주의,
  /// 나머지는 성공으로 본다. 그동안 색을 그렇게 써 왔다.
  static ToastType _typeOf(Color color) {
    if (color == Colors.red || color == Colors.redAccent) {
      return ToastType.error;
    }
    if (color == Colors.orange || color == Colors.orangeAccent) {
      return ToastType.info;
    }
    return ToastType.success;
  }
}
