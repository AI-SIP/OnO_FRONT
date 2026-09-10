import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Motion/AppMotion.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'MissionRewardChip.dart';

/// 받은 보상 코인이 상단 카운터로 날아가는 연출이다.
///
/// 예전에는 받으면 화면 위에서 `+10 XP` 알림이 내려왔는데, 그게 일일/주간 탭
/// 바를 정확히 덮었다. 알림을 옮겨 피하는 대신 **연출을 화면 안에서 끝낸다.**
/// 코인이 카드에서 카운터로 날아가 합쳐지고, 카운터 숫자가 롤업된다. 덮을
/// 것이 없으니 겹침 문제도 같이 사라진다.
abstract final class MissionRewardFlight {
  /// [from] 에서 [to] 로 코인을 날린다. 실제로 날렸으면 true 다.
  ///
  /// 둘 중 하나라도 화면에 없으면(스크롤 밖이거나 이미 사라졌으면) 아무것도
  /// 하지 않고 false 를 돌려준다. 부르는 쪽은 그때 숫자를 바로 올려야 한다.
  /// 연출은 없어도 되는 것이지만, 숫자가 영영 안 오르면 안 된다.
  static bool launch({
    required BuildContext context,
    required GlobalKey from,
    required GlobalKey to,
    Color? color,
    VoidCallback? onArrived,
  }) {
    if (AppMotion.isReduced(context)) return false;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final fromBox = from.currentContext?.findRenderObject() as RenderBox?;
    final toBox = to.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || fromBox == null || toBox == null) return false;
    if (!fromBox.hasSize || !toBox.hasSize) return false;

    final start = fromBox.localToGlobal(fromBox.size.center(Offset.zero));
    return launchFrom(
      context: context,
      start: start,
      to: to,
      color: color,
      onArrived: onArrived,
    );
  }

  /// 화면의 [start] 자리에서 [to] 로 코인을 날린다.
  ///
  /// 보상 카드가 닫히면서 코인이 있던 자리를 알려 줄 때 쓴다. 그 코인은 이미
  /// 사라진 뒤라 [GlobalKey] 로는 잡을 수 없다.
  static bool launchFrom({
    required BuildContext context,
    required Offset start,
    required GlobalKey to,
    Color? color,
    VoidCallback? onArrived,
  }) {
    if (AppMotion.isReduced(context)) return false;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final toBox = to.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || toBox == null || !toBox.hasSize) return false;

    final end = toBox.localToGlobal(toBox.size.center(Offset.zero));

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingCoin(
        start: start,
        end: end,
        color: color ??
            Provider.of<ThemeHandler>(context, listen: false).primaryColor,
        onCompleted: () {
          onArrived?.call();
          // 그리는 도중에 걷어내면 안 되므로 프레임이 끝난 뒤에 지운다.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (entry.mounted) entry.remove();
          });
        },
      ),
    );
    overlay.insert(entry);
    return true;
  }
}

class _FlyingCoin extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Color color;
  final VoidCallback onCompleted;

  const _FlyingCoin({
    required this.start,
    required this.end,
    required this.color,
    required this.onCompleted,
  });

  @override
  State<_FlyingCoin> createState() => _FlyingCoinState();
}

class _FlyingCoinState extends State<_FlyingCoin>
    with SingleTickerProviderStateMixin {
  static const double _coinSize = 26;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  /// 빌더 안에서 만들면 프레임마다 새로 생기고 리스너가 쌓인다.
  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.emphasized,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 직선으로 가면 날아가는 느낌이 없다. 위로 한 번 솟았다가 카운터로 떨어진다.
  Offset _positionAt(double t) {
    final control = Offset(
      (widget.start.dx + widget.end.dx) / 2,
      math.min(widget.start.dy, widget.end.dy) - 80,
    );
    final inverse = 1 - t;
    return widget.start * (inverse * inverse) +
        control * (2 * inverse * t) +
        widget.end * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        final t = _curved.value;
        final position = _positionAt(t);
        // 카운터에 가까워질수록 작아지며 합쳐진다.
        final scale = 1.0 - 0.45 * t;

        return Positioned(
          left: position.dx - _coinSize / 2,
          top: position.dy - _coinSize / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: t > 0.85 ? (1 - t) / 0.15 : 1,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
      child: MissionRewardToken(size: _coinSize, color: widget.color),
    );
  }
}
