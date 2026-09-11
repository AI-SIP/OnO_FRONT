import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Model/User/UserInfoModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/AnimatedGauge.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/MotionReplayScope.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/CosmeticProvider.dart';
import '../../Provider/MissionProvider.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Provider/UserProvider.dart';
import '../Cosmetic/CosmeticClosetScreen.dart';
import '../Cosmetic/Widget/CosmeticStage.dart';
import '../Mission/MissionCard.dart';
import '../Mission/MissionClaimScope.dart';
import '../Mission/MissionScreen.dart';
import '../Tutorial/TutorialTargets.dart';
import 'Widget/ActivityGrowthCard.dart';

/// 개구리와 성장을 한 화면에 몰아 주는 탭이다.
///
/// 그동안 미션과 옷장은 마이페이지 레벨 카드 구석의 작은 글자 링크 뒤에
/// 숨어 있었다. 이 앱에서 가장 오래 쳐다보게 될 것이 개구리인데, 정작 그
/// 개구리를 보려면 두 번을 눌러 들어가야 했다. 하단 탭 하나를 내주고 **개구리를
/// 화면의 주인공으로** 올린다.
///
/// 화면은 두 덩어리다.
///
/// - **무대**: 꾸민 개구리가 크게 서 있고, 레벨과 경험치가 그 위아래에 붙는다.
///   스크롤과 함께 사라지지 않는다. 보상을 받을 때 코인이 날아가 닿을 자리라서
///   늘 화면에 있어야 한다. 옷장 무대([CosmeticStageFrog])의 조명과 그림자를
///   그대로 빌려 쓴다.
/// - **오늘의 미션**: 미션 화면의 카드([MissionCard])를 그대로 쓰고, 받는
///   절차도 [MissionClaimScope] 로 같은 것을 쓴다. 여기서 받아도 상자가 열리고
///   코인이 날아가고 레벨업 화면이 뜬다.
///
/// **개구리를 누르면 옷장으로 간다.** 마이페이지와 미션 화면이 쓰던 약속을
/// 그대로 잇는다. 이 앱에서 개구리를 누르면 늘 꾸미러 가는 문이 열린다.
class CharacterScreen extends StatefulWidget {
  final TutorialTargets? tutorialTargets;

  const CharacterScreen({super.key, this.tutorialTargets});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  /// 캐릭터 탭이 홈의 몇 번째인지. main.dart 의 widgetOptions 순서를 따른다.
  static const int _tabIndex = 2;

  /// 코인이 날아가 닿을 자리(무대의 레벨 칩).
  final GlobalKey _counterKey = GlobalKey();

