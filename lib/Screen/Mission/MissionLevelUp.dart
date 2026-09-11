import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Cosmetic/CosmeticItemModel.dart';
import '../../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../../Model/User/UserInfoModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Dialog/ThemeDialog.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/AnimatedGauge.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossDialog.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/Theme/ThemeLockManager.dart';
import '../../Provider/CosmeticProvider.dart';
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

/// [from] 다음 레벨부터 [to] 까지 새로 열리는 치장 아이템을 순서대로 모은다.
///
/// 한 번에 두 레벨 넘게 오르는 일이 있어서 구간을 훑는다. Lv.13 에서 Lv.15 로
/// 뛰면 Lv.14 의 것과 Lv.15 의 것이 모두 이번에 열린 것이다.
///
/// [unlockedAt] 은 `CosmeticProvider.unlockedAt` 을 그대로 넘긴다. 프로바이더를
/// 직접 받지 않는 것은 이 계산만 따로 확인할 수 있게 하려는 것이다.
List<CosmeticItemModel> missionUnlocksBetween(
  int from,
  int to,
  List<CosmeticItemModel> Function(int level) unlockedAt,
) {
  if (to <= from) return const [];

  final unlocked = <CosmeticItemModel>[];
  for (var level = from + 1; level <= to; level++) {
    unlocked.addAll(unlockedAt(level));
  }
  return unlocked;
}

/// 해금된 것을 하나씩 얹어 가는 중간 차림들을 만든다.
///
/// 첫 칸은 [before] 그대로이고, 칸이 하나 늘 때마다 [unlocked] 의 아이템이
/// 하나씩 더 걸린 모습이 된다. 그래서 길이는 늘 `unlocked.length + 1` 이다.
/// 화면은 이 목록을 앞에서 뒤로 넘기며 개구리가 옷을 입는 과정을 그린다.
///
/// 같은 자리에 이미 걸려 있던 것은 내린다. Lv.14 의 왕관이 Lv.15 의 학사모로
/// 바뀌는 것처럼, 한 자리에 둘이 겹쳐 그려지면 안 된다.
///
/// [after] 는 층 순서를 알아내는 데 쓴다. 마지막 칸이 [after] 와 같아지도록
/// 맞추는 것이 목적이라, 그림이 어느 층에 놓이는지는 이미 계산된 쪽을 믿는다.
List<List<CosmeticLayerModel>> missionUnlockStages({
  required List<CosmeticLayerModel> before,
  required List<CosmeticLayerModel> after,
  required List<CosmeticItemModel> unlocked,
}) {
  final stages = <List<CosmeticLayerModel>>[List.of(before)];
  if (unlocked.isEmpty) return stages;

  // 아이템 키로 이미 계산된 층을 먼저 찾고, 없으면 같은 자리의 층에서 순서만
  // 빌린다. 뒤에 열린 것에 밀려 마지막 차림에는 없는 아이템도 있기 때문이다.
  final layerOfItem = <String, CosmeticLayerModel>{};
  final orderOfSlot = <String, int>{};
  var topOrder = 0;
  for (final layer in [...before, ...after]) {
    final itemKey = layer.itemKey;
    if (itemKey != null) layerOfItem[itemKey] = layer;

    final slot = layer.slot;
    if (slot != null) orderOfSlot[slot] = layer.layerOrder;

    if (layer.layerOrder > topOrder) topOrder = layer.layerOrder;
  }

  var current = List.of(before);
  for (final item in unlocked) {
    // 그림이 없으면 개구리에 얹을 것이 없다. 칸은 그대로 한 번 더 둔다.
    // 칸과 이름표가 하나씩 짝을 이뤄야 화면이 둘을 같이 넘길 수 있다.
    if (item.imageUrl.isEmpty) {
      stages.add(List.of(current));
      continue;
    }

    final known = layerOfItem[item.itemKey];
    final layer = known ??
        CosmeticLayerModel(
          imageUrl: item.imageUrl,
          // 어느 자리인지도 모르면 맨 앞에 둔다. 새로 얻은 것은 보여야 한다.
          layerOrder: orderOfSlot[item.slot] ?? topOrder + 1,
          slot: item.slot,
          itemKey: item.itemKey,
        );

    current = [
      for (final kept in current)
        if (kept.itemKey != layer.itemKey &&
            (layer.slot == null || kept.slot != layer.slot))
          kept,
    ];
    current.insert(_insertIndexFor(current, layer), layer);
    stages.add(List.of(current));
  }

  return stages;
}

