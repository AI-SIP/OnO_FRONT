import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedGauge.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/SelectionPop.dart';
import '../../Module/Motion/StepProgressBar.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'MissionIcon.dart';
import 'MissionPalette.dart';
import 'MissionPeriodLabel.dart';
import 'MissionRewardChip.dart';
import 'MissionTag.dart';

/// 미션 한 장이 가질 수 있는 세 가지 무게.
///
/// 라벨만 바뀌는 것이 아니라 **카드의 무게 자체가 달라야** 눈이 받을 수 있는
/// 것에 먼저 간다. 게시판이 아니라 게임으로 읽히는 것은 여기서 갈린다.
enum MissionCardState {
  /// 완료했고 아직 안 받음. 테마색을 옅게 깔고 떠 있게 한다.
  claimable,

  /// 진행 중. 흰 카드에 테두리만. 버튼도 두지 않는다.
  inProgress,

  /// 받음. 채도를 빼고 도장만 남긴다.
  claimed;

  static MissionCardState of(MissionModel mission) {
    if (mission.claimed) return MissionCardState.claimed;
    if (mission.isClaimable) return MissionCardState.claimable;
    return MissionCardState.inProgress;
  }
}

/// 미션 한 장이다.
///
/// 아이콘 타일과 진행바 색은 이 미션이 올리는 능력치를 따른다([MissionPalette]).
/// 마이페이지의 활동별 레벨과 같은 색이라, 카드 색만 보고 어떤 경험치가
/// 오르는지 알 수 있다. 받을 수 있는 카드만 테마색을 옅게 깔고 떠오른다.
///
/// 목표가 작으면(5 이하) 진행도를 칸으로 보여 준다. `2/3` 이 점 세 개로 보이면
/// 숫자를 읽지 않아도 알 수 있다. 목표가 크면(복습 30회) 칸이 너무 잘게
/// 쪼개지므로 막대를 쓴다.
class MissionCard extends StatefulWidget {
  final MissionModel mission;

  /// 지금 받기 요청이 나가 있는지. 버튼을 잠근다.
  final bool isClaiming;

  final VoidCallback onClaim;

  /// 어느 기간의 미션인지 함께 보여 줄지. 지난 미션 목록에서만 켠다.
  final bool showPeriod;

  /// 코인이 날아갈 출발점을 잡는 데 쓴다. 보상 칩에 달린다.
  final GlobalKey? rewardKey;

  /// 이 값이 바뀌면 카드가 좌우로 한 번 흔들린다. 받기가 실패했을 때 쓴다.
  final int shakeTick;

