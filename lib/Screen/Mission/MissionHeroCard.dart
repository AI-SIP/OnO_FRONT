import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppRewardColors.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/AnimatedGauge.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Text/StandardText.dart';
import '../User/Widget/FrogCharacter.dart';
import 'MissionRewardChip.dart';

/// 오늘 받은 XP 를 센다.
///
/// 화면이 프로바이더에서 바로 계산한다. 서버가 따로 내려주는 값이 아니고,
/// 보여 주기 위한 합계라 계약을 늘리지 않는다.
int todayEarnedXp(List<MissionModel> dailyMissions) {
  var sum = 0;
  for (final mission in dailyMissions) {
    if (mission.claimed && mission.rewardType == MissionRewardType.xp) {
      sum += mission.rewardValue;
    }
  }
  return sum;
}

/// 미션 화면 맨 위의 히어로다.
///
/// 개구리가 오늘의 진행을 링으로 두르고 있고, 오른쪽에 오늘 받은 XP 가 있다.
/// 보상을 받으면 코인이 이 카운터로 날아와 숫자가 롤업된다. 미션 화면에
/// 마스코트가 없으면 이 앱의 화면으로 보이지 않는다.
class MissionHeroCard extends StatefulWidget {
  final List<MissionModel> dailyMissions;

  /// 마이페이지와 같은 레벨의 개구리를 띄운다.
  final int level;

  final Color primaryColor;

  /// 코인이 날아와 닿을 자리. XP 카운터에 달린다.
  final GlobalKey? counterKey;

  /// 지금 날아오는 중인 XP. 코인이 닿기 전까지는 합계에서 빼 둔다.
  ///
  /// 이게 없으면 코인이 아직 공중에 있는데 숫자가 먼저 올라가 버린다. 그러면
  /// 코인이 무엇을 옮기는 중인지가 사라진다.
  final int pendingXp;

  /// 코인이 닿을 때마다 1 씩 는다. 칩이 한 번 튀는 신호다.
  final int arrivalTick;

  /// XP 칩을 눌렀을 때. 지금까지 받은 보상을 보여 주는 화면으로 간다.
  final VoidCallback? onCounterTap;

  const MissionHeroCard({
    super.key,
    required this.dailyMissions,
    required this.level,
    required this.primaryColor,
    this.counterKey,
    this.pendingXp = 0,
    this.arrivalTick = 0,
    this.onCounterTap,
  });

  @override
  State<MissionHeroCard> createState() => _MissionHeroCardState();
}

class _MissionHeroCardState extends State<MissionHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  int get _total => widget.dailyMissions.length;

  int get _completed => widget.dailyMissions.where((m) => m.completed).length;

  int get _claimable => widget.dailyMissions.where((m) => m.isClaimable).length;

  bool get _allDone => _total > 0 && _completed == _total;

  /// 기기에서 애니메이션을 껐는지.
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = AppMotion.isReduced(context);
    _syncBob();
  }

  @override
  void didUpdateWidget(covariant MissionHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBob();
  }

  /// 받을 게 있으면 들썩이고, 오늘 것을 다 하면 기뻐한다. 둘 다 아니면 가만히
  /// 있는다. 늘 움직이면 아무 뜻도 없는 움직임이 된다.
  void _syncBob() {
    final shouldMove = !_reduced && (_claimable > 0 || _allDone);
    if (shouldMove && !_bob.isAnimating) {
      _bob.repeat(reverse: true);
    } else if (!shouldMove && _bob.isAnimating) {
      _bob.stop();
      _bob.value = 0;
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _total > 0 ? _completed / _total : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 폰과 태블릿에서 같은 비율로 보이게 폭에 맞춰 잡는다.
        final gaugeSize = math.min(
          math.max(constraints.maxWidth * 0.32, 92.0),
          132.0,
        );

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xlarge),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildFrogRing(gaugeSize, ratio),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildSummary()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrogRing(double size, double ratio) {
    final frog = FrogCharacter(level: widget.level, size: size * 0.62);

    return AnimatedCircularGauge(
      value: ratio,
      color: widget.primaryColor,
      backgroundColor: AppColors.surfaceMuted,
      size: size,
      strokeWidth: size * 0.075,
      child: _reduced
          ? frog
          : AnimatedBuilder(
              animation: _bob,
              builder: (context, child) => Transform.translate(
                // 다 받은 뒤에는 조금 더 크게 움직인다.
                offset: Offset(0, -(_allDone ? 5 : 3) * _bob.value),
                child: child,
              ),
              child: frog,
            ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        StandardText(
          text: _headline,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedCountText(
              value: _completed,
              fontSize: 28,
              color: widget.primaryColor,
            ),
            StandardText(
              text: ' / $_total',
              fontSize: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildXpCounter(),
      ],
    );
  }

  String get _headline {
    if (_total == 0) return '오늘의 미션';
    if (_claimable > 0) return '받을 보상이 있어요';
    if (_allDone) return '오늘 것을 다 했어요';
    return '오늘의 미션';
  }

  /// 오늘 받은 XP. 받을 때마다 여기로 코인이 날아와 숫자가 올라간다.
  Widget _buildXpCounter() {
    final earned = (todayEarnedXp(widget.dailyMissions) - widget.pendingXp)
        .clamp(0, 1 << 30);

    return _ArrivalPop(
      tick: widget.arrivalTick,
      enabled: !_reduced,
      child: PressableScale(
        onTap: widget.onCounterTap,
        haptic: HapticLevel.secondary,
        child: Container(
          key: widget.counterKey,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppRewardColors.coinSurface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppRewardColors.coin.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MissionCoin(size: 18),
              const SizedBox(width: AppSpacing.sm),
              const StandardText(
                text: '오늘',
                fontSize: 12,
                color: AppRewardColors.onCoin,
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedCountText(
                value: earned,
                formatter: (value) => '+${value.round()} XP',
                fontSize: 14,
                color: AppRewardColors.onCoin,
              ),
              // 누를 수 있다는 것이 보여야 한다.
              if (widget.onCounterTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppRewardColors.onCoin,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// [tick] 이 바뀔 때마다 한 번 커졌다 돌아온다.
///
/// 코인이 칩에 닿는 순간에 쓴다. [SelectionPop] 은 켜질 때 한 번만 튀는
/// 것이라 여러 번 반복되는 이 자리에는 맞지 않는다.
class _ArrivalPop extends StatefulWidget {
  final int tick;
  final bool enabled;
  final Widget child;

  const _ArrivalPop({
    required this.tick,
    required this.enabled,
    required this.child,
  });

  @override
  State<_ArrivalPop> createState() => _ArrivalPopState();
}

class _ArrivalPopState extends State<_ArrivalPop>
    with SingleTickerProviderStateMixin {
  // 늦게 만들지 않는다. 연출을 끈 기기에서는 build 가 컨트롤러를 건드리지
  // 않는데, 그 상태로 dispose 가 컨트롤러를 만들면 이미 빠진 위젯의 조상을
  // 찾다가 죽는다.
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.normal);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: AppMotion.enter)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: AppMotion.emphasized)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _ArrivalPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tick != oldWidget.tick && widget.enabled) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
