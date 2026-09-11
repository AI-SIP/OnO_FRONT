import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/MissionProvider.dart';
import '../../Provider/UserProvider.dart';
import 'ExpiredMissionSection.dart';
import 'MissionCard.dart';
import '../Cosmetic/CosmeticClosetScreen.dart';
import 'MissionClaimScope.dart';
import 'MissionHeroCard.dart';
import 'MissionHistoryScreen.dart';
import 'MissionSegments.dart';

/// 일일 미션과 주간 미션을 보여 주고 보상을 받는 화면이다.
///
/// 화면의 뼈대는 세 층이다. 맨 위에 오늘을 요약하는 히어로(개구리와 링, 오늘
/// 받은 XP), 그 아래 지난 미션 배너, 그 아래 일일/주간 목록이다. 히어로는
/// 스크롤과 함께 사라지지 않는다. 보상을 받을 때 코인이 날아가 닿을 자리라서
/// 늘 화면에 있어야 한다.
///
/// 보상을 받는 절차 자체는 [MissionClaimScope] 가 들고 있다. 미션을 받는 자리는
/// 이제 이 화면 하나다. 옷장 탭은 미션 목록을 걷어 내고 이 화면으로 가는
/// 버튼만 남겼다.
///
/// 조회에 실패하면 오류를 띄우지 않는다. 미션이 없는 것처럼 조용한 안내만
/// 남긴다. 백엔드에 아직 이 API 가 없어 404 가 떨어지는 동안에도 앱이 평소대로
/// 돌아야 하기 때문이다.
class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  /// 0 이면 일일, 1 이면 주간.
  int _tabIndex = 0;

  /// 목록 등장 연출을 이미 한 번 재생했는지.
  ///
  /// 진입 연출은 화면에 처음 들어올 때 한 번이면 된다. 탭을 옮길 때마다 줄이
  /// 하나씩 다시 올라오면 그건 연출이 아니라 깜빡임이다.
  bool _entryPlayed = false;

  /// 코인이 날아가 닿을 자리(히어로의 XP 카운터).
  final GlobalKey _counterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<MissionProvider>(context, listen: false).fetchMissions();
    });
  }

  Future<void> _refresh() {
    return Provider.of<MissionProvider>(context, listen: false).fetchMissions();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final missionProvider = Provider.of<MissionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: StandardText(
          text: '미션',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: !missionProvider.hasMissions
          ? _buildEmpty(themeProvider)
          : MissionClaimScope(
              counterKey: _counterKey,
              // 이 화면의 카운터는 **오늘 받은 XP** 다. 주간이나 지난 미션을
              // 받으면 코인만 날아오고 오늘 숫자는 그대로여야 한다.
              countsToward: (result) => missionProvider.dailyMissions
                  .any((m) => m.progressId == result.progressId),
              builder: (context, claim) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        AppearTransition(
                          child: MissionHeroCard(
                            dailyMissions: missionProvider.dailyMissions,
                            level:
                                userProvider.userInfoModel?.totalStudyLevel ??
                                    1,
                            primaryColor: themeProvider.primaryColor,
                            counterKey: _counterKey,
                            pendingXp: claim.pendingXp,
                            arrivalTick: claim.arrivalTick,
                            onCounterTap: () => Navigator.push(
                              context,
                              TossPageRoute(
                                builder: (_) => const MissionHistoryScreen(),
                              ),
                            ),
                            onFrogTap: () => Navigator.push(
                              context,
                              TossPageRoute(
                                builder: (_) => const CosmeticClosetScreen(),
                              ),
                            ),
                          ),
                        ),
                        if (missionProvider.expiredUnclaimedCount > 0) ...[
                          const SizedBox(height: AppSpacing.md),
                          AppearTransition(
                            delay: AppMotion.stagger,
                            child: ExpiredMissionBanner(
                              count: missionProvider.expiredUnclaimedCount,
                              onTap: () {
                                AppHaptic.secondary();
                                showExpiredMissionSheet(
                                  context,
                                  onClaim: claim.claim,
                                  // 목록과 같은 것을 넘긴다. 시트에서 받아도
                                  // 실패하면 카드가 흔들리고 코인도 날아간다.
                                  rewardKeyOf: claim.rewardKeyOf,
                                  shakeTickOf: claim.shakeTickOf,
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        // 등장 연출로 감싸지 않는다. 감싸면 그 안쪽이 다시
                        // 만들어질 때 선택된 알약이 잠깐 사라진다.
                        MissionSegments(
                          key: const ValueKey('mission_segments'),
                          index: _tabIndex,
                          color: themeProvider.primaryColor,
                          onChanged: (index) => setState(() {
                            _tabIndex = index;
                            // 탭을 옮긴 뒤로는 목록이 하나씩 올라오지 않는다.
                            _entryPlayed = true;
                          }),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    // 전환 영역 뒤를 반드시 칠해 둔다. 비어 있으면 바뀌는
                    // 사이에 검정 캔버스가 그대로 비친다.
                    child: ColoredBox(
                      color: AppColors.background,
                      child: AnimatedSwitcher(
                        duration: AppMotion.fast,
                        switchInCurve: AppMotion.enter,
                        switchOutCurve: AppMotion.exit,
                        // 페이드만 한다. 크기를 건드리면 가장자리에 틈이 생긴다.
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                          fit: StackFit.expand,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        ),
                        // 한 번에 한 탭만 그린다. 두 탭을 함께 들고 있으면
                        // 숨은 쪽까지 같이 흐려진다.
                        child: KeyedSubtree(
                          key: ValueKey<int>(_tabIndex),
                          child: _buildMissionList(
                            _tabIndex == 0
                                ? missionProvider.dailyMissions
                                : missionProvider.weeklyMissions,
                            missionProvider,
                            themeProvider,
                            claim,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty(ThemeHandler themeProvider) {
    return RefreshIndicator(
      color: themeProvider.primaryColor,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xxxl,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: const [
          StandardText(
            text: '아직 미션이 없어요',
            fontSize: 14,
            color: AppColors.textTertiary,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// 한 탭의 목록이다.
  ///
  /// 받을 수 있는 것이 맨 위, 받은 것이 맨 아래다. 받은 미션이 목록 한가운데를
  /// 차지할 이유가 없다.
  Widget _buildMissionList(
    List<MissionModel> missions,
    MissionProvider missionProvider,
    ThemeHandler themeProvider,
    MissionClaimHandle claim,
  ) {
    final sorted = sortedMissionsForList(missions);

    return RefreshIndicator(
      color: themeProvider.primaryColor,
      onRefresh: _refresh,
      child: sorted.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxxl,
              ),
              children: const [
                StandardText(
                  text: '아직 미션이 없어요',
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: AppearTransition.stagger(
                enabled: !_entryPlayed,
                initialDelay: AppMotion.stagger * 3,
                [
                  for (final mission in sorted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: MissionCard(
                        mission: mission,
                        isClaiming:
                            missionProvider.isClaiming(mission.progressId),
                        rewardKey: claim.rewardKeyOf(mission),
                        shakeTick: claim.shakeTickOf(mission),
                        onClaim: () => claim.claim(mission),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// 목록에 앉힐 순서로 미션을 정렬한다.
///
/// 받을 수 있는 것이 맨 위, 진행 중인 것이 가운데, 받은 것이 맨 아래다.
/// 미션 화면과 캐릭터 탭이 같은 순서를 써야 두 화면이 따로 놀지 않는다.
List<MissionModel> sortedMissionsForList(List<MissionModel> missions) {
  return [...missions]..sort(
      (a, b) =>
          _weightOf(MissionCardState.of(a)) - _weightOf(MissionCardState.of(b)),
    );
}

int _weightOf(MissionCardState state) {
  return switch (state) {
    MissionCardState.claimable => 0,
    MissionCardState.inProgress => 1,
    MissionCardState.claimed => 2,
  };
}
