import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/User/UserInfoModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/AnimatedGauge.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/MotionReplayScope.dart';
import '../../Module/Motion/AppHaptic.dart';
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
      // 무대가 화면을 통째로 덮으므로 이 색은 무대가 그려지기 전 한 틱에만
      // 보인다. 그래도 비워 두면 그 한 틱이 검게 뜬다.
      backgroundColor: AppColors.background,
      body: MotionReplayScope(
        token: _visitSequence,
        child: _CharacterStage(
          key: widget.tutorialTargets?.levelCardKey,
          themeProvider: themeProvider,
          missionDone: missionProvider.dailyCompletedCount,
          missionTotal: missionProvider.dailyTotalCount,
          onMissionTap: _openMissions,
          onClosetTap: _openCloset,
        ),
      ),
    );
  }
}

/// 개구리가 서 있는 무대다. **이 탭의 화면 전체가 무대다.**
///
/// 예전에는 무대가 위쪽 덩어리였고 그 아래에 버튼 둘이 회색 바탕 위에 따로
/// 앉아 있었다. 배경 파츠가 개구리 발치에서 끊기고 아래 90px 남짓이 아무
/// 역할도 없는 연보라 빈 면으로 남았다. 무대를 화면 끝까지 늘리고 **성장
/// 카드와 버튼 둘을 그 위에 얹는다.** 셋 다 같은 장면 위에 떠 있는 것이 되고,
/// 배경 그림에서 보이는 세로도 그만큼 늘어난다.
///
/// 바탕은 [CosmeticStageGround] 가 그린다. 배경 파츠를 걸쳤으면 그것이
/// 화면을 채우고, 안 걸쳤으면 위가 밝고 아래로 갈수록 테마색이 도는
/// 그라데이션과 지평선이 보인다.
///
/// 금색 같은 별도의 장식색을 쓰지 않는다. 쓰는 색은 사용자가 테마에서 고른
/// 색 하나뿐이다. 그래야 이 화면만 앱에서 겉돌지 않는다.
class _CharacterStage extends StatelessWidget {
  final ThemeHandler themeProvider;

  final int missionDone;
  final int missionTotal;
  final VoidCallback onMissionTap;
  final VoidCallback onClosetTap;

  const _CharacterStage({
    super.key,
    required this.themeProvider,
    required this.missionDone,
    required this.missionTotal,
    required this.onMissionTap,
    required this.onClosetTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = themeProvider.primaryColor;
    final userInfo = Provider.of<UserProvider>(context).userInfoModel;
    // LayoutBuilder 안에서는 watch 가 듣지 않는다. 그 바깥에서 받는다.
    final cosmetic = context.watch<CosmeticProvider>();

    // 디버그 패널에서 옮겨 놓은 레벨은 여기서 따로 챙기지 않는다.
    // [UserProvider] 가 유저 정보를 내주는 자리에서 이미 갈아 끼운다. 그래야
    // 이 화면과 테마 다이얼로그와 마이페이지가 같은 값을 말한다.
    final level = userInfo?.totalStudyLevel ?? 0;
    final point = userInfo?.totalStudyCurrentPoint ?? 0;
    final threshold = userInfo?.totalStudyNextLevelThreshold ?? 40;
    final progress = threshold > 0 ? (point / threshold).clamp(0.0, 1.0) : 0.0;

    return DecoratedBox(
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
      ),
      // 개구리 빛무리가 좌우로 새 나가게 잘라 낸다. 모서리를 둥글리지 않는
      // 것은 무대가 이제 카드가 아니라 화면 그 자체이기 때문이다. 화면
      // 네 귀퉁이가 깎여 있으면 그 뒤에 또 무언가 있는 것처럼 보인다.
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CosmeticStageGround(
              backdrop: cosmetic.stageBackdrop,
              color: color,
            ),
            SafeArea(
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
                    const SizedBox(height: AppSpacing.md),
                    // 버튼도 무대 위에 얹힌다. 회색 바탕에 따로 앉아 있던
                    // 때에는 화면이 장면과 조작 판으로 갈라져 보였다.
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenHorizontal,
                          ),
                          child: AppearTransition(
                            delay: AppMotion.stagger * 5,
                            child: _ActionRow(
                              color: color,
                              missionDone: missionDone,
                              missionTotal: missionTotal,
                              onMissionTap: onMissionTap,
                              onClosetTap: onClosetTap,
                            ),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        // **살짝 비친다.** 불투명한 흰 판이면 배경 그림에 뚫린 구멍이 되고,
        // 카드가 무대 위에 놓인 것이 아니라 무대를 가린 것이 된다. 그렇다고
        // 많이 비치면 밤하늘 배경에서 글자가 안 읽힌다.
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadius.large),
        // 테두리는 테마색이 아니라 흰색이다. 어두운 배경에서 카드의 모서리를
        // 그어 주는 일만 하면 되고, 이 카드에 테마색을 한 겹 더 얹으면
        // 그러잖아도 색이 많은 자리가 더 시끄러워진다.
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        // 밝은 배경에서는 흰 카드가 배경에 묻힌다. 테두리 대신 이 그림자가
        // 그때 카드를 떼어 놓는다.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
                        // **여기만 색을 뺀다.** 능력치 넷은 서로를 구분해야
                        // 해서 색이 정보지만, 총 학습은 혼자라 색으로 가를
                        // 형제가 없다. 이 영역에서 가장 큰 글자여서 색이
                        // 없어도 가장 먼저 읽히고, 덜어 낸 색은 바로 아래
                        // 막대가 가져간다.
                        color: GrowthType.totalLevelColor,
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
          _GrowthGauge(progress: progress, color: color),
          const SizedBox(height: AppSpacing.md),
          // 총 학습과 능력치 넷 사이를 가르는 선. 카드를 둘로 쪼개는 대신
          // 머리카락 한 올만큼만 긋는다. 같은 카드에 있지만 위와 아래가
          // 다른 층이라는 것만 말하면 된다. 흰색인 것은 카드 테두리와 같은
          // 이유다. 이 카드에 테마색을 더 얹지 않는다.
          Container(height: 1, color: Colors.white.withValues(alpha: 0.75)),
          const SizedBox(height: AppSpacing.md),
          AbilityStatPanel(userInfo: userInfo, framed: false),
        ],
      ),
    );
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

