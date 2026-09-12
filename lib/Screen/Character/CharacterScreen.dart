import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Cosmetic/CosmeticAbilityLevels.dart';
import '../../Model/User/UserInfoModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/AnimatedGauge.dart';
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
import '../Cosmetic/Widget/CosmeticAbilityStyle.dart';
import '../Cosmetic/Widget/CosmeticStage.dart';
import '../Mission/MissionScreen.dart';
import '../Tutorial/TutorialTargets.dart';
import 'Widget/AbilityStatPanel.dart';
import 'Widget/GrowthTypeScale.dart';

/// 개구리와 성장을 한 화면에 몰아 주는 탭이다. 하단 탭에서는 `옷장`이다.
///
/// 화면은 **스크롤이 없다.** 둘이 위에서 아래로 붙박이로 앉는다.
///
/// - **무대**: 위쪽에 성장 카드(총 학습 한 줄 + 능력치 눈금판 넷)가 붙고,
///   그 아래에 꾸민 개구리가 크게 선다.
/// - **버튼 둘**: 미션과 꾸미기.
///
/// 원래는 무대 아래에 오늘의 미션 목록이 스크롤로 붙어 있었고 능력치 넉 줄은
/// 그 아래에 있었다. 경험치를 보려면 매번 스크롤을 내려야 했다. 이 탭에서
/// 가장 자주 궁금한 것이 "내가 얼마나 자랐나"인데 그게 화면 밖에 있었다는
/// 뜻이다. 목록을 버튼 하나로 접고, 그 자리를 능력치에 내줬다. 미션을 더 볼
/// 사람은 미션 버튼으로 넘어간다.
///
/// 그 뒤로도 **레벨 이야기가 개구리를 사이에 두고 갈라져 있었다.** 총 학습은
/// 개구리 위, 능력치 넷은 개구리 아래였다. 둘 다 "내가 얼마나 자랐나"에
/// 답하는 값이라 같이 읽혀야 하는데 눈이 화면을 위아래로 오가야 했다.
/// 넷을 총 학습 바로 아래로 올려 카드 하나로 묶었다.
///
/// **개구리를 누르면 격려 한마디를 한다.** 꾸미러 가는 문은 이제 버튼이
/// 따로 맡아서, 개구리를 누르는 것이 꾸미기 화면으로 가는 지름길일 필요가
/// 없어졌다.
class CharacterScreen extends StatefulWidget {
  final TutorialTargets? tutorialTargets;

  const CharacterScreen({super.key, this.tutorialTargets});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  /// 이 탭이 홈의 몇 번째인지. main.dart 의 widgetOptions 순서를 따른다.
  static const int _tabIndex = 2;

  /// 이 탭에 몇 번째로 들어왔는지.
  ///
  /// 홈이 탭 다섯을 IndexedStack 으로 들고 있어서 앱을 켜는 순간 이 화면까지
  /// 함께 만들어진다. 그대로 두면 눈금판이 탭을 누르기도 전에 다 차 있으므로,
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

  void _openCloset() {
    Navigator.push(
      context,
      TossPageRoute(builder: (_) => const CosmeticClosetScreen()),
    );
  }

