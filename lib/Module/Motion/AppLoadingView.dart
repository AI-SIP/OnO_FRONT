import 'package:flutter/material.dart';

import '../Text/StandardText.dart';
import 'AnimatedGauge.dart';
import 'AppMotion.dart';
import '../Design/AppRadius.dart';
import '../Design/AppColors.dart';

/// 기다리는 동안 보여 주는 화면을 한 가지로 맞춘 것이다.
///
/// 그동안 로딩이 세 갈래로 갈라져 있었다. 전체 화면 로딩은 투명한 배경에
/// 손글씨체 흰 글씨였고, 오답노트 여러 장 등록은 흰 카드에 진행 막대였고,
/// 나머지는 회색 기본 동그라미였다. 같은 앱인데 기다릴 때마다 다른 화면이
/// 나오던 것을 하나로 모은다.
///
/// [progress] 를 주면 얼마나 남았는지 보이는 게이지가 되고, 주지 않으면
/// 도는 동그라미가 된다. 몇 개 중 몇 개인지 같은 것은 [detail] 에 적는다.
///
/// ```dart
/// // 얼마나 걸릴지 모를 때
/// const AppLoadingView(message: '불러오는 중이에요')
///
/// // 진행 정도를 알 때
/// AppLoadingView(
///   message: '이미지를 등록하고 있어요',
///   detail: '$done / $total',
///   progress: done / total,
/// )
/// ```
class AppLoadingView extends StatelessWidget {
  /// 무엇을 기다리는지 알려 주는 한 줄.
  final String message;

  /// 진행 정도를 숫자로 덧붙일 때 쓴다.
  final String? detail;

  /// 0 에서 1 사이. 넘기지 않으면 도는 동그라미가 된다.
  final double? progress;

  /// 강조색. 넘기지 않으면 테마의 기본 색을 쓴다.
  final Color? color;

  const AppLoadingView({
    super.key,
    required this.message,
    this.detail,
    this.progress,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progress == null)
          _PulsingDots(color: accent)
        else
          SizedBox(
            width: 180,
            child: AnimatedLinearGauge(
              value: progress!,
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.12),
              height: 6,
              borderRadius: 3,
              // 올라간 만큼만 따라가면 되므로 짧게 움직인다.
              duration: AppMotion.normal,
              curve: AppMotion.standard,
            ),
          ),
        const SizedBox(height: 18),
        StandardText(
          text: message,
          fontSize: 15,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          textAlign: TextAlign.center,
        ),
        if (detail != null) ...[
          const SizedBox(height: 6),
          StandardText(
            text: detail!,
            fontSize: 13,
            color: Colors.grey[600]!,
            fontWeight: FontWeight.normal,
            fontFamily: 'PretendardLight',
          ),
        ],
      ],
    );
  }
}

/// [AppLoadingView] 를 화면 가운데 흰 카드로 띄운다.
///
/// 다이얼로그 안에 넣을 때 쓴다. 카드 모양과 여백을 여기서 맞춰 두어
/// 부르는 쪽마다 다르게 그리지 않게 한다.
class AppLoadingCard extends StatelessWidget {
  final String message;
  final String? detail;
  final double? progress;
  final Color? color;

  const AppLoadingCard({
    super.key,
    required this.message,
    this.detail,
    this.progress,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xlarge),
        ),
        child: AppLoadingView(
          message: message,
          detail: detail,
          progress: progress,
          color: color,
        ),
      ),
    );
  }
}

/// 점 세 개가 차례로 부풀었다 가라앉는다.
///
/// 도는 동그라미는 어느 앱에나 있어서 눈에 남지 않고, 캐릭터를 크게 넣으면
/// 기다리는 것보다 그림이 먼저 보인다. 점 세 개는 자리를 적게 쓰면서
/// 무언가 진행 중이라는 것만 조용히 알린다.
class _PulsingDots extends StatefulWidget {
  final Color color;

  const _PulsingDots({required this.color});

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  static const int _dotCount = 3;
  static const double _dotSize = 9.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_dotCount, (index) {
            // 점마다 시작을 어긋나게 해서 물결처럼 이어지게 한다.
            final shifted = (_controller.value - index * 0.18) % 1.0;
            // 앞쪽 절반 동안 부풀었다가 나머지 절반 동안 가라앉는다.
            final wave = shifted < 0.5
                ? Curves.easeOut.transform(shifted * 2)
                : Curves.easeIn.transform((1 - shifted) * 2);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: _dotSize,
                height: _dotSize,
                transform: Matrix4.diagonal3Values(
                  0.7 + 0.5 * wave,
                  0.7 + 0.5 * wave,
                  1.0,
                ),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.35 + 0.65 * wave),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