/// 총 학습 경험치 막대다.
///
/// **이 영역에서 가장 중요한 값인데 제일 약해 보였다.** 8px 짜리 실선 한 줄은
/// 구분선과 구별되지 않아서, 얼마나 찼는지가 아니라 카드에 줄이 하나 그어져
/// 있는 것으로 읽혔다. 높이를 키우고 두 가지를 더한다.
///
/// - **광택**: 채운 부분 위쪽을 밝게 한다. 평평한 색면이 아니라 속이 찬
///   원기둥처럼 보여서 게임의 체력 막대에 가까워진다. 흰색을 섞어 밝히므로
///   화면에 없던 색이 새로 생기지 않는다.
/// - **머리**: 차오른 끝에 밝은 세로선을 세운다. 어디까지 왔는지가 한 점으로
///   짚인다. 능력치 고리도 같은 자리에 같은 표시를 한다.
///
/// 트랙은 흰색이다. 트랙까지 테마색이면 찬 곳과 안 찬 곳이 진하기 차이로만
/// 갈린다. **카드에서 테마색이 남는 곳은 채운 부분 하나뿐이다.**
class _GrowthGauge extends StatelessWidget {
  final double progress;
  final Color color;

  const _GrowthGauge({required this.progress, required this.color});

  /// 막대 높이.
  static const double _height = 14.0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.full);

    return AnimatedGaugeValue(
      value: progress.clamp(0.0, 1.0),
      builder: (context, current) => ClipRRect(
        borderRadius: radius,
        child: Container(
          height: _height,
          color: Colors.white.withValues(alpha: 0.80),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: current,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.alphaBlend(
                      Colors.white.withValues(alpha: 0.42),
                      color,
                    ),
                    color,
                  ],
                  stops: const [0.0, 0.62],
                ),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 3,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: radius,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 미션과 꾸미기로 가는 버튼 두 개.
///
/// 예전에는 미션 목록이 이 탭에 통째로 붙어 있었고 꾸미기는 무대 구석의 작은
/// 칩이었다. 둘 다 같은 무게의 버튼으로 내려놓는다.
///
/// **둘의 무게는 채움으로 가른다.** 꾸미기가 이 탭의 주 동작이라 테마색으로
/// 꽉 채우고, 미션은 흰 바탕에 테마색 글자다. 한때 둘 다 흰 바탕에 테두리
/// 진하기만 달리 했는데, 화면에서는 차이가 거의 안 보여서 둘 다 웹 폼의 보조
/// 버튼처럼 읽혔다. 색 덩어리 **하나**는 무겁지 않다. 무거웠던 것은 둘이었다.
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
            primary: false,
            color: color,
            onTap: onMissionTap,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionButton(
            icon: Icons.checkroom_rounded,
            label: '꾸미기',
            primary: true,
            color: color,
            onTap: onClosetTap,
          ),
        ),
      ],
    );
  }
}