  void _openMissions() {
    Navigator.push(
      context,
      TossPageRoute(builder: (_) => const MissionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final missionProvider = Provider.of<MissionProvider>(context);
    _syncVisitSequence(
      Provider.of<ScreenIndexProvider>(context).screenIndex,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MotionReplayScope(
        token: _visitSequence,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 무대가 남는 높이를 전부 가져간다. 아래 둘은 필요한 만큼만 쓰고,
            // 글자를 키운 기기에서 아래가 두꺼워지면 개구리가 그만큼 작아진다.
            // 넘치는 쪽이 아니라 개구리가 양보하는 쪽이 맞다.
            Expanded(
              child: _CharacterStage(
                key: widget.tutorialTargets?.levelCardKey,
                themeProvider: themeProvider,
              ),
            ),
            SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  // 태블릿에서 스탯창이 끝없이 넓어지지 않게 가운데로 모은다.
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.lg,
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                    ),
                    child: AppearTransition(
                      delay: AppMotion.stagger * 5,
                      child: _ActionRow(
                        color: themeProvider.primaryColor,
                        missionDone: missionProvider.dailyCompletedCount,
                        missionTotal: missionProvider.dailyTotalCount,
                        onMissionTap: _openMissions,
                        onClosetTap: _openCloset,
                      ),
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
  final ThemeHandler themeProvider;

  const _CharacterStage({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final color = themeProvider.primaryColor;
    final userInfo = Provider.of<UserProvider>(context).userInfoModel;
    // LayoutBuilder 안에서는 watch 가 듣지 않는다. 그 바깥에서 받는다.
    final cosmetic = context.watch<CosmeticProvider>();

    // 꾸미기 화면의 디버그 패널에서 총 학습 레벨을 옮기면 이 이름표도 같이
    // 움직인다. 스탯창이 능력치 넷에 대해 하는 것과 같은 규칙이다. 두 화면이
    // 같은 레벨을 다르게 말하면 어느 쪽이 진짜인지 알 수 없고, 무엇보다
    // Lv.16~20 에서만 열리는 것들(랜턴 · 눈꽃 뱃지 · 왕관 · 학사 세트)을
    // 시안에서 확인할 길이 없어진다. 한 번도 안 옮겼으면 서버 값 그대로다.
    final mockLevel = kDebugMode && cosmetic.levelsTouched
        ? cosmetic.levels.totalStudy
        : null;

    final level = mockLevel ?? userInfo?.totalStudyLevel ?? 0;
    final threshold = mockLevel != null
        ? _mockThreshold(mockLevel)
        : (userInfo?.totalStudyNextLevelThreshold ?? 40);
    final point = mockLevel != null
        ? _mockPoint(mockLevel)
        : (userInfo?.totalStudyCurrentPoint ?? 0);
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
        // 무대가 아래 스탯창에서 살짝 떠 보이게 한다. 카드가 아니라 장면이라는
        // 신호라서 테마색 그림자를 옅게 쓴다.
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // 배경 파츠가 무대 모서리를 넘지 않게, 그리고 개구리 빛무리가 좌우로
      // 새 나가게 한꺼번에 잘라 낸다. 무대 자체가 그릇이므로 개구리는 제
      // 액자를 따로 가질 필요가 없다.
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xlarge + 8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CosmeticStageGround(
              backdrop: cosmetic.stageBackdrop,
              color: color,
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: Column(
                  children: [
                    // 성장 카드만 좌우 여백과 폭 제한을 쓴다. 개구리는 무대를
                    // 끝까지 쓴다.
                    Center(
                      child: ConstrainedBox(
                        // 태블릿에서 카드가 끝없이 넓어지지 않게 모은다.
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenHorizontal,
                          ),
                          child: AppearTransition(
                            delay: AppMotion.stagger * 2,
                            child: _buildGrowthCard(
                              level: level,
                              point: point,
                              threshold: threshold,
                              progress: progress,
                              color: color,
                              userInfo: userInfo,
                              // 꾸미기 화면의 디버그 패널에서 레벨을 옮기면
                              // 눈금판도 같이 움직인다. 한 번도 안 옮겼으면
                              // 서버가 준 진짜 레벨을 그대로 보여 준다.
                              levelOverrides:
                                  kDebugMode && cosmetic.levelsTouched
                                      ? cosmetic.levels
                                      : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: LayoutBuilder(
                        // 개구리는 무대 **바닥에** 선다. 가운데에 띄워 두면
                        // 발밑에 빈 면이 한 뼘 남아서, 배경을 걸쳤을 때는
                        // 지면에서 떠 보이고 안 걸쳤을 때는 그 자리가 아무
                        // 역할도 없는 빈 테마색으로 남는다.
                        builder: (context, constraints) => OverflowBox(
                          // 빛무리가 무대 폭을 살짝 넘는다. 가장자리로 갈수록
                          // 투명해지는 빛이라 잘려도 티가 안 나고, 그만큼
                          // 개구리를 크게 그릴 수 있다.
                          maxWidth: double.infinity,
                          // 위에서 내려오는 것은 꽉 찬 제약이다. 아래 한계를
                          // 0 으로 풀지 않으면 개구리 상자가 남는 높이만큼
                          // 늘어나 버리고, 그러면 아래에 붙이라는 말이 아무
                          // 일도 하지 않는다.
                          minWidth: 0,
                          minHeight: 0,
                          alignment: Alignment.bottomCenter,
                          child: CosmeticStageFrog(
                            // 배경 한 장은 무대가 대신 그린다. 여기 남는 것은
                            // 개구리 몸에 맞춰 그려진 것들뿐이다.
                            layers: cosmetic.layersOnStage,
                            size: _frogSizeFor(constraints),
                            color: color,
                            // 갈아입기는 꾸미기 화면에서 한다. 여기서는 들썩일
                            // 일이 없다.
                            equipTick: 0,
                            // 꾸미러 가는 문은 아래 버튼이 맡는다. 개구리는
                            // 다시 한마디 하는 자리로 돌아왔다.
                            showEncouragement: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **성장 카드.** 총 학습 한 줄과 능력치 눈금판 넷이 한 카드에 들어간다.
  ///
  /// 둘을 한 덩어리로 묶은 이유는 둘 다 "내가 얼마나 자랐나" 하나에 답하는
  /// 값이기 때문이다. 총 학습이 개구리 위, 능력치 넷이 개구리 아래에 있던
  /// 동안에는 한 가지를 알려고 눈이 화면을 위아래로 오가야 했다. 카드를 둘로
  /// 나란히 놓지 않은 것도 같은 이유다. 카드가 둘이면 서로 다른 것을 말하는
  /// 것처럼 갈라져 보이고, 테두리와 안쪽 여백이 두 겹이라 세로도 그만큼 더
  /// 먹어 개구리가 작아진다. 사이는 옅은 선 하나로만 가른다.
  ///
  /// **총 학습이 위다.** 넷을 합산해 오르는 값이라 위계가 그렇고, 글자도 한
  /// 치수 크다([GrowthType.totalLevel]).
  ///
  /// 총 학습 줄은 [GrowthType] 의 세 층을 그대로 따른다. 왼쪽에 `[아이콘]
  /// 총 학습` 이름표와 `Lv.11` 값이 붙어 한 문장으로 읽히고, 진행도는 오른쪽
  /// 끝에 앉는다. 막대는 그 아래 칸 전체를 가로지르므로 **이름표는 막대의
  /// 왼쪽 끝과, 진행도는 오른쪽 끝과 맞물린다.** 눈금판 넷이 `이름표 → 값 →
  /// 진행도` 를 위에서 아래로 쌓는 것을, 자리가 가로로 긴 여기서는 옆으로 편
  /// 것이다.
  ///
  /// 예전에는 이 줄 안에서만 규칙이 셋이었다. 이름표는 값 왼쪽인데 `다음
  /// 레벨까지` 는 수치 위였고, 레벨은 15px 테마색인데 경험치는 12px 테마색,
  /// 두 덩어리가 한 줄을 반씩 나눠 쓰느라 막대는 오른쪽 절반에만 있었다.
  /// 규칙을 하나로 줄이고 막대를 칸 전체로 넓혔다.
  ///
  /// 글자를 키운 기기에서는 한 줄이 칸보다 넓어진다. 이름표와 값은 붙어 있어야
  /// 한 문장으로 읽히므로 **둘을 함께** 줄이고, 진행도는 따로 줄인다.
  Widget _buildGrowthCard({
    required int level,
    required int point,
    required int threshold,
    required double progress,
    required Color color,
    required UserInfoModel? userInfo,
    required CosmeticAbilityLevels? levelOverrides,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 이름도 아이콘도 꾸미기 화면의 잠금 배지가 쓰는 것과
                      // 같은 것을 가져온다. 같은 레벨을 두 화면이 다른 말로
                      // 부르면 그 말이 정보를 잃는다.
                      GrowthLabel(
                        icon: CosmeticAbilityStyle.iconOf(null),
                        text: CosmeticAbilityStyle.labelOf(null),
                        color: color,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AnimatedCountText(
                        value: level,
                        formatter: GrowthType.level,
                        fontSize: GrowthType.totalLevel,
                        fontFamily: GrowthType.valueFamily,
                        color: color,
                        height: GrowthType.lineHeight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: GrowthMeterText(current: point, goal: threshold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedLinearGauge(
            value: progress,
            color: color,
            // 이름표 바탕이 흰색이라 회색 트랙은 잘 안 보인다. 같은 테마색을
            // 옅게 깔아 파인 자리로 만든다.
            backgroundColor: color.withValues(alpha: 0.18),
            height: 8,
            borderRadius: AppRadius.full,
          ),
          const SizedBox(height: AppSpacing.md),
          // 총 학습과 능력치 넷 사이를 가르는 선. 카드를 둘로 쪼개는 대신
          // 머리카락 한 올만큼만 긋는다. 같은 카드에 있지만 위와 아래가
          // 다른 층이라는 것만 말하면 된다.
          Container(height: 1, color: color.withValues(alpha: 0.12)),
          const SizedBox(height: AppSpacing.md),
          AbilityStatPanel(
            userInfo: userInfo,
            levelOverrides: levelOverrides,
            framed: false,
          ),
        ],
      ),
    );
  }

  /// **시안 전용.** 그 총 학습 레벨에서 다음 레벨까지 필요한 경험치.
  ///
  /// 백엔드가 확정한 식이 `40 × 레벨` 이고 레벨 상한은
  /// [CosmeticAbilityLevels.maxTotalStudy] 다. **서버가 붙으면 서버가 내려준
  /// `totalStudyNextLevelThreshold` 가 이긴다.** 여기 있는 것은 디버그 패널로
  /// 레벨을 옮겨 볼 때 막대가 빈 채로 남지 않게 하려는 더미일 뿐이다.
  static int _mockThreshold(int level) => 40 * level;

  /// **시안 전용.** 그 레벨에서 지금까지 모은 경험치.
  ///
  /// 레벨을 옮길 때마다 막대가 다르게 차야 게이지가 어떻게 보이는지 한 번에
  /// 훑을 수 있다. 5분의 1씩 네 칸을 돈다. 끝까지 올라간 뒤에는 더 갈 곳이
  /// 없으니 꽉 채운다. 이것도 서버가 붙으면 `totalStudyCurrentPoint` 가 이긴다.
  static int _mockPoint(int level) {
    final threshold = _mockThreshold(level);
    if (level >= CosmeticAbilityLevels.maxTotalStudy) return threshold;
    return (threshold * ((level % 4) + 1) / 5).round();
  }

  /// 개구리 한 변의 길이. 남은 자리에 들어가는 만큼 크게 그린다.
  ///
  /// [CosmeticStageFrog] 는 빛무리와 바닥 그림자 때문에 한 변보다 가로로
  /// 1.18배, 세로로 1.04배 넓게 자리를 쓴다.
  ///
  /// **가로는 그 몫을 다 빼지 않는다.** 1.18 을 그대로 빼면 무대 폭의 85%
  /// 까지만 쓸 수 있어서 개구리가 이 탭의 주인공치고 작았다. 빛무리는
  /// 가장자리로 갈수록 투명해지는 원이라 무대 밖으로 조금 새어 나가도 눈에
  /// 띄지 않는다. 1.04 만 빼고 나머지는 무대가 잘라 낸다.
  ///
  /// **세로는 다 뺀다.** 바닥 그림자는 아래로 실제로 그려지는 것이라, 그 몫을
  /// 안 빼면 개구리가 성장 카드를 밀어 올린다. 아래 한계를 두지 않는 것도 같은
  /// 이유다. 글자를 아주 크게 키우면 개구리가 작아질지언정 화면이 깨지면 안 된다.
  ///
  /// 위 한계는 파츠 원본의 한 변이다. 그보다 크게 그려 봐야 뭉갠다.
  double _frogSizeFor(BoxConstraints constraints) {
    final byWidth = constraints.maxWidth / 1.04;
    final byHeight = constraints.maxHeight / 1.04;
    final smaller = byWidth < byHeight ? byWidth : byHeight;
    return smaller.clamp(0.0, _frogMaxSize);
  }

  /// 파츠 그림 원본의 한 변.
  static const double _frogMaxSize = 512.0;
}

/// 미션과 꾸미기로 가는 버튼 두 개.
///
/// 예전에는 미션 목록이 이 탭에 통째로 붙어 있었고 꾸미기는 무대 구석의 작은
/// 칩이었다. 둘 다 같은 무게의 버튼으로 내려놓는다. 꾸미기 쪽만 채운 버튼인
/// 것은 이 탭이 옷장이라서다. 여기서 가장 하고 싶은 일이 갈아입기다.
class _ActionRow extends StatelessWidget {
  final Color color;
  final int missionDone;
  final int missionTotal;
  final VoidCallback onMissionTap;
  final VoidCallback onClosetTap;

  const _ActionRow({
    required this.color,
    required this.missionDone,
    required this.missionTotal,
    required this.onMissionTap,
    required this.onClosetTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.flag_rounded,
            label: '미션',
            // 오늘 몇 개를 했는지는 여기서만 말한다. 버튼에 숫자가 붙어 있으면
            // 목록을 걷어 내고도 오늘 할 일이 남았는지 알 수 있다.
            badge: missionTotal > 0 ? '$missionDone / $missionTotal' : null,
            filled: false,
            color: color,
            onTap: onMissionTap,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionButton(
            icon: Icons.checkroom_rounded,
            label: '꾸미기',
            filled: true,
            color: color,
            onTap: onClosetTap,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  /// 버튼 오른쪽에 붙는 작은 숫자. 없으면 안 붙는다.
  final String? badge;

  /// 테마색으로 채울지. false 면 흰 바탕에 테마색 테두리다.
  final bool filled;

  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : color;

    return PressableScale(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: filled ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border:
              filled ? null : Border.all(color: color.withValues(alpha: 0.28)),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        // 글자를 키운 기기에서 아이콘과 글자가 버튼 폭을 넘는다. 넘치게 두는
        // 대신 줄여서 앉힌다.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: AppSpacing.sm),
              StandardText(
                text: label,
                fontSize: 14,
                color: foreground,
                fontWeight: FontWeight.w700,
                maxLines: 1,
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: filled
                        ? Colors.white.withValues(alpha: 0.24)
                        : color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: StandardText(
                    text: badge!,
                    fontSize: 11,
                    color: foreground,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
