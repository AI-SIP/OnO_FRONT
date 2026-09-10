import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppRewardColors.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Model/User/UserInfoModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/Theme/ThemeLockManager.dart';
import '../User/Widget/FrogCharacter.dart';

/// 레벨대별 한 줄이다.
///
/// 개구리가 알에서 다 자란 개구리가 되는 서사에 맞춘 말이다. 문구를 고칠 일이
/// 생기면 여기만 고치면 된다.
const Map<int, String> missionLevelPhrases = <int, String>{
  2: '이제 막 시작이에요',
  3: '조금씩 자라고 있어요',
  4: '제법 모양이 잡혔어요',
  5: '꾸준함이 보여요',
  6: '습관이 붙었어요',
  7: '이제 능숙해졌어요',
  8: '실력이 붙었어요',
  9: '믿음직해졌어요',
  10: '한참 올라왔어요',
  11: '눈에 띄게 늘었어요',
  12: '대단해요',
  13: '손꼽히는 실력이에요',
  14: '정점이 보여요',
  15: '최고 레벨이에요',
};

/// [level] 에 맞는 문구. 표를 벗어나면 마지막 문구로 떨어진다.
String missionLevelPhraseOf(int level) {
  final phrase = missionLevelPhrases[level];
  if (phrase != null) return phrase;
  if (level < 2) return missionLevelPhrases[2]!;
  return missionLevelPhrases[15]!;
}

/// 지금 열려 있는 테마의 번호들.
///
/// 서버가 해금 정보를 따로 내려주지 않아서 [ThemeLockManager] 의 로컬 계산을
/// 쓴다. 받기 전후로 한 번씩 구해 차이를 보면 이번에 열린 것을 알 수 있다.
Set<int> unlockedThemeIndexes(UserInfoModel? userInfo) {
  return <int>{
    for (var i = 0; i < ThemeLockManager.themeNames.length; i++)
      if (ThemeLockManager.isThemeUnlocked(i, userInfo)) i,
  };
}

/// [before] 에 없고 [after] 에 있는 테마의 이름들. 없으면 빈 목록이다.
List<String> newlyUnlockedThemeNames(Set<int> before, Set<int> after) {
  final added = after.difference(before).toList()..sort();
  return [
    for (final index in added)
      if (index < ThemeLockManager.themeNames.length)
        ThemeLockManager.themeNames[index],
  ];
}