  /// 이 탭에 몇 번째로 들어왔는지.
  ///
  /// 홈이 탭 다섯을 IndexedStack 으로 들고 있어서 앱을 켜는 순간 이 화면까지
  /// 함께 만들어진다. 그대로 두면 경험치 바가 탭을 누르기도 전에 다 차 있으므로,
  /// 들어올 때마다 이 값을 올려 게이지와 카드를 처음부터 다시 재생한다.
  int _visitSequence = 0;
  bool _wasSelected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<MissionProvider>(context, listen: false).fetchMissions();
    });
  }

  /// build 안에서 부른다. setState 를 부르지 않고 값만 갱신하므로 이번 build
  /// 에 그대로 반영된다.
  void _syncVisitSequence(int screenIndex) {
    final isSelected = screenIndex == _tabIndex;
    if (isSelected == _wasSelected) return;
    _wasSelected = isSelected;
    if (isSelected) _visitSequence++;
  }

  Future<void> _refresh() async {
    final missionProvider =
        Provider.of<MissionProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await Future.wait([
      missionProvider.fetchMissions(),
      userProvider.fetchUserInfo(showErrorSnackBar: false),
    ]);
  }

  void _openCloset() {
    Navigator.push(
      context,
      TossPageRoute(builder: (_) => const CosmeticClosetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final missionProvider = Provider.of<MissionProvider>(context);
    final userInfo = Provider.of<UserProvider>(context).userInfoModel;
    _syncVisitSequence(
      Provider.of<ScreenIndexProvider>(context).screenIndex,
    );

    final missions = sortedMissionsForList(missionProvider.dailyMissions);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MotionReplayScope(
        token: _visitSequence,
        child: MissionClaimScope(
          counterKey: _counterKey,
          builder: (context, claim) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CharacterStage(
                key: widget.tutorialTargets?.levelCardKey,
                counterKey: _counterKey,
                arrivalTick: claim.arrivalTick,
                themeProvider: themeProvider,
                onFrogTap: _openCloset,
                onClosetTap: _openCloset,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: themeProvider.primaryColor,
                  onRefresh: _refresh,
                  child: _buildBody(
                    missions,
                    missionProvider,
                    themeProvider,
                    claim,
                    userInfo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 무대 아래에서 스크롤되는 부분.
  ///
  /// 오늘의 미션이 먼저다. 미션 화면과 같은 카드를 같은 순서로 쓴다. 그 아래에
  /// 무엇으로 레벨이 올랐는지를 둔다. 순서가 반대면 숫자 넉 줄이 미션을 밀어
  /// 낸다.
  Widget _buildBody(
    List<MissionModel> missions,
    MissionProvider missionProvider,
    ThemeHandler themeProvider,
    MissionClaimHandle claim,
    UserInfoModel? userInfo,
  ) {
    final done = missionProvider.dailyCompletedCount;
    final total = missionProvider.dailyTotalCount;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        _buildSectionHeader(themeProvider, done: done, total: total),
        const SizedBox(height: AppSpacing.md),
        if (missions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
            child: StandardText(
              text: '아직 미션이 없어요',
              fontSize: 14,
              color: AppColors.textTertiary,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          )
        else
          ...AppearTransition.stagger(
            initialDelay: AppMotion.stagger * 2,
            [
              for (final mission in missions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MissionCard(
                    mission: mission,
                    isClaiming: missionProvider.isClaiming(mission.progressId),
                    rewardKey: claim.rewardKeyOf(mission),
                    shakeTick: claim.shakeTickOf(mission),
                    onClaim: () => claim.claim(mission),
                  ),
                ),
            ],
          ),
        if (userInfo != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppearTransition(
            delay: AppMotion.stagger * 6,
            child: ActivityGrowthCard(userInfo: userInfo),
          ),
        ],
      ],
    );
  }

  /// `오늘의 미션 2/4` 와 전체 미션으로 가는 길.
  ///
  /// 이 탭에는 오늘 것만 둔다. 주간과 지난 미션까지 여기 쌓으면 개구리가
  /// 목록에 밀려난다. 더 볼 사람만 미션 화면으로 넘어간다.
  Widget _buildSectionHeader(
    ThemeHandler themeProvider, {
    required int done,
    required int total,
  }) {
    return Row(
      children: [
        const StandardText(
          text: '오늘의 미션',
          fontSize: 16,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        if (total > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          StandardText(
            text: '$done / $total',
            fontSize: 13,
            color: AppColors.textTertiary,
          ),
        ],
        const Spacer(),
        PressableScale(
          onTap: () => Navigator.push(
            context,
            TossPageRoute(builder: (_) => const MissionScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StandardText(
                  text: '전체 보기',
                  fontSize: 13,
                  color: themeProvider.primaryColor,
                  maxLines: 1,
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: themeProvider.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 개구리가 서 있는 무대다. 이 화면의 주인공이 앉는 자리다.
///
/// 바탕은 위가 밝고 아래로 갈수록 테마색이 도는 세로 그라데이션이다. 위에서
/// 빛이 들어오고 아래가 바닥인 결이라, 그 위에 선 개구리가 조각이 아니라
/// 장면으로 읽힌다. 아래 모서리만 둥글려서 화면 위에서 내려온 무대처럼
/// 보이게 하고, 좌우는 화면 끝까지 붙인다.
///
/// 금색 같은 별도의 장식색을 쓰지 않는다. 쓰는 색은 사용자가 테마에서 고른
/// 색 하나뿐이다. 그래야 이 화면만 앱에서 겉돌지 않는다.
class _CharacterStage extends StatelessWidget {
  final GlobalKey counterKey;
  final int arrivalTick;
  final ThemeHandler themeProvider;
  final VoidCallback onFrogTap;
  final VoidCallback onClosetTap;

  const _CharacterStage({
    super.key,
    required this.counterKey,
    required this.arrivalTick,
    required this.themeProvider,
    required this.onFrogTap,
    required this.onClosetTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = themeProvider.primaryColor;
    final userInfo = Provider.of<UserProvider>(context).userInfoModel;
    // LayoutBuilder 안에서는 watch 가 듣지 않는다. 그 바깥에서 받는다.
    final cosmetic = context.watch<CosmeticProvider>();

    final level = userInfo?.totalStudyLevel ?? 0;
    final point = userInfo?.totalStudyCurrentPoint ?? 0;
    final threshold = userInfo?.totalStudyNextLevelThreshold ?? 40;
    final progress = threshold > 0 ? (point / threshold).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(color.withValues(alpha: 0.05), Colors.white),
            Color.alphaBlend(color.withValues(alpha: 0.13), Colors.white),
            Color.alphaBlend(color.withValues(alpha: 0.20), Colors.white),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xlarge + 8),
        ),
        // 무대가 아래 목록에서 살짝 떠 보이게 한다. 카드가 아니라 장면이라는
        // 신호라서 테마색 그림자를 옅게 쓴다.
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final frogSize = _frogSizeFor(context, constraints);

            return Center(
              child: ConstrainedBox(
                // 태블릿에서 무대가 끝없이 넓어지지 않게 가운데로 모은다.
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildLevelChip(level, color)),
                          const SizedBox(width: AppSpacing.md),
                          _buildClosetButton(color),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CosmeticStageFrog(
                        layers: cosmetic.layers,
                        size: frogSize,
                        color: color,
                        // 갈아입기는 옷장에서 한다. 여기서는 들썩일 일이 없다.
                        equipTick: 0,
                        // 누름 하나가 한 가지 일만 하게 한다. 여기 개구리는
                        // 옷장으로 가는 문이라 말풍선을 띄우지 않는다.
                        showEncouragement: false,
                        onTap: () {
                          AppHaptic.selection();
                          onFrogTap();
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildExpBar(point, threshold, progress, color),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 레벨 칩. 코인이 날아와 닿는 자리이기도 하다.
  Widget _buildLevelChip(int level, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      // 글자를 키운 기기에서 칩이 남은 폭보다 길어진다. 넘치게 두는 대신
      // 줄여서 앉힌다.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: _ArrivalPop(
          tick: arrivalTick,
          child: Container(
            key: counterKey,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm - 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_florist_rounded, size: 14, color: color),
                const SizedBox(width: AppSpacing.xs),
                StandardText(
                  text: '학습 레벨',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  maxLines: 1,
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedCountText(
                  value: level,
                  formatter: (value) => 'Lv.${value.round()}',
                  fontSize: 15,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 옷장으로 가는 두 번째 길.
  ///
  /// 첫 번째 길은 개구리 자신이다. 그래도 글로 적힌 길이 하나 있어야 처음 온
  /// 사람이 개구리를 눌러 볼 생각을 한다.
  Widget _buildClosetButton(Color color) {
    return PressableScale(
      onTap: onClosetTap,
      scale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm - 2,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.32),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom_rounded, size: 15, color: Colors.white),
            SizedBox(width: AppSpacing.xs),
            StandardText(
              text: '꾸미기',
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  /// 다음 레벨까지의 경험치.
  ///
  /// 개구리 발치에 둔다. 숫자가 개구리 위에 있으면 숫자가 주인공이 된다.
  Widget _buildExpBar(int point, int threshold, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedLinearGauge(
          value: progress,
          color: color,
          // 무대 바탕이 이미 테마색으로 물들어 있다. 회색을 깔면 그 자리만
          // 탁해진다. 같은 테마색을 한 단계 진하게 깔아 파인 자리로 만든다.
          backgroundColor: color.withValues(alpha: 0.18),
          height: 8,
          borderRadius: AppRadius.full,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const StandardText(
              text: '다음 레벨까지',
              fontSize: 11,
              color: AppColors.textSecondary,
              maxLines: 1,
            ),
            AnimatedCountText(
              value: point,
              formatter: (value) => '${value.round()} / $threshold XP',
              fontSize: 12,
              color: color,
            ),
          ],
        ),
      ],
    );
  }

  /// 개구리 한 변의 길이. 좁은 쪽과 낮은 쪽 중 더 빡빡한 쪽을 따른다.
  ///
  /// 무대가 붙박이라 개구리가 크면 아래 미션 카드가 첫 화면에서 사라진다.
  /// 화면 높이를 기준으로 잡아서 작은 폰에서도 미션 한 장은 보이게 한다.
  double _frogSizeFor(BuildContext context, BoxConstraints constraints) {
    final byWidth = constraints.maxWidth * 0.52;
    final byHeight = MediaQuery.of(context).size.height * 0.26;
    final smaller = byWidth < byHeight ? byWidth : byHeight;
    return smaller.clamp(96.0, 300.0);
  }
}

/// [tick] 이 바뀔 때마다 한 번 커졌다 돌아온다.
///
/// 코인이 레벨 칩에 닿는 순간에 쓴다. [SelectionPop] 은 켜질 때 한 번만 튀는
/// 것이라 여러 번 반복되는 이 자리에는 맞지 않는다.
class _ArrivalPop extends StatefulWidget {
  final int tick;
  final Widget child;

  const _ArrivalPop({required this.tick, required this.child});

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
    if (widget.tick != oldWidget.tick && !AppMotion.isReduced(context)) {
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
    if (AppMotion.isReduced(context)) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
