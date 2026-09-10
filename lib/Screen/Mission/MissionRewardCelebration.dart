import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'MissionRewardChip.dart';

/// 보상 카드를 화면에서 찾는 키. 테스트가 이 순간이 떴는지 확인하는 데 쓴다.
const Key missionRewardCelebrationKey = Key('mission_reward_celebration');

/// 보상을 받은 순간을 보여 주고, 코인이 있던 자리를 돌려준다.
///
/// 돌려준 자리에서 코인이 상단 카운터로 날아간다. 그래야 "여기 있던 것이
/// 저기로 갔다"가 눈에 이어진다. 화면에서 코인을 찾지 못하면 null 이다.
///
/// **레벨업 여부와 상관없이 받을 때마다 이 순간이 있어야 한다.** 카드가 조용히
/// `받음` 으로 바뀌기만 하면 그건 보상이 아니라 알림이다.
Future<Offset?> showMissionRewardCelebration(
  BuildContext context, {
  required String missionTitle,
  required MissionRewardType? rewardType,
  required int amount,
}) {
  return showGeneralDialog<Offset?>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '보상',
    // 검정 스크림을 쓰지 않는다. 축하는 어둡게 해서가 아니라 빛으로 낸다.
    barrierColor: Colors.white.withValues(alpha: 0.82),
    transitionDuration: AppMotion.normal,
    pageBuilder: (context, animation, secondaryAnimation) =>
        _MissionRewardCelebration(
      missionTitle: missionTitle,
      rewardType: rewardType,
      amount: amount,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
        child: child,
      );
    },
  );
}

class _MissionRewardCelebration extends StatefulWidget {
  final String missionTitle;
  final MissionRewardType? rewardType;
  final int amount;

  const _MissionRewardCelebration({
    required this.missionTitle,
    required this.rewardType,
    required this.amount,
  });

  @override
  State<_MissionRewardCelebration> createState() =>
      _MissionRewardCelebrationState();
}

class _MissionRewardCelebrationState extends State<_MissionRewardCelebration>
    with SingleTickerProviderStateMixin {
  /// 화면 가운데로 튀어오르는 것.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  /// 코인의 자리를 재는 데 쓴다. 닫을 때 이 자리를 돌려준다.
  final GlobalKey _coinKey = GlobalKey();

  /// 스스로 닫히는 시간. 기다리게 하지 않는다.
  static const Duration _autoDismiss = Duration(milliseconds: 1100);

  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _enter.forward();
    _timer = Timer(_autoDismiss, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enter.dispose();
    super.dispose();
  }

  /// 코인이 지금 화면 어디에 있는지 재서 들고 나간다.
  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();

    final box = _coinKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(box.size.center(Offset.zero))
        : null;
    Navigator.of(context).pop(origin);
  }

  String get _amountLabel =>
      widget.rewardType == MissionRewardType.xp ? '+${widget.amount} XP' : '보상';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final reduced = AppMotion.isReduced(context);

    return Material(
      type: MaterialType.transparency,
      // 어디를 눌러도 바로 넘어간다. 연출이 길을 막으면 안 된다.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _buildCard(themeProvider.primaryColor, reduced),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Color primary, bool reduced) {
    final card = Container(
      key: missionRewardCelebrationKey,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCoin(primary, reduced),
          const SizedBox(height: AppSpacing.lg),
          // 이게 주인공이다. 가장 크게 둔다.
          StandardText(
            text: _amountLabel,
            fontSize: 34,
            color: primary,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: AppSpacing.xs),
          StandardText(
            text: widget.missionTitle,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (reduced) return card;

    // 스프링처럼 살짝 넘겼다 제자리로 온다.
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _enter,
          curve: AppMotion.emphasized,
        ).value;
        return Transform.scale(scale: 0.7 + 0.3 * t, child: child);
      },
      child: card,
    );
  }

  /// 큰 금색 코인. 뒤로 테마색 빛이 퍼지고 둘레에 조각이 튄다.
  Widget _buildCoin(Color primary, bool reduced) {
    const size = 96.0;

    return SizedBox.square(
      dimension: size * 1.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 뒤에서 퍼지는 빛. 밝은 바탕이라 검정 없이도 코인이 도드라진다.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primary.withValues(alpha: 0.22),
                  primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          if (!reduced)
            AnimatedBuilder(
              animation: _enter,
              builder: (context, _) => CustomPaint(
                size: const Size.square(size * 1.6),
                painter: _SparklePainter(
                  progress: _enter.value,
                  color: primary,
                ),
              ),
            ),
          KeyedSubtree(
            key: _coinKey,
            child: MissionRewardToken(size: size, color: primary),
          ),
        ],
      ),
    );
  }
}

/// 코인 둘레로 짧게 튀는 조각들이다.
class _SparklePainter extends CustomPainter {
  /// 0 에서 1. 퍼져 나간 정도.
  final double progress;
  final Color color;

  const _SparklePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    // 끝에서 옅어지며 사라진다.
    final fade = (1 - progress).clamp(0.0, 1.0);

    const count = 10;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * math.pi / count;
      final distance = maxRadius * (0.55 + 0.45 * progress);
      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      final paint = Paint()
        ..color = color.withValues(alpha: (i.isEven ? 0.9 : 0.5) * fade);
      canvas.drawCircle(offset, 3.5 * fade + 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
