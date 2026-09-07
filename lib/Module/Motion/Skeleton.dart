import 'package:flutter/material.dart';

/// 내용을 불러오는 동안 그 자리에 놓는 회색 덩어리다.
///
/// 화면 가운데에서 도는 스피너는 무엇을 기다리는지 알려주지 않고, 다 불러온
/// 순간 화면이 통째로 바뀌어서 덜컥거린다. 실제 배치와 같은 모양의 회색
/// 덩어리를 먼저 보여주면 그 자리에 무엇이 올지 미리 보이고 교체도 덜 튄다.
///
/// ```dart
/// isLoading
///     ? const SkeletonBox(height: 20, width: 120)
///     : StandardText(text: problem.title)
/// ```
///
/// 빛이 흐르는 효과는 끝나지 않는 애니메이션이라 위젯 테스트에서
/// `pumpAndSettle` 이 타임아웃난다. 로딩 상태를 검증하는 테스트에서는
/// `pumpOnoWidget(..., settle: false)` 를 쓰거나 [animate] 를 false 로 둔다.
class SkeletonBox extends StatefulWidget {
  /// 넘기지 않으면 부모가 주는 너비를 다 쓴다.
  final double? width;

  final double height;
  final double borderRadius;

  /// 바탕색. 기본은 회색 200.
  final Color? baseColor;

  /// 흐르는 빛의 색. 기본은 회색 100.
  final Color? highlightColor;

  /// false 면 흐르는 효과 없이 회색으로만 둔다.
  final bool animate;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
    this.animate = true,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  // late final 로 미뤄 두면 animate 가 false 일 때 한 번도 만들어지지 않고,
  // dispose 에서 그제야 생기면서 이미 떨어져 나간 위젯의 TickerMode 를 찾다가
  // 터진다. initState 에서 반드시 만든다.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(SkeletonBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? Colors.grey[200]!;
    final highlight = widget.highlightColor ?? Colors.grey[100]!;
    final radius = BorderRadius.circular(widget.borderRadius);

    if (!widget.animate) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: base, borderRadius: radius),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // 빛이 왼쪽 바깥에서 오른쪽 바깥으로 한 번 지나간다.
        final shift = _controller.value * 3 - 1.5;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(shift - 0.5, 0),
              end: Alignment(shift + 0.5, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 목록을 불러오는 동안 놓는 여러 줄짜리 덩어리다.
///
/// 실제 항목과 높이를 맞춰야 다 불러왔을 때 화면이 덜 움직인다.
class SkeletonList extends StatelessWidget {
  /// 몇 줄을 놓을지.
  final int itemCount;

  /// 한 줄의 높이. 실제 항목 높이에 맞춘다.
  final double itemHeight;

  /// 줄 사이 간격.
  final double spacing;

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool animate;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72.0,
    this.spacing = 12.0,
    this.borderRadius = 12.0,
    this.padding = EdgeInsets.zero,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            SkeletonBox(
              height: itemHeight,
              borderRadius: borderRadius,
              animate: animate,
            ),
          ],
        ],
      ),
    );
  }
}
