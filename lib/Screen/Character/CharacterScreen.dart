import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import '../Cosmetic/Widget/CosmeticStage.dart';
import '../Mission/MissionScreen.dart';
import '../Tutorial/TutorialTargets.dart';
import 'Widget/AbilityStatPanel.dart';

/// 개구리와 성장을 한 화면에 몰아 주는 탭이다. 하단 탭에서는 `옷장`이다.
///
/// 화면은 **스크롤이 없다.** 셋이 위에서 아래로 붙박이로 앉는다.
///
/// - **무대**: 꾸민 개구리가 크게 서 있고, 총 학습 레벨이 그 위에, 다음
///   레벨까지의 경험치가 발치에 붙는다.
/// - **스탯창**([AbilityStatPanel]): 능력치 넷의 레벨과 남은 경험치.
/// - **버튼 둘**: 미션과 꾸미기.
///
/// 원래는 무대 아래에 오늘의 미션 목록이 스크롤로 붙어 있었고 능력치 넉 줄은
/// 그 아래에 있었다. 경험치를 보려면 매번 스크롤을 내려야 했다. 이 탭에서
/// 가장 자주 궁금한 것이 "내가 얼마나 자랐나"인데 그게 화면 밖에 있었다는
/// 뜻이다. 목록을 버튼 하나로 접고, 그 자리를 능력치에 내줬다. 미션을 더 볼
/// 사람은 미션 버튼으로 넘어간다.
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
    final userInfo = Provider.of<UserProvider>(context).userInfoModel;
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppearTransition(
                          delay: AppMotion.stagger * 2,
                          child: AbilityStatPanel(userInfo: userInfo),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppearTransition(
                          delay: AppMotion.stagger * 5,
                          child: _ActionRow(
                            color: themeProvider.primaryColor,
                            missionDone: missionProvider.dailyCompletedCount,
                            missionTotal: missionProvider.dailyTotalCount,
                            onMissionTap: _openMissions,
                            onClosetTap: _openCloset,
                          ),
                        ),
                      ],
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
      child: SafeArea(
        bottom: false,
        child: Center(
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
                children: [
                  _buildLevelChip(level, color),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Center(
                        child: CosmeticStageFrog(
                          layers: cosmetic.layers,
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
                  _buildExpBar(point, threshold, progress, color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 총 학습 레벨. 개구리 머리 위에 다는 이름표다.
  ///
  /// 능력치 넷은 아래 스탯창이 맡는다. 여기 있는 것은 그 넷을 합친 값
  /// 하나뿐이라, 가운데에 하나만 놓아 무대의 제목처럼 읽히게 한다.
  Widget _buildLevelChip(int level, Color color) {
    return Center(
      // 글자를 키운 기기에서 칩이 남은 폭보다 길어진다. 넘치게 두는 대신
      // 줄여서 앉힌다.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
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
              const StandardText(
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
        // 글자를 키운 작은 폰에서는 이 한 줄이 화면 폭을 넘는다. 양쪽 끝에
        // 붙여 두는 모양은 지키면서 각자 줄어들게 한다.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: StandardText(
                  text: '다음 레벨까지',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: AnimatedCountText(
                  value: point,
                  formatter: (value) => '${value.round()} / $threshold XP',
                  fontSize: 12,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 개구리 한 변의 길이. 남은 자리에 들어가는 만큼만 크게 그린다.
  ///
  /// [CosmeticStageFrog] 는 빛무리와 바닥 그림자 때문에 한 변보다 가로로
  /// 1.18배, 세로로 1.04배 넓게 자리를 쓴다. 그 몫까지 빼고 계산해야 무대가
  /// 좁아졌을 때 넘치지 않는다. 아래 한계를 두지 않는 것도 같은 이유다.
  /// 글자를 아주 크게 키우면 개구리가 작아질지언정 화면이 깨지면 안 된다.
  double _frogSizeFor(BoxConstraints constraints) {
    final byWidth = constraints.maxWidth / 1.18;
    final byHeight = constraints.maxHeight / 1.04;
    final smaller = byWidth < byHeight ? byWidth : byHeight;
    return smaller.clamp(0.0, 300.0);
  }
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
