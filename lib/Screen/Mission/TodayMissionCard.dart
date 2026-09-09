import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/MissionProvider.dart';
import 'MissionIcon.dart';
import 'MissionScreen.dart';

/// 홈 맨 위에 붙는 오늘의 미션 배너다.
///
/// 바로 옆에 있는 추천 복습 배너(`DirectoryScreen._buildReviewDueBadge`)와 같은
/// 모양을 쓴다. 같은 자리에 다른 모양의 카드가 둘 놓이면 눈에 거슬린다.
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        onTap: () {
          Navigator.push(
            context,
            TossPageRoute(builder: (_) => const MissionScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
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
                iconKey: MissionIconKeys.fallback,
                color: themeProvider.primaryColor,
                iconSize: 16,
              ),
              const SizedBox(width: 12),
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
                        const SizedBox(width: 6),
                        StandardText(
                          text: '$completed/$total',
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                        if (unclaimed > 0) ...[
                          const SizedBox(width: 6),
                          _ClaimableBadge(
                            count: unclaimed,
                            color: themeProvider.primaryColor,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: ratio.toDouble(),
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeProvider.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

/// 받을 보상이 몇 개 남았는지 알리는 배지.
class _ClaimableBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _ClaimableBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: StandardText(
        text: '받기 $count',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
