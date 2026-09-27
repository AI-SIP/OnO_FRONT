import 'package:flutter/material.dart';

import '../Constants/ErrorMessages.dart';
import '../Module/Design/AppToast.dart';
import 'ErrorMessageMapper.dart';

/// 앱 어디서나 부를 수 있는 오류 알림이다.
///
/// 예전에는 화면 아래에서 올라오는 빨간 SnackBar 였다. 하단 버튼을 가리고
/// 배경을 가득 칠해서 화면에서 튀었다. 지금은 위에서 내려오는 [AppToast] 를
/// 쓴다. 부르는 쪽 코드는 그대로 두고 안쪽만 바꿨다.
class AppSnackBar {
  /// MaterialApp 이 아직 이 키를 쓰고 있어서 남겨 둔다.
  /// 토스트는 Overlay 를 쓰므로 이 키에 기대지 않는다.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showError(String message) {
    if (message.trim().isEmpty) return;

    final safeMessage = ErrorMessageMapper.sanitizeRawMessage(
      message,
      fallback: ErrorMessages.unknown,
      allowRawMessage: true,
    );
    AppToast.error(safeMessage);
  }
}
