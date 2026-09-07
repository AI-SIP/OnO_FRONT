import 'dart:async';

import 'package:flutter/material.dart';

import '../../Util/AppNavigator.dart';
import '../Motion/AppMotion.dart';
import '../Motion/SelectionPop.dart';
import '../Text/StandardText.dart';
import 'AppColors.dart';
import 'AppRadius.dart';
import 'AppSpacing.dart';

/// 알림의 성격. 색과 아이콘이 이걸 따라간다.
enum ToastType { success, error, info }

/// 화면 위쪽에서 내려오는 알림이다.
///
/// 그동안 `SnackBar` 를 써서 아래에서 올라왔다. 하단 버튼이나 탭 바를 가리고,
/// 배경을 빨강이나 초록으로 가득 칠해서 화면에서 튀었다.
///
/// 이것은 위에서 내려와 흰 바탕에 테두리만 색으로 구분한다. 왼쪽 아이콘으로
/// 성공인지 실패인지 알리고, 손으로 위로 밀거나 두드리면 바로 닫힌다.
///
/// `SnackBar` 대신 `Overlay` 를 쓰는 이유는 `SnackBar` 가 화면 아래에
/// 붙도록 만들어져 있어서 위로 올릴 수 없기 때문이다.
class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  /// 같은 문구가 연달아 뜨는 것을 막는다.
  static DateTime? _lastShownAt;
  static String? _lastMessage;

  static void success(String message) =>
      show(message: message, type: ToastType.success);

  static void error(String message) =>
      show(message: message, type: ToastType.error);

  static void info(String message) =>
      show(message: message, type: ToastType.info);

  /// [context] 를 주면 그 화면의 Overlay 를, 주지 않으면 앱 전체의 것을 쓴다.
  static void show({
    required String message,
    ToastType type = ToastType.info,
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (message.trim().isEmpty) return;

    final now = DateTime.now();
    if (_lastMessage == message &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastMessage = message;
    _lastShownAt = now;

    // context 로 먼저 찾되, 못 찾으면 앱 전체의 Overlay 로 되돌아간다.
    // 삭제처럼 화면을 닫으면서 알리는 경우 context 가 이미 죽어 있어서,
    // context 만 믿으면 알림이 아무것도 뜨지 않는다.
    final overlay = (context != null
            ? Overlay.maybeOf(context, rootOverlay: true)
            : null) ??
        AppNavigator.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    dismiss();

    final entry = OverlayEntry(
      builder: (context) => _ToastView(
        message: message,
        type: type,
        duration: duration,
        onDismiss: dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// 지금 떠 있는 알림을 닫는다.
  ///
  /// 이미 닫혀 있으면 아무 일도 하지 않는다. 자동으로 닫히는 것과 손으로
  /// 닫는 것이 겹칠 수 있어서 두 번 불려도 안전해야 한다.
  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    entry?.remove();
  }
}

class _ToastView extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastView({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  );

  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // 타이머를 위젯이 들고 있어야 화면이 사라질 때 함께 정리된다.
    // AppToast 가 들고 있으면 트리가 없어진 뒤에도 타이머가 남는다.
    _autoDismiss = Timer(widget.duration, widget.onDismiss);
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  ({Color accent, IconData icon}) get _style {
    switch (widget.type) {
      case ToastType.success:
        return (accent: const Color(0xFF2FA97C), icon: Icons.check_circle);
      case ToastType.error:
        return (accent: const Color(0xFFE5504D), icon: Icons.error);
      case ToastType.info:
        return (accent: const Color(0xFF4A90D9), icon: Icons.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final topInset = MediaQuery.of(context).padding.top;

    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enter,
    );

    return Positioned(
      // 상태바 바로 아래에 두면 앱바와 겹쳐 묻힌다. 앱바 높이만큼 내려서
      // 화면 내용 위에 또렷하게 얹힌다.
      top: topInset + kToolbarHeight + AppSpacing.sm,
      left: AppSpacing.screenHorizontal,
      right: AppSpacing.screenHorizontal,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.6),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: ValueKey(widget.message),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    // 배경을 가득 칠하는 대신 테두리로만 성격을 알린다.
                    border: Border.all(
                      color: style.accent.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 아이콘이 한 박자 늦게 튀어오르면 방금 끝난 일이라는
                      // 것이 눈에 들어온다.
                      SelectionPop(
                        selected: true,
                        peak: 1.35,
                        child: Icon(style.icon, size: 20, color: style.accent),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StandardText(
                          text: widget.message,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
