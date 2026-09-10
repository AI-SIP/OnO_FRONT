import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionClaimResultModel.dart';
import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Design/AppToast.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/MissionProvider.dart';
import '../../Provider/UserProvider.dart';
import 'ExpiredMissionSection.dart';
import 'MissionCard.dart';
import 'MissionHeroCard.dart';
import 'MissionHistoryScreen.dart';
import 'MissionLevelUp.dart';
import 'MissionRewardCelebration.dart';
import 'MissionRewardFlight.dart';
import 'MissionSegments.dart';

/// 일일 미션과 주간 미션을 보여 주고 보상을 받는 화면이다.
///
/// 화면의 뼈대는 세 층이다. 맨 위에 오늘을 요약하는 히어로(개구리와 링, 오늘
/// 받은 XP), 그 아래 지난 미션 배너, 그 아래 일일/주간 목록이다. 히어로는
/// 스크롤과 함께 사라지지 않는다. 보상을 받을 때 코인이 날아가 닿을 자리라서
/// 늘 화면에 있어야 한다.
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

  /// 지금 날아가는 중인 XP. 코인이 닿을 때까지 히어로 합계에서 빼 둔다.
  int _pendingXp = 0;

  /// 코인이 카운터에 닿은 횟수. 칩이 튀는 신호로 쓴다.
  int _arrivalTick = 0;

  /// 받기가 실패한 미션과 그 횟수. 카드를 흔드는 신호로 쓴다.
  final Map<int, int> _shakeTicks = {};

  /// 보상 연출을 하나씩 처리하는 줄. 연달아 받아도 겹쳐 뜨지 않는다.
  Future<void> _celebrationQueue = Future<void>.value();

  /// 코인이 날아가 닿을 자리(히어로의 XP 카운터).
  final GlobalKey _counterKey = GlobalKey();

  /// 코인이 출발하는 자리(각 카드의 보상 칩). 미션마다 하나씩 만든다.
  final Map<int, GlobalKey> _rewardKeys = {};

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

  GlobalKey _rewardKeyFor(MissionModel mission) {
    final progressId = mission.progressId;
    if (progressId == null) return GlobalKey();
    return _rewardKeys.putIfAbsent(progressId, GlobalKey.new);
  }

  /// 보상을 받는다.
  ///
  /// 두 번 눌리는 것은 [MissionProvider.claim] 이 막는다. 여기서는 받은 뒤의
  /// 순서를 만든다. **성공은 알림으로 알리지 않는다.**
  ///
  /// 1. 누르는 즉시 버튼이 눌리고 진동이 온다 (카드 쪽에서 한다)
  /// 2. 보상 카드가 화면 가운데로 튀어오른다 — 레벨업이 있든 없든 항상
  /// 3. 카드가 닫히며 코인이 상단 카운터로 날아간다
  /// 4. 닿으면 칩이 튀고 숫자가 롤업된다
  /// 5. 미션 카드는 받음으로 가라앉고 목록 아래로 내려간다
  Future<void> _claim(MissionModel mission) async {
    final progressId = mission.progressId;
    if (progressId == null) return;

    final missionProvider =
        Provider.of<MissionProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (missionProvider.isClaiming(progressId)) return;

    // 받기 전에 열려 있던 테마를 찍어 둔다. 서버가 해금 정보를 내려주지 않아서
    // 받은 뒤와 비교해 이번에 열린 것을 알아낸다.
    final unlockedBefore = unlockedThemeIndexes(userProvider.userInfoModel);
    // 레벨업 전의 종합 레벨. 개구리 그림이 실제로 바뀌는지 판단하는 데 쓴다.
    final levelBefore = userProvider.userInfoModel?.totalStudyLevel;

    final result = await missionProvider.claim(progressId);
    if (!mounted) return;

    if (result == null) {
      await _handleClaimFailure(progressId, missionProvider);
      return;
    }

    // 오늘 합계에 잡히는 미션인지. 주간이나 지난 미션은 오늘 숫자를 올리지
    // 않으므로 코인만 날리고 숫자는 그대로 둔다.
    final countsToday = missionProvider.dailyMissions
        .any((m) => m.progressId == result.progressId);

    await _enqueueCelebration(() async {
      await _celebrateReward(
        mission: mission,
        result: result,
        countsToday: countsToday,
      );
      if (!mounted) return;

      // 레벨 카드가 방금 받은 경험치를 반영하도록 사용자 정보를 다시 읽는다.
      // 여기서 실패해도 보상은 이미 받았다. 갱신이 안 됐다고 오류를 띄우지 않는다.
      try {
        await userProvider.fetchUserInfo(showErrorSnackBar: false);
      } catch (error) {
        debugPrint('[MissionScreen] 보상 뒤 사용자 정보 갱신 실패: $error');
      }
      if (!mounted) return;

      if (result.leveledUp) {
        await showMissionLevelUp(
          context,
          level: result.totalStudyLevel,
          previousLevel: levelBefore,
          unlockedThemeIndexes: newlyUnlockedThemeIndexes(
            unlockedBefore,
            unlockedThemeIndexes(userProvider.userInfoModel),
          ),
        );
      }
    });
  }

  /// 보상 연출을 줄 세워 하나씩 돌린다.
  Future<void> _enqueueCelebration(Future<void> Function() body) {
    final next = _celebrationQueue.then((_) async {
      if (!mounted) return;
      await body();
    });
    // 하나가 실패해도 줄이 막히지 않게 한다.
    _celebrationQueue = next.catchError((Object error) {
      debugPrint('[MissionScreen] 보상 연출 실패: $error');
    });
    return next;
  }

  /// 보상 카드를 띄우고, 닫히면 코인을 카운터로 날린다.
  Future<void> _celebrateReward({
    required MissionModel mission,
    required MissionClaimResultModel result,
    required bool countsToday,
  }) async {
    final pending = countsToday ? result.rewardValue : 0;
    if (pending > 0) {
      setState(() => _pendingXp += pending);
    }

    final coinOrigin = await showMissionRewardCelebration(
      context,
      missionTitle: mission.title,
      rewardType: result.rewardType,
      amount: result.rewardValue,
    );
    if (!mounted) return;

    final flying = coinOrigin != null &&
        MissionRewardFlight.launchFrom(
          context: context,
          start: coinOrigin,
          to: _counterKey,
          onArrived: () => _onCoinArrived(pending),
        );

    // 날리지 못했으면(연출을 끈 기기, 카운터가 화면에 없음) 숫자는 바로 오른다.
    if (!flying) _onCoinArrived(pending);
  }

  void _onCoinArrived(int pending) {
    if (!mounted) return;
    setState(() {
      _pendingXp = (_pendingXp - pending).clamp(0, 1 << 30);
      _arrivalTick++;
    });
  }

  void _shakeCard(int progressId) {
    if (!mounted) return;
    setState(() {
      _shakeTicks[progressId] = (_shakeTicks[progressId] ?? 0) + 1;
    });
  }

  /// 받기가 뜻대로 되지 않았을 때 무엇을 알릴지 정한다.
  ///
  /// 실패라고 단정할 수 있을 때만 오류를 띄운다.
  ///
  /// - 이미 받음(7012): 서버 기준으로는 받은 상태다. 실패가 아니므로 조용히
  ///   화면만 맞춘다
  /// - 서버가 거절: 이유를 그대로 알린다 (아직 완료하지 않음 등)
  /// - 결과를 모름(연결 끊김, 시간 초과, 5xx, 응답을 읽지 못함): 서버가 이미
  ///   XP 를 줬을 수 있다. 다시 조회해서 진실을 확인하고, 확인도 못 하면
  ///   중립적인 안내만 남긴다
  Future<void> _handleClaimFailure(
    int progressId,
    MissionProvider missionProvider,
  ) async {
    final failure = missionProvider.consumeClaimFailure();

    if (failure == null || failure.isAlreadyClaimed) {
      await missionProvider.fetchMissions();
      return;
    }

    if (!failure.isUnknown) {
      // 실패했으니 코인을 날리지 않는다. 카드가 짧게 흔들려 안 됐다고 알린다.
      _shakeCard(progressId);
      AppToast.error(failure.message);
      await missionProvider.fetchMissions();
      return;
    }

    final refreshed = await missionProvider.fetchMissions();
    if (!mounted) return;

    final mission = missionProvider.missionByProgressId(progressId);
    if (refreshed && mission != null && mission.claimed) {
      // 서버는 줬는데 답을 못 받았던 것이다. 카드가 이미 받음으로 바뀌었으니
      // 코인만 날려 준다.
      final rewardKey = _rewardKeys[progressId];
      if (rewardKey != null) {
        MissionRewardFlight.launch(
          context: context,
          from: rewardKey,
          to: _counterKey,
          onArrived: () => _onCoinArrived(0),
        );
      }
      return;
    }
    if (refreshed) {
      // 조회는 됐는데 여전히 안 받은 상태다. 이번엔 정말 실패다.
      _shakeCard(progressId);
      AppToast.error(failure.message);
      return;
    }
    _shakeCard(progressId);
    AppToast.info(_claimUnknownMessage);
  }

  static const String _claimUnknownMessage = '보상을 받았는지 확인하지 못했어요';

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
          : Column(
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
                              userProvider.userInfoModel?.totalStudyLevel ?? 1,
                          currentPoint: userProvider
                                  .userInfoModel?.totalStudyCurrentPoint ??
                              0,
                          nextLevelThreshold: userProvider.userInfoModel
                                  ?.totalStudyNextLevelThreshold ??
                              0,
                          primaryColor: themeProvider.primaryColor,
                          counterKey: _counterKey,
                          pendingXp: _pendingXp,
                          arrivalTick: _arrivalTick,
                          onCounterTap: () => Navigator.push(
                            context,
                            TossPageRoute(
                              builder: (_) => const MissionHistoryScreen(),
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
                              showExpiredMissionSheet(context, onClaim: _claim);
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
                  // 전환 영역 뒤를 반드시 칠해 둔다. 비어 있으면 바뀌는 사이에
                  // 검정 캔버스가 그대로 비친다.
                  child: ColoredBox(
                    color: AppColors.background,
                    child: AnimatedSwitcher(
                      duration: AppMotion.fast,
                      switchInCurve: AppMotion.enter,
                      switchOutCurve: AppMotion.exit,
                      // 페이드만 한다. 크기를 건드리면 가장자리에 틈이 생긴다.
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      layoutBuilder: (currentChild, previousChildren) => Stack(
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
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
  ) {
    final sorted = [...missions]..sort(
        (a, b) =>
            _weightOf(MissionCardState.of(a)) -
            _weightOf(MissionCardState.of(b)),
      );

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
                        rewardKey: _rewardKeyFor(mission),
                        shakeTick: _shakeTicks[mission.progressId] ?? 0,
                        onClaim: () => _claim(mission),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  static int _weightOf(MissionCardState state) {
    return switch (state) {
      MissionCardState.claimable => 0,
      MissionCardState.inProgress => 1,
      MissionCardState.claimed => 2,
    };
  }
}