/// 무대 위에 놓인 **게임 키** 한 개.
///
/// 배경 그림 위에 평평한 사각형을 얹으면 그림에 붙은 무늬인지 누를 수 있는
/// 것인지 알기 어렵다. 세 가지로 "누르는 물건"을 만든다.
///
/// 1. **옆면**: 윗면 아래에 진한 판을 한 장 깔아 위에서 내려다본 두께를
///    만든다. 흐림 없는 그림자로 흉내 낸 적이 있는데 화면에서 옅은 선 한 줄로
///    보여서 없는 것이나 마찬가지였다. 진짜 판을 깔고 [_depth] 만큼 내놓는다.
/// 2. **눌림**: 누르면 윗면이 그 두께만큼 **실제로 내려앉는다.** 크기만
///    줄이는 것과 다르게, 키가 바닥에 닿았다가 튀어 오르는 느낌이 난다.
///    "동작 줄이기"를 켠 기기에서는 움직이지 않는다.
/// 3. **모양**: 모서리를 완전히 둥글려 알약으로 만들고 아이콘을 글자보다 크게
///    키운다. 각진 사각형에 작은 아이콘은 어느 앱에나 있는 보조 버튼이다.
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;

  /// 버튼 오른쪽에 붙는 작은 숫자. 없으면 안 붙는다.
  final String? badge;

  /// 이 탭에서 먼저 누를 것인지.
  final bool primary;

  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  /// 옆면의 두께. 이만큼 내려앉는다.
  ///
  /// 4 로는 화면에서 안 보였다. 손가락 끝으로 눌렀을 때 눈에 띄려면 이 정도는
  /// 돼야 한다.
  static const double _depth = 7.0;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    AppHaptic.secondary();
    widget.onTap();
  }

  /// 옆면 색. 윗면보다 어두워야 두께로 읽힌다.
  ///
  /// 검정을 섞는다. 금색이나 다른 색을 섞으면 그 색이 어디서 왔는지 설명할 수
  /// 없고, 화면에 없던 색이 하나 더 생긴다.
  Color get _sideColor => widget.primary
      ? Color.lerp(widget.color, Colors.black, 0.34)!
      : Color.alphaBlend(
          widget.color.withValues(alpha: 0.55),
          Colors.white,
        );

  Color get _faceColor =>
      widget.primary ? widget.color : Colors.white.withValues(alpha: 0.95);

  Color get _foreground => widget.primary ? Colors.white : widget.color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.full);
    final reduced = AppMotion.isReduced(context);
    final sunk = _pressed && !reduced;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _handleTap,
        child: DecoratedBox(
          // 옆면. 윗면이 내려앉으면 이 판이 가려진다.
          decoration: BoxDecoration(
            color: _sideColor,
            borderRadius: radius,
            boxShadow: [
              // 바닥에서 떨어뜨린다. 밝은 배경에서 흰 윗면이 묻히지 않게
              // 하는 것도 이 한 겹이다.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AnimatedPadding(
            duration: reduced ? Duration.zero : AppMotion.press,
            curve: AppMotion.standard,
            padding: EdgeInsets.only(
              top: sunk ? _depth : 0,
              bottom: sunk ? 0 : _depth,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: _faceColor,
                borderRadius: radius,
                // 흰 윗면은 어두운 배경에서 저절로 떠 보이지만, 채운 윗면은
                // 옆면과 붙어 한 덩어리로 보인다. 위쪽에 밝은 선을 한 줄
                // 그어 빛을 받는 면이라는 것을 말한다.
                border: Border.all(
                  color: widget.primary
                      ? Colors.white.withValues(alpha: 0.34)
                      : widget.color.withValues(alpha: 0.32),
                  width: 1.2,
                ),
              ),
              // 글자를 키운 기기에서 아이콘과 글자가 버튼 폭을 넘는다. 넘치게
              // 두는 대신 줄여서 앉힌다.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 24, color: _foreground),
                    const SizedBox(width: AppSpacing.sm),
                    StandardText(
                      text: widget.label,
                      fontSize: 15,
                      color: _foreground,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                    ),
                    if (widget.badge != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _buildBadge(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 오늘 미션을 몇 개 했는지.
  ///
  /// 버튼 안에서 색이 꽉 찬 자리다. 회색으로 두면 숫자가 버튼에 얹힌 딱지처럼
  /// 따로 논다.
  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: widget.primary
            ? Colors.white.withValues(alpha: 0.26)
            : widget.color,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: StandardText(
        text: widget.badge!,
        fontSize: 12,
        color: widget.primary ? Colors.white : Colors.white,
        fontWeight: FontWeight.w700,
        maxLines: 1,
      ),
    );
  }
}
