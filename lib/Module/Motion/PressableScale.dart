import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'AppHaptic.dart';
import 'AppMotion.dart';

/// 누르면 살짝 줄어들었다가 돌아오는 래퍼다.
///
/// Material 의 물결 효과(ripple) 대신 축소로 눌림을 표현한다. 기존 화면에서
/// `GestureDetector` 와 `InkWell` 이 하던 자리를 이것으로 바꾼다.
///
/// ```dart
/// PressableScale(
///   onTap: () => Navigator.push(context, TossPageRoute(builder: (_) => const NextScreen())),
///   child: const ProblemCard(),
/// )
/// ```
///
/// 눌림 상태를 [Listener] 로 직접 관리하는 이유가 있다. `GestureDetector` 의
/// `onTapDown` 은 제스처 경쟁에서 이겨야 불리는데, 스크롤되는 목록 안에서는
/// 그 판정이 늦어서 축소가 한 박자 밀린다. 게다가 경쟁에서 지면 `onTapDown`
/// 을 보낸 적이 없다는 이유로 `onTapCancel` 도 오지 않아서, 스크롤을 시작하면
/// 항목이 줄어든 채로 남는다. 그래서 손가락이 [kTouchSlop] 이상 움직이면
/// 스스로 눌림을 푼다.
class PressableScale extends StatefulWidget {
  /// 누를 대상.
  final Widget child;

  /// 탭했을 때 부를 것. null 이면 축소도 하지 않는다.
  final VoidCallback? onTap;

  /// 길게 눌렀을 때 부를 것.
  final VoidCallback? onLongPress;

  /// 눌렸을 때의 크기 비율. 기본값은 [AppMotion.pressedScale].
  ///
  /// 작은 아이콘 버튼은 0.97 이면 변화가 잘 안 보여서 조금 더 줄이는 게 낫다.
  final double scale;

  /// 탭 순간 줄 진동. 기본값은 [HapticLevel.secondary].
  ///
  /// 목록 항목처럼 연달아 누르게 되는 곳은 [HapticLevel.none] 으로 끈다.
  final HapticLevel haptic;

  /// false 면 축소도 진동도 콜백도 없다. 비활성 버튼에 쓴다.
  final bool enabled;

  /// 자식이 투명한 영역을 포함할 때 그 부분도 누르게 하려면
  /// [HitTestBehavior.opaque] 를 쓴다.
  final HitTestBehavior behavior;

  /// 시맨틱 트리에 버튼으로 알릴지 여부. 카드 전체를 감쌀 때는 false 로 둔다.
  final bool semanticButton;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = AppMotion.pressedScale,
    this.haptic = HapticLevel.secondary,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
    this.semanticButton = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  /// 손가락이 처음 닿은 자리. 여기서 얼마나 벗어났는지로 취소를 판단한다.
  Offset? _downPosition;

  /// 이번 터치에서 이미 취소된 경우 다시 축소하지 않는다.
  bool _canceled = false;

  /// 누를 것이 실제로 있을 때만 반응한다.
  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _setPressed(bool value) {
    if (value && !_interactive) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _downPosition = event.position;
    _canceled = false;
    _setPressed(true);
  }

  /// 스크롤이나 드래그로 넘어갔다고 볼 만큼 움직였으면 눌림을 푼다.
  void _handlePointerMove(PointerMoveEvent event) {
    if (_canceled || _downPosition == null) return;
    if ((event.position - _downPosition!).distance <= kTouchSlop) return;

    _canceled = true;
    _setPressed(false);
  }

  void _handlePointerRelease() {
    _downPosition = null;
    _canceled = false;
    _setPressed(false);
  }

  void _handleTap() {
    if (!_interactive || widget.onTap == null) return;
    AppHaptic.of(widget.haptic);
    widget.onTap!();
  }

  void _handleLongPress() {
    if (!_interactive || widget.onLongPress == null) return;
    AppHaptic.primary();
    widget.onLongPress!();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    final scaled = AnimatedScale(
      scale: _pressed && !reduced ? widget.scale : 1.0,
      duration: AppMotion.press,
      curve: AppMotion.standard,
      child: widget.child,
    );

    return Semantics(
      button: widget.semanticButton && widget.onTap != null,
      enabled: widget.enabled,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: (_) => _handlePointerRelease(),
        onPointerCancel: (_) => _handlePointerRelease(),
        behavior: widget.behavior,
        child: GestureDetector(
          behavior: widget.behavior,
          onTapCancel: _handlePointerRelease,
          onTap: widget.onTap == null ? null : _handleTap,
          onLongPress: widget.onLongPress == null ? null : _handleLongPress,
          child: scaled,
        ),
      ),
    );
  }
}
