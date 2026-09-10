import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppRewardColors.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedGauge.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/MissionProvider.dart';
import 'MissionIcon.dart';
import 'MissionPalette.dart';
import 'MissionRewardChip.dart';
import 'MissionScreen.dart';

/// 홈 맨 위에 붙는 오늘의 미션 배너다.
///
/// 미션 화면의 히어로와 톤을 맞춘다. 진행은 테마색, 받을 보상은 금색이다.
/// 왼쪽 그림도 미션 화면과 같은 것을 쓴다 — 지금 눈여겨볼 미션의 그림이다.
///
/// 미션 조회에 실패했거나 미션이 하나도 없으면 **배너를 통째로 숨긴다.**
/// 백엔드에 아직 미션 API 가 없을 때 홈에 오류가 남지 않아야 한다.
class TodayMissionCard extends StatelessWidget {
  const TodayMissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

    if (!missionProvider.hasMissions) return const SizedBox.shrink();

    final total = missionProvider.dailyTotalCount;
    final completed = missionProvider.dailyCompletedCount;
    // 진행도(n/m)는 오늘 것만 센다. 배지는 거기에 지난 미션을 더한다.
    // 기간을 넘긴 미수령 보상이 배지에 안 잡히면 있는 줄도 모르고 지나간다.
    final unclaimed = missionProvider.bannerUnclaimedCount;
    final ratio = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final highlight = _highlightMission(missionProvider.dailyMissions);

    return Padding(
      // 아래에 추천 복습 배너가 이어 붙는다. 둘이 세로로 쌓이면 홈 위쪽이
      // 무거워지므로 사이를 좁히고 이 카드 자체도 납작하게 둔다.
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PressableScale(
        onTap: () {
          Navigator.push(
            context,
            TossPageRoute(builder: (_) => const MissionScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: themeProvider.primaryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              MissionIconBox(
                iconKey: highlight?.iconKey ?? MissionIconKeys.fallback,
                code: highlight?.code,
                // 홈에서도 미션 화면과 같은 갈래 색을 쓴다.
                colors: MissionPalette.colorsOf(
                  code: highlight?.code,
                  iconKey: highlight?.iconKey,
                ),
                padding: 6,
                iconSize: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: StandardText(
                            text: '오늘의 미션',
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        StandardText(
                          text: '$completed/$total',
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                        if (unclaimed > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _ClaimableBadge(count: unclaimed),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedLinearGauge(
                      value: ratio.toDouble(),
                      color: themeProvider.primaryColor,
                      backgroundColor: AppColors.surfaceMuted,
                      height: 5,
                      borderRadius: AppRadius.full,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  /// 배너에 그림을 빌려 줄 미션.
  ///
  /// 받을 수 있는 것이 있으면 그것, 없으면 아직 못 끝낸 것, 그것도 없으면
  /// 첫 번째다. 오늘 눈여겨볼 미션이 배너의 얼굴이 된다.
  static MissionModel? _highlightMission(List<MissionModel> missions) {
    if (missions.isEmpty) return null;
    for (final mission in missions) {
      if (mission.isClaimable) return mission;
    }
    for (final mission in missions) {
      if (!mission.completed) return mission;
    }
    return missions.first;
  }
}

/// 받을 보상이 몇 개 남았는지 알리는 금색 배지.
///
/// 테마색이 아니라 금색이다. 보상의 색은 테마와 무관하게 고정한다.
class _ClaimableBadge extends StatelessWidget {
  final int count;

  const _ClaimableBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppRewardColors.coinSurface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppRewardColors.coin.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MissionCoin(size: 12),
          const SizedBox(width: 4),
          StandardText(
            text: '받기 $count',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppRewardColors.onCoin,
          ),
        ],
      ),
    );
  }
}