/// 레벨이 올랐을 때 화면 전체를 쓰는 순간이다.
///
/// 전에는 작은 다이얼로그 한 장이었다. 레벨업은 이 앱에서 가장 드물게 오는
/// 사건인데 그것이 확인 버튼 달린 상자로 끝나면 아무 일도 아닌 것이 된다.
/// 배경이 어두워지고, 개구리가 커지고, 숫자가 올라가고, 뒤에서 빛이 돈다.
Future<void> showMissionLevelUp(
  BuildContext context, {
  int? level,
  List<String> unlockedThemeNames = const [],
}) {
  AppHaptic.primary();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '레벨업',
    // 검정 스크림을 쓰지 않는다. 어두우면 무겁다. 축하는 어둡게 해서가 아니라
    // 빛과 움직임으로 낸다.
    barrierColor: Colors.white.withValues(alpha: 0.88),
    transitionDuration: AppMotion.page,
    pageBuilder: (context, animation, secondaryAnimation) =>
        _MissionLevelUpView(
      level: level,
      unlockedThemeNames: unlockedThemeNames,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

class _MissionLevelUpView extends StatefulWidget {
  final int? level;
  final List<String> unlockedThemeNames;

  const _MissionLevelUpView({
    this.level,
    this.unlockedThemeNames = const [],
  });

  @override
  State<_MissionLevelUpView> createState() => _MissionLevelUpViewState();
}

class _MissionLevelUpViewState extends State<_MissionLevelUpView>
    with TickerProviderStateMixin {
  /// 개구리가 커지며 자리를 잡는다.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  /// 뒤에서 도는 빛. 한 바퀴만 돈다.
  ///
  /// 끝없이 돌리지 않는 이유가 있다. 사라지지 않는 애니메이션은 화면이 언제
  /// 조용해지는지를 없애고, 테스트에서도 영영 안정되지 않는다.
  late final AnimationController _rays = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    _enter.forward();
    _rays.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _rays.dispose();
    super.dispose();
  }

  int get _level => widget.level ?? 1;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final reduced = AppMotion.isReduced(context);

    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        // 개구리 뒤에서 테마색 빛이 퍼진다. 밝은 바탕 위의 빛이라 눈이 부시지
        // 않으면서도 평소 화면과 확실히 다르다.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 0.9,
            colors: [
              themeProvider.primaryColor.withValues(alpha: 0.20),
              themeProvider.primaryColor.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFrog(themeProvider.primaryColor, reduced),
                  const SizedBox(height: AppSpacing.xl),
                  // 제목을 따로 두지 않는다. `Lv.1 → Lv.2` 가 이미 그 말이다.
                  _buildLevelRow(themeProvider.primaryColor, reduced),
                  const SizedBox(height: AppSpacing.md),
                  StandardText(
                    text: missionLevelPhraseOf(_level),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  if (widget.unlockedThemeNames.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildUnlocked(),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildConfirm(themeProvider.primaryColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrog(Color primary, bool reduced) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 폰에서는 화면 폭의 절반, 태블릿에서는 그보다 덜 키운다.
        final size = math.min(
          math.max(constraints.maxWidth * 0.5, 140.0),
          220.0,
        );

        final frog = FrogCharacter(level: _level, size: size * 0.72);

        final rays = SizedBox.square(
          dimension: size,
          child: AnimatedBuilder(
            animation: _rays,
            builder: (context, _) => CustomPaint(
              painter: _RayPainter(
                color: AppRewardColors.coin,
                accent: primary,
                turns: reduced ? 0 : _rays.value,
              ),
            ),
          ),
        );

        final content = Stack(
          alignment: Alignment.center,
          children: [rays, frog],
        );

        if (reduced) return content;

        return AnimatedBuilder(
          animation: _enter,
          builder: (context, child) => Transform.scale(
            scale: Tween<double>(begin: 0.6, end: 1.0)
                .chain(CurveTween(curve: AppMotion.emphasized))
                .evaluate(_enter),
            child: child,
          ),
          child: content,
        );
      },
    );
  }

  /// `Lv.1 → Lv.2`. 새 레벨만 숫자가 올라간다.
  Widget _buildLevelRow(Color primary, bool reduced) {
    final previous = _level > 1 ? _level - 1 : _level;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StandardText(
          text: 'Lv.$previous',
          fontSize: 16,
          color: AppColors.textTertiary,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(
            Icons.arrow_forward,
            size: 18,
            color: AppColors.textTertiary,
          ),
        ),
        StandardText(
          text: 'Lv.',
          fontSize: 26,
          color: primary,
        ),
        if (reduced)
          StandardText(
            text: '$_level',
            fontSize: 26,
            color: primary,
          )
        else
          AnimatedCountText(
            value: _level,
            fontSize: 26,
            color: primary,
            delay: const Duration(milliseconds: 260),
          ),
      ],
    );
  }

  /// 이번에 열린 것. 없으면 이 영역은 통째로 없다.
  Widget _buildUnlocked() {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_open,
            size: 16,
            color: AppRewardColors.onCoin,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: StandardText(
              text: _unlockedLabel,
              fontSize: 13,
              color: AppRewardColors.onCoin,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  String get _unlockedLabel {
    final names = widget.unlockedThemeNames;
    final head = '새 테마 「${names.first}」';
    if (names.length == 1) return '$head 해금';
    return '$head 외 ${names.length - 1}개 해금';
  }

  Widget _buildConfirm(Color primary) {
    return PressableScale(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const StandardText(
          text: '계속하기',
          fontSize: 15,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 개구리 뒤에서 도는 빛줄기다.
class _RayPainter extends CustomPainter {
  final Color color;
  final Color accent;

  /// 0 에서 1 사이. 한 바퀴를 얼마나 돌았는지.
  final double turns;

  const _RayPainter({
    required this.color,
    required this.accent,
    required this.turns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turns * 2 * math.pi);

    const count = 12;
    for (var i = 0; i < count; i++) {
      final paint = Paint()
        // 밝은 바탕이라 옅게 깐다. 진하면 종이에 그은 선처럼 보인다.
        ..color = (i.isEven ? color : accent).withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(radius * 1.5, -radius * 0.12)
        ..lineTo(radius * 1.5, radius * 0.12)
        ..close();

      canvas.save();
      canvas.rotate(i * 2 * math.pi / count);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RayPainter oldDelegate) =>
      oldDelegate.turns != turns ||
      oldDelegate.color != color ||
      oldDelegate.accent != accent;
}