  const MissionCard({
    super.key,
    required this.mission,
    required this.isClaiming,
    required this.onClaim,
    this.showPeriod = false,
    this.rewardKey,
    this.shakeTick = 0,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard>
    with TickerProviderStateMixin {
  /// 받을 수 있는 카드가 숨 쉬듯 오르내리는 것.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  /// 받기가 실패했을 때 좌우로 흔드는 것.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  /// 기기에서 애니메이션을 껐는지. [didChangeDependencies] 에서 읽는다.
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = AppMotion.isReduced(context);
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant MissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTick != oldWidget.shakeTick && !_reduced) {
      _shake.forward(from: 0);
    }
    _syncPulse();
  }

  void _syncPulse() {
    final shouldPulse = !_reduced &&
        MissionCardState.of(widget.mission) == MissionCardState.claimable;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = MissionCardState.of(widget.mission);
    final primary = Provider.of<ThemeHandler>(context).primaryColor;
    final colors = MissionPalette.colorsOf(
      code: widget.mission.code,
      iconKey: widget.mission.iconKey,
    );

    Widget card = _buildCard(state, colors, primary);

    if (state == MissionCardState.claimable && !_reduced) {
      // 아주 옅게만 움직인다. 목록이 통째로 들썩이면 읽기가 어려워진다.
      card = AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.012 * _pulse.value,
          child: child,
        ),
        child: card,
      );
    }

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        if (_shake.value == 0) return child!;
        // 잦아들며 멎는다. 계속 같은 폭으로 흔들리면 오류처럼 보인다.
        final decay = 1 - _shake.value;
        final offset = math.sin(_shake.value * math.pi * 6) * 8 * decay;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: card,
    );
  }

  Widget _buildCard(
    MissionCardState state,
    MissionKindColors colors,
    Color primary,
  ) {
    final claimable = state == MissionCardState.claimable;
    final dimmed = state == MissionCardState.claimed;

    final content = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        // 받을 수 있는 것만 테마색을 옅게 깔고 떠오른다.
        color:
            claimable ? MissionPalette.claimableSurface(primary) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: claimable
              ? MissionPalette.claimableBorder(primary)
              : AppColors.border,
          width: claimable ? 1.4 : 1,
        ),
        boxShadow: claimable
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(colors, dimmed),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildBody(colors, dimmed)),
          const SizedBox(width: AppSpacing.md),
          _buildTrailing(state, primary),
        ],
      ),
    );

    // 받는 순간 카드가 한 번 튄다. 손끝에서 일어난 일이 카드에서 확인된다.
    return SelectionPop(
      selected: widget.mission.claimed,
      peak: 1.04,
      child: content,
    );
  }

  Widget _buildIcon(MissionKindColors colors, bool dimmed) {
    final icon = MissionIcon(
      iconKey: widget.mission.iconKey,
      code: widget.mission.code,
      color: colors.accent,
    );

    // 받은 미션은 그림도 한 단계 물린다. 다 한 일이 목록에서 제일 조용해야
    // 아직 할 일이 눈에 들어온다.
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: dimmed ? AppColors.surfaceMuted : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: dimmed ? Opacity(opacity: 0.4, child: icon) : icon,
    );
  }

  Widget _buildBody(MissionKindColors colors, bool dimmed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showPeriod) ...[
          MissionTag(
            text: MissionPeriodLabel.of(widget.mission.periodKey),
            color: colors.accent,
            dimmed: dimmed,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        StandardText(
          text: widget.mission.title,
          fontSize: 15,
          color: dimmed ? AppColors.textTertiary : AppColors.textPrimary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        StandardText(
          text: widget.mission.description,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: dimmed ? AppColors.textDisabled : AppColors.textSecondary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!dimmed) ...[
          _buildProgress(colors),
          const SizedBox(height: AppSpacing.sm),
        ],
        // 어떤 경험치가 오르는지 말로도 알린다. 색만으로는 처음 보는 사람이
        // 알 수 없다.
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            KeyedSubtree(
              key: widget.rewardKey,
              child: MissionRewardChip(
                rewardType: widget.mission.rewardType,
                amount: widget.mission.rewardValue,
                dimmed: dimmed,
              ),
            ),
            if (_abilityLabel.isNotEmpty)
              MissionTag(
                text: _abilityLabel,
                color: colors.accent,
                dimmed: dimmed,
              ),
          ],
        ),
      ],
    );
  }

  String get _abilityLabel => MissionPalette.labelOf(
        code: widget.mission.code,
        iconKey: widget.mission.iconKey,
      );

  /// 목표가 작으면 칸으로, 크면 막대로 보여 준다. 색은 능력치를 따른다.
  Widget _buildProgress(MissionKindColors colors) {
    final mission = widget.mission;

    if (mission.target > 0 && mission.target <= 5) {
      return _StepDots(
        current: mission.current.clamp(0, mission.target),
        total: mission.target,
        color: colors.accent,
        background: colors.surface,
      );
    }

    return StepProgressBar(
      currentStep: mission.current,
      totalSteps: mission.target,
      color: colors.accent,
      backgroundColor: colors.surface,
      height: 8,
    );
  }

  Widget _buildTrailing(MissionCardState state, Color primary) {
    // 어느 상태든 같은 폭을 차지하게 둔다. 진행바 끝이 줄마다 어긋나던 것이
    // 여기서 정리된다.
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 72),
      child: Align(
        alignment: Alignment.centerRight,
        child: switch (state) {
          MissionCardState.claimable => _ClaimButton(
              color: primary,
              isClaiming: widget.isClaiming,
              onTap: () {
                // 네트워크를 기다리지 않는다. 누른 즉시 손에 답이 온다.
                AppHaptic.primary();
                widget.onClaim();
              },
            ),
          // 진행 중에는 버튼을 두지 않는다. 지금 할 수 있는 것이 없는데 버튼이
          // 있으면 눌러 보게 되고, 눌리지 않으면 고장으로 읽힌다.
          MissionCardState.inProgress => MissionTag.neutral(
              '${widget.mission.current}/${widget.mission.target}',
            ),
          MissionCardState.claimed => MissionTag.neutral('받음'),
        },
      ),
    );
  }
}

/// 받기 버튼.
///
/// 앱의 다른 버튼(추가 FAB)과 같은 결이다. 테마색으로 채우고 흰 글자만 얹는다.
/// 테두리와 그림자를 겹쳐 두면 작은 버튼이 무거워 보인다.
class _ClaimButton extends StatelessWidget {
  final Color color;
  final bool isClaiming;
  final VoidCallback onTap;

  const _ClaimButton({
    required this.color,
    required this.isClaiming,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: isClaiming ? null : onTap,
      // 진동은 받기 처리 쪽에서 한 번만 준다.
      haptic: HapticLevel.none,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: isClaiming
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const StandardText(
                text: '받기',
                fontSize: 14,
                color: Colors.white,
                maxLines: 1,
              ),
      ),
    );
  }
}

/// 목표가 작을 때 쓰는 칸 진행도. 채워진 칸이 하나씩 보인다.
class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  final Color color;
  final Color background;

  const _StepDots({
    required this.current,
    required this.total,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedLinearGauge(
              // 칸은 한 칸씩 채워진다. 차오르는 방향이 보이게 지연을 준다.
              value: i < current ? 1 : 0,
              color: color,
              backgroundColor: background,
              height: 8,
              borderRadius: 4,
              duration: AppMotion.normal,
              delay: AppMotion.stagger * i,
            ),
          ),
        ],
      ],
    );
  }
}
