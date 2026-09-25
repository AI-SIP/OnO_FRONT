import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedGauge.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/CosmeticProvider.dart';
import '../../Provider/MissionProvider.dart';
import '../User/Widget/FrogCharacter.dart';
import 'MissionPalette.dart';
import 'MissionRewardChip.dart';
import 'MissionTag.dart';
import 'MissionScreen.dart';

/// 홈 맨 위에 붙는 오늘의 미션 배너다.
///
/// 미션 화면의 히어로와 톤을 맞춘다. 진행은 테마색, 받을 보상은 금색이다.
/// 왼쪽 그림도 미션 화면과 같은 것을 쓴다 — 지금 눈여겨볼 미션의 그림이다.
///
/// 미션 조회에 실패했거나 미션이 하나도 없으면 **배너를 통째로 숨긴다.**
/// 백엔드에 아직 미션 API 가 없을 때 홈에 오류가 남지 않아야 한다.
class TodayMissionCard extends StatelessWidget {
  /// 이 카드와 추천 복습 배너가 함께 쓰는 최소 높이.
  ///
  /// 추천 복습 배너는 밀린 문제가 있으면 두 줄이 되어 이 카드보다 8 쯤
  /// 높았다. 두 줄일 때의 높이를 둘 다의 바닥으로 삼아 나란히 같은 크기로
  /// 보이게 한다. 글자를 키운 기기에서는 각자 더 커질 수 있다.
  static const double minHeight = 76;

  const TodayMissionCard({super.key});

  /// 진행 게이지를 테스트에서 찾는 키.
  static const Key gaugeKey = Key('today_mission_gauge');

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
      // 무거워지므로 사이를 좁힌다.
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PressableScale(
        onTap: () {
          Navigator.push(
            context,
            TossPageRoute(builder: (_) => const MissionScreen()),
          );
        },
        child: Container(
          // 바로 아래 추천 복습 배너와 같은 크기로 보이도록 안쪽 여백과
          // 최소 높이를 맞춘다.
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: minHeight),
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
              // 미션 갈래 그림 대신 그 사람이 꾸민 개구리를 세운다. 홈에서
              // 처음 마주치는 자리라, 남의 아이콘이 아니라 내 캐릭터가 있는
              // 편이 옷장으로 이어진다.
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: MissionPalette.colorsOf(
                    code: highlight?.code,
                    iconKey: highlight?.iconKey,
                  ).surface,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: FrogHeadAvatar(
                  layers: context.watch<CosmeticProvider>().layers,
                  size: 24,
                ),
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
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // 트랙을 회색이 아니라 주제색으로 옅게 깐다. 회색 트랙은
                    // 흰 카드 위에서 거의 구분되지 않아, 하나도 못 채운 날에는
                    // 게이지가 통째로 없는 것처럼 보였다. 업적 게이지와 같은 농도다.
                    AnimatedLinearGauge(
                      key: gaugeKey,
                      value: ratio.toDouble(),
                      color: themeProvider.primaryColor,
                      backgroundColor:
                          themeProvider.primaryColor.withValues(alpha: 0.16),
                      height: 5,
                      borderRadius: AppRadius.full,
                    ),
                  ],
                ),
              ),
              // 받을 것은 누르면 가는 곳 바로 앞에 둔다. 아래 추천 복습
              // 배너의 개수 배지와 같은 자리다.
              if (unclaimed > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                MissionTag(
                  text: '받기 $unclaimed',
                  color: themeProvider.primaryColor,
                  leading: MissionRewardToken(
                    size: MissionTag.fontSize * 1.1,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
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
