import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Dialog/ThemeDialog.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossDialog.dart';
import '../../Model/User/UserInfoModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/Theme/ThemeLockManager.dart';
import 'LegacyFrogAsset.dart';

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

/// [before] 에 없고 [after] 에 있는 테마 번호들. 없으면 빈 목록이다.
///
/// 번호를 그대로 돌려준다. 화면이 색과 이름을 함께 보여 주기 때문이다.
List<int> newlyUnlockedThemeIndexes(Set<int> before, Set<int> after) {
  final added = after.difference(before).toList()..sort();
  return [
    for (final index in added)
      if (index >= 0 && index < ThemeLockManager.themeNames.length) index,
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

  /// 이 레벨업 직전의 종합 레벨. 개구리가 실제로 바뀌는지 판단하는 데 쓴다.
  int? previousLevel,
  List<int> unlockedThemeIndexes = const [],
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
      previousLevel: previousLevel,
      unlockedThemeIndexes: unlockedThemeIndexes,
    ),
    // 빌더 안에서 CurvedAnimation 을 만들면 프레임마다 새로 생긴다.
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _MissionLevelUpView extends StatefulWidget {
  final int? level;
  final int? previousLevel;
  final List<int> unlockedThemeIndexes;

  const _MissionLevelUpView({
    this.level,
    this.previousLevel,
    this.unlockedThemeIndexes = const [],
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

  /// 개구리를 감싸고 밖으로 번지는 파문.
  ///
  /// 예전에는 광선이 돌았는데 풍차처럼 보였다. **회전을 쓰지 않는다.** 돌리면
  /// 풍차나 로딩 스피너가 된다. 축하는 크고 화려한 것이 아니라 부드럽고 밝은
  /// 쪽이다. 두 번만 번지고 멎는다.
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  /// 빌더 안에서 만들면 프레임마다 새로 생기고 리스너가 쌓인다.
  late final Animation<double> _entered = CurvedAnimation(
    parent: _enter,
    curve: AppMotion.emphasized,
  );

  @override
  void initState() {
    super.initState();
    _enter.forward();
    _ripple.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _ripple.dispose();
    super.dispose();
  }

  int get _level => widget.level ?? 1;

  int get _previousLevel =>
      widget.previousLevel ?? (_level > 1 ? _level - 1 : _level);

  /// 이번 레벨업으로 개구리 그림이 실제로 바뀌는지.
  ///
  /// 에셋이 홀수 여덟 장이라 Lv.7 에서 Lv.8 로 올라도 그림은 그대로다. 그때
  /// 진화 연출을 하면 같은 그림 두 장을 놓고 바뀌었다고 하는 셈이라, 숫자와
  /// 게이지만 조용히 보여 준다.
  bool get _evolves => LegacyFrogAsset.evolvesBetween(_previousLevel, _level);

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
                  if (widget.unlockedThemeIndexes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildUnlocked(themeProvider.primaryColor),
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

        final frog = _EvolvingFrog(
          previousLevel: _previousLevel,
          level: _level,
          size: size * 0.72,
          progress: _enter,
          evolves: _evolves && !reduced,
        );

        // 뒤에서 부드럽게 퍼지는 원형 빛. 회전하지 않는다.
        final glow = SizedBox.square(
          dimension: size * 1.5,
          child: AnimatedBuilder(
            animation: _enter,
            builder: (context, _) {
              final t = _entered.value;
              return Opacity(
                opacity: reduced ? 1 : t,
                child: Transform.scale(
                  scale: reduced ? 1 : 0.7 + 0.3 * t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primary.withValues(alpha: 0.30),
                          primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );

        // 얇은 원 두 개가 밖으로 번지며 사라진다.
        final ripples = reduced
            ? const SizedBox.shrink()
            : SizedBox.square(
                dimension: size * 1.5,
                child: AnimatedBuilder(
                  animation: _ripple,
                  builder: (context, _) => CustomPaint(
                    painter: _RipplePainter(
                      progress: _ripple.value,
                      color: primary,
                    ),
                  ),
                ),
              );

        final content = Stack(
          alignment: Alignment.center,
          children: [glow, ripples, frog],
        );

        if (reduced) return content;

        return AnimatedBuilder(
          animation: _entered,
          builder: (context, child) => Transform.scale(
            scale: 0.6 + 0.4 * _entered.value,
            child: child,
          ),
          child: content,
        );
      },
    );
  }

  /// `Lv.1 → Lv.2`. 새 레벨만 숫자가 올라간다.
  ///
  /// 이전 레벨은 받기 직전에 들고 온 값이다. 한 번에 두 레벨이 오르면 글자와
  /// 개구리가 서로 다른 말을 하게 되므로 여기서도 같은 값을 쓴다.
  Widget _buildLevelRow(Color primary, bool reduced) {
    final previous = _previousLevel;

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

  /// 이번에 열린 테마. 없으면 이 영역은 통째로 없다.
  ///
  /// 색 동그라미와 이름을 같이 둔다. 이름만 있으면 무슨 색인지 모르고, 색만
  /// 있으면 무엇을 얻었는지 모른다.
  Widget _buildUnlocked(Color primary) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StandardText(
            text: '새 테마가 열렸어요',
            fontSize: 13,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              for (final index in widget.unlockedThemeIndexes)
                _UnlockedTheme(index: index),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PressableScale(
            onTap: _openThemeDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StandardText(
                    text: '바로 적용해보기',
                    fontSize: 13,
                    color: primary,
                    maxLines: 1,
                  ),
                  Icon(Icons.chevron_right, size: 16, color: primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 테마 고르는 창을 띄운다. 레벨업 화면은 닫고 넘어간다.
  void _openThemeDialog() {
    final navigator = Navigator.of(context);
    navigator.pop();
    showTossDialog(
      context: navigator.context,
      builder: (_) => ThemeDialog(),
    );
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

/// 개구리를 감싸고 밖으로 번지는 얇은 원들이다.
///
/// 회전이 없다. 커지면서 옅어지기만 한다.
class _RipplePainter extends CustomPainter {
  /// 0 에서 1. 번져 나간 정도.
  final double progress;
  final Color color;

  const _RipplePainter({required this.progress, required this.color});

  /// 두 원이 시차를 두고 번진다. 하나씩이면 심심하고 셋이면 어수선하다.
  static const List<double> _delays = [0.0, 0.35];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;

    for (final delay in _delays) {
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        // 번질수록 옅어진다.
        ..color = color.withValues(alpha: 0.35 * (1 - t));

      canvas.drawCircle(center, maxRadius * (0.5 + 0.5 * t), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// 레벨업 전후의 개구리를 이어 보여 준다.
///
/// 이전 개구리가 빛에 감싸여 하얗게 지워지고, 그 자리에서 새 개구리가 튀어
/// 오른다. 포켓몬 진화처럼 **무엇이 무엇으로 바뀌었는지**가 보여야 한다.
///
/// [evolves] 가 false 면 그냥 지금 개구리만 그린다. 에셋이 홀수 여덟 장이라
/// 레벨이 올라도 그림이 그대로인 구간이 있는데, 그때 같은 그림 두 장을 놓고
/// 바뀌었다고 하면 안 된다.
class _EvolvingFrog extends StatelessWidget {
  final int previousLevel;
  final int level;
  final double size;
  final Animation<double> progress;
  final bool evolves;

  const _EvolvingFrog({
    required this.previousLevel,
    required this.level,
    required this.size,
    required this.progress,
    required this.evolves,
  });

  /// 언제 무엇을 보여 줄지.
  ///
  /// 겹치는 구간이 있어야 한 장이 사라진 빈 화면이 생기지 않는다. 이전
  /// 개구리가 하얗게 타오르는 동안 새 개구리가 그 안에서 올라온다.
  static const double _fadeOutEnd = 0.55;
  static const double _fadeInStart = 0.35;

  @override
  Widget build(BuildContext context) {
    if (!evolves) {
      return _frogImage(LegacyFrogAsset.pathOf(level), size);
    }

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value;

        // 1) 이전 개구리가 하얗게 타오르며 사라진다.
        final outT = (t / _fadeOutEnd).clamp(0.0, 1.0);
        // 2) 새 개구리가 그 자리에서 커지며 나타난다.
        final inT = ((t - _fadeInStart) / (1 - _fadeInStart)).clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            if (outT < 1)
              Opacity(
                opacity: 1 - outT,
                child: ColorFiltered(
                  // 실루엣이 되었다가 사라진다.
                  colorFilter: ColorFilter.mode(
                    Colors.white.withValues(alpha: outT),
                    BlendMode.srcATop,
                  ),
                  child: Transform.scale(
                    scale: 1 + 0.12 * outT,
                    child: _frogImage(
                      LegacyFrogAsset.pathOf(previousLevel),
                      size,
                    ),
                  ),
                ),
              ),
            if (inT > 0)
              Opacity(
                opacity: inT,
                child: Transform.scale(
                  // 나타나면서 한 번 크게 튀어오른다.
                  scale: _popScale(inT),
                  child: _frogImage(LegacyFrogAsset.pathOf(level), size),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 0.8 에서 1.12 까지 넘겼다가 1 로 돌아온다.
  static double _popScale(double t) {
    if (t < 0.6) return 0.8 + (1.12 - 0.8) * (t / 0.6);
    return 1.12 - 0.12 * ((t - 0.6) / 0.4);
  }

  static Widget _frogImage(String assetPath, double size) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox.square(dimension: size),
    );
  }
}

/// 열린 테마 하나. 색 동그라미와 이름이다.
class _UnlockedTheme extends StatelessWidget {
  final int index;

  const _UnlockedTheme({required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: ThemeLockManager.getThemeColor(index),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        StandardText(
          text: ThemeLockManager.getThemeName(index),
          fontSize: 11,
          color: AppColors.textSecondary,
          maxLines: 1,
        ),
      ],
    );
  }
}
