import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppRewardColors.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossBottomSheet.dart';
import '../../Module/Text/StandardText.dart';
import '../../Provider/MissionProvider.dart';
import 'MissionCard.dart';
import 'MissionRewardChip.dart';

/// 지난 기간의 미수령 보상을 알리는 접힌 배너다.
///
/// 전에는 지난 미션을 일일 탭 맨 위에 펼쳐 놓았는데 두 가지가 어그러졌다.
/// 어제 것과 오늘 것이 같은 제목으로 두 번 보였고, 지난주 **주간** 미션이
/// **일일** 탭에 앉아 있었다. 한 줄로 접어서 탭 밖으로 꺼내면 둘 다 없어진다.
class ExpiredMissionBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const ExpiredMissionBanner({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppRewardColors.coinSurface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(
            color: AppRewardColors.coin.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            const MissionCoin(size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StandardText(
                text: '받지 않은 보상 $count개',
                fontSize: 13,
                color: AppRewardColors.onCoin,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppRewardColors.onCoin,
            ),
          ],
        ),
      ),
    );
  }
}

/// 지난 미션만 모아 보여 주는 시트를 띄운다.
Future<void> showExpiredMissionSheet(
  BuildContext context, {
  required void Function(MissionModel mission) onClaim,
}) {
  return showTossSheet<void>(
    context: context,
    builder: (sheetContext) => _ExpiredMissionSheet(onClaim: onClaim),
  );
}

class _ExpiredMissionSheet extends StatelessWidget {
  final void Function(MissionModel mission) onClaim;

  const _ExpiredMissionSheet({required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(context);
    final missions = missionProvider.expiredMissions;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StandardText(
              text: '지난 미션',
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: AppSpacing.xs),
            const StandardText(
              text: '기간은 지났지만 아직 받을 수 있어요.',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),
            // 내용이 길면 시트 안에서만 스크롤된다. 화면을 다 덮지 않는다.
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: missions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final mission = missions[index];
                  return MissionCard(
                    mission: mission,
                    isClaiming: missionProvider.isClaiming(mission.progressId),
                    showPeriod: true,
                    onClaim: () => onClaim(mission),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