/// [layer] 가 들어갈 자리. `CosmeticLoadoutModel.resolveLayers` 와 같은 규칙이다.
///
/// 층이 작을수록 뒤에 깔리고, 같은 층이면 개구리 본체가 파츠보다 앞에 온다.
int _insertIndexFor(List<CosmeticLayerModel> layers, CosmeticLayerModel layer) {
  for (var i = 0; i < layers.length; i++) {
    final other = layers[i];
    if (other.layerOrder > layer.layerOrder) return i;
    if (other.layerOrder == layer.layerOrder && other.isBase) return i;
  }
  return layers.length;
}

/// 레벨이 올랐을 때 화면 전체를 쓰는 순간이다.
///
/// 전에는 작은 다이얼로그 한 장이었다. 레벨업은 이 앱에서 가장 드물게 오는
/// 사건인데 그것이 확인 버튼 달린 상자로 끝나면 아무 일도 아닌 것이 된다.
/// 배경이 밝아지고, 개구리가 커지고, 숫자가 올라가고, 뒤에서 빛이 돈다.
///
/// **개구리 그림은 레벨에 따라 바뀌지 않는다.** 그래서 성장은 이번에 열린
/// 치장을 개구리에 직접 입혀서 보여 준다. 목록으로 늘어놓으면 받았다는 느낌이
/// 나지 않는다. 개구리가 이미 쓰고 있어야 내 것이 된 것이다.
Future<void> showMissionLevelUp(
  BuildContext context, {
  int? level,

  /// 이 레벨업 직전의 종합 레벨.
  ///
  /// 이 값과 [level] 사이에서 열린 치장을 찾아 개구리에 하나씩 입힌다. 한 번에
  /// 두 레벨이 오르면 그 사이 것까지 전부 이번에 열린 것이다.
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
  /// 해금 하나가 개구리에 내려앉고 다음 것까지 쉬는 시간.
  ///
  /// 쉬는 구간이 없으면 셋이 끊김 없이 밀려 들어와 몇 개가 열렸는지 세어지지
  /// 않는다. 하나씩 받는 느낌은 이 틈에서 나온다.
  static const Duration _unlockStep = Duration(milliseconds: 420);

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
  ///
  /// 들어올 때 한 번 돌고, 해금이 하나씩 내려앉을 때마다 다시 돈다.
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  /// 빌더 안에서 만들면 프레임마다 새로 생기고 리스너가 쌓인다.
  late final Animation<double> _entered = CurvedAnimation(
    parent: _enter,
    curve: AppMotion.emphasized,
  );

  /// 해금된 것을 하나씩 입히는 시계. 0 에서 1 까지가 전부 입은 것이다.
  late final AnimationController _unlock;

  /// 이번 레벨업으로 새로 열린 치장들. 열린 순서 그대로다.
  late final List<CosmeticItemModel> _unlocked;

  /// 오르기 전 차림에서 시작해 하나씩 걸쳐 가는 중간 차림들.
  late final List<List<CosmeticLayerModel>> _stages;

  /// 레벨 게이지의 오른쪽 끝. 해금이 없는 레벨업에서만 쓴다.
  late final int _maxLevel;

  /// 지금까지 내려앉기 시작한 해금의 수. 같은 것에 두 번 진동을 주지 않는다.
  int _startedCount = 0;

  /// 연출을 시작했는지. [didChangeDependencies] 는 여러 번 불릴 수 있다.
  bool _playing = false;

  @override
  void initState() {
    super.initState();

    // 프로바이더는 여기서 한 번만 읽는다. 이 연출이 보여 줄 것은 창이 열리고
    // 닫힐 때까지 바뀌지 않아서 watch 할 이유가 없고, LayoutBuilder 안에서는
    // watch 가 되지 않는 문제도 같이 피한다.
    final cosmetic = Provider.of<CosmeticProvider>(context, listen: false);
    _maxLevel = cosmetic.maxLevel;
    _unlocked = missionUnlocksBetween(
      _previousLevel,
      _level,
      cosmetic.unlockedAt,
    );
    _stages = missionUnlockStages(
      before: cosmetic.layersAtLevel(_previousLevel),
      after: cosmetic.layersAtLevel(_level),
      unlocked: _unlocked,
    );

    _unlock = AnimationController(
      vsync: this,
      duration: _unlockStep * math.max(_unlocked.length, 1),
    )..addListener(_onUnlockTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_playing) return;
    _playing = true;

    // 기기에서 동작을 줄였으면 아무것도 돌리지 않는다. build 가 컨트롤러 값을
    // 보지 않고 다 입은 모습만 그린다.
    if (AppMotion.isReduced(context)) return;

    _ripple.forward();
    _enter.forward().whenComplete(() {
      if (!mounted || _unlocked.isEmpty) return;
      _unlock.forward();
    });
  }

  @override
  void dispose() {
    _unlock.removeListener(_onUnlockTick);
    _unlock.dispose();
    _enter.dispose();
    _ripple.dispose();
    super.dispose();
  }

  /// 해금 하나가 내려앉기 시작할 때마다 파문과 진동을 준다.
  ///
  /// 마지막 하나만 세게 준다. 처음부터 세게 주면 몇 개가 남았는지 알 수 없고,
  /// 끝났다는 것도 손끝으로 오지 않는다.
  void _onUnlockTick() {
    final count = _unlocked.length;
    if (count == 0) return;

    final started = math.min((_unlock.value * count).floor() + 1, count);
    if (started <= _startedCount) return;
    _startedCount = started;

    _ripple.forward(from: 0);
    if (started >= count) {
      AppHaptic.primary();
    } else {
      AppHaptic.selection();
    }
  }

  int get _level => widget.level ?? 1;

  int get _previousLevel =>
      widget.previousLevel ?? (_level > 1 ? _level - 1 : _level);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final reduced = AppMotion.isReduced(context);
    final primary = themeProvider.primaryColor;

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
              primary.withValues(alpha: 0.20),
              primary.withValues(alpha: 0.04),
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
                  _buildFrog(primary, reduced),
                  const SizedBox(height: AppSpacing.xl),
                  // 제목을 따로 두지 않는다. `Lv.1 → Lv.2` 가 이미 그 말이다.
                  _buildLevelRow(primary, reduced),
                  const SizedBox(height: AppSpacing.md),
                  StandardText(
                    text: missionLevelPhraseOf(_level),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // 입을 것이 열렸으면 그것을, 아니면 얼마나 올라왔는지를 둔다.
                  if (_unlocked.isNotEmpty)
                    _buildUnlockedCosmetics(primary, reduced)
                  else
                    _buildLevelTrack(primary, reduced),
                  if (widget.unlockedThemeIndexes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.cardGap),
                    _buildUnlocked(primary),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildConfirm(primary),
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

        final frog = reduced
            // 움직임을 끈 기기에는 다 입은 모습을 바로 보여 준다.
            ? _DressingFrog(stages: _stages, size: size * 0.72, progress: 1)
            : AnimatedBuilder(
                animation: _unlock,
                builder: (context, _) => _DressingFrog(
                  stages: _stages,
                  size: size * 0.72,
                  progress: _unlock.value,
                ),
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

  /// 이번에 열린 치장. 개구리가 이미 입고 있고, 여기에는 이름만 붙는다.
  ///
  /// 이름표는 개구리에 하나가 내려앉은 뒤에 따라 붙는다. 먼저 뜨면 목록을
  /// 읽고 나서 그림이 따라오는 순서가 되어 받은 느낌이 흐려진다.
  Widget _buildUnlockedCosmetics(Color primary, bool reduced) {
    final chips = [
      for (final item in _unlocked)
        _UnlockChip(name: item.nameKo, color: primary),
    ];

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
            text: '개구리가 바로 입어 봤어요',
            fontSize: 13,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          if (reduced)
            _chipWrap(chips)
          else
            AnimatedBuilder(
              animation: _unlock,
              builder: (context, _) => _chipWrap([
                for (var i = 0; i < chips.length; i++) _revealChip(chips[i], i),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _chipWrap(List<Widget> chips) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips,
    );
  }

  /// 아직 차례가 오지 않은 이름표는 투명하게 둔다.
  ///
  /// 자리는 처음부터 잡아 둔다. 이름이 하나씩 늘어나며 아래가 밀리면 누르려던
  /// 버튼이 손가락 밑에서 움직인다.
  Widget _revealChip(Widget chip, int index) {
    final count = _unlocked.length;
    final raw = _unlock.value * count;
    final t = AppMotion.emphasized.transform(
      ((raw - index - 0.3) / 0.55).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, AppMotion.enterOffset * (1 - t)),
        child: chip,
      ),
    );
  }

  /// 입을 것이 열리지 않은 레벨업. 숫자와 게이지로만 간다.
  ///
  /// 없는 보상을 지어내지 않는다. 대신 전체 레벨 중 어디까지 왔는지를 보여
  /// 준다. 이번에 찬 만큼이 진한 색으로 앞서 있던 자리를 덮고 더 나간다.
  Widget _buildLevelTrack(Color primary, bool reduced) {
    final top = math.max(_maxLevel, 2);
    final before = (_previousLevel / top).clamp(0.0, 1.0);
    final after = (_level / top).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 8,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: ColoredBox(
                      color: AppColors.border,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: before,
                        heightFactor: 1,
                        child: ColoredBox(
                          color: primary.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedLinearGauge(
                    value: after,
                    color: primary,
                    // 이 막대는 아래에 깔린 것을 덮으면 안 된다.
                    backgroundColor: Colors.transparent,
                    height: 8,
                    borderRadius: AppRadius.full,
                    delay: reduced ? Duration.zero : AppMotion.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StandardText(
                text: 'Lv.1',
                fontSize: 11,
                color: AppColors.textTertiary,
                maxLines: 1,
              ),
              StandardText(
                text: 'Lv.$top',
                fontSize: 11,
                color: AppColors.textTertiary,
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
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

/// 개구리가 이번에 열린 것을 하나씩 입는 과정이다.
///
/// 개구리 그림은 더 이상 레벨에 따라 바뀌지 않는다. 그래서 성장은 여기서만
/// 눈에 보인다. 해금을 목록으로 늘어놓는 대신 개구리에 바로 얹는다.
///
/// [stages] 는 오르기 전 차림에서 시작해 하나씩 더 걸친 차림들이다.
/// [progress] 가 0 이면 첫 칸, 1 이면 마지막 칸이고, 그 사이에서는 다음 칸에
/// 새로 붙는 한 장이 커진 채로 옅게 들어와 제자리에 내려앉는다.
class _DressingFrog extends StatelessWidget {
  final List<List<CosmeticLayerModel>> stages;
  final double size;

  /// 0 에서 1. 해금을 어디까지 입혔는지.
  final double progress;

  const _DressingFrog({
    required this.stages,
    required this.size,
    required this.progress,
  });

  /// 한 걸음 중 앞쪽 얼마 동안 내려앉는지. 나머지는 다음 것까지 쉬는 시간이다.
  static const double _landPortion = 0.78;

  /// 들어올 때의 배율. 밖에서 날아오는 것이 아니라 제자리에 얹히는 느낌이라
  /// 크게 벌리지 않는다.
  static const double _landScale = 1.16;

  @override
  Widget build(BuildContext context) {
    final steps = stages.length - 1;
    // 아직 입히기가 시작되지 않았으면 오르기 전 차림 그대로다. 개구리가 커지며
    // 자리를 잡는 동안 이미 갈아입고 있으면 무엇이 새로 온 것인지 알 수 없다.
    if (steps <= 0 || progress <= 0) return _part(stages.first);

    final raw = (progress * steps).clamp(0.0, steps.toDouble());
    if (raw >= steps) return _part(stages.last);

    final index = raw.floor();
    final target = stages[index + 1];
    final landing = _landingIndexOf(stages[index], target);
    // 그림이 없어 얹을 것이 없는 칸이면 그냥 그대로 둔다.
    if (landing < 0) return _part(stages[index]);

    final t = AppMotion.emphasized.transform(
      ((raw - index) / _landPortion).clamp(0.0, 1.0),
    );

    // 내려앉는 한 장을 제 층에 끼워 넣는다. 배경처럼 개구리 뒤에 깔리는 것을
    // 통째로 앞에 놓으면 개구리가 가려진다.
    return Stack(
      alignment: Alignment.center,
      children: [
        _part(target.sublist(0, landing)),
        Opacity(
          // 자리를 잡기 한참 전에 이미 또렷해야 무엇이 오는지 보인다.
          opacity: (t * 2.2).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _landScale - (_landScale - 1) * t,
            child: _part([target[landing]]),
          ),
        ),
        _part(target.sublist(landing + 1)),
      ],
    );
  }

  /// [previous] 에 없고 [target] 에 있는 층의 자리. 없으면 -1 이다.
  static int _landingIndexOf(
    List<CosmeticLayerModel> previous,
    List<CosmeticLayerModel> target,
  ) {
    final had = {for (final layer in previous) layer.itemKey};
    for (var i = 0; i < target.length; i++) {
      if (!had.contains(target[i].itemKey)) return i;
    }
    return -1;
  }

  /// 층 몇 장을 겹쳐 그린다.
  ///
  /// [FrogLayerStack] 은 층이 비면 개구리 본체를 대신 그린다. 여기서는 그
  /// 자리를 정말로 비워 둬야 해서 빈 칸을 놓는다.
  Widget _part(List<CosmeticLayerModel> layers) {
    if (layers.isEmpty) return SizedBox.square(dimension: size);
    return FrogLayerStack(layers: layers, size: size);
  }
}

/// 이번에 열린 치장 하나의 이름표다.
///
/// 금색이나 반짝임을 쓰지 않는다. 테마색 테두리를 두른 흰 알약 하나면 충분하고,
/// 무엇을 얻었는지는 이미 개구리가 입고 서 있다.
class _UnlockChip extends StatelessWidget {
  final String name;
  final Color color;

  const _UnlockChip({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: StandardText(
        text: name,
        fontSize: 13,
        color: color,
        maxLines: 1,
      ),
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
