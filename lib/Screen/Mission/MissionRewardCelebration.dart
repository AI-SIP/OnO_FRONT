import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Mission/MissionModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'MissionRewardChest.dart';
import 'MissionRewardChip.dart';

/// 보상 카드를 화면에서 찾는 키. 테스트가 이 순간이 떴는지 확인하는 데 쓴다.
const Key missionRewardCelebrationKey = Key('mission_reward_celebration');

/// 보상 액수가 떠오르는 자리. 언제 보이기 시작하는지를 테스트가 여기서 본다.
const Key missionRewardAmountKey = Key('mission_reward_amount');

/// 상자가 닫힘에서 내용물 등장까지 가는 데 걸리는 시간.
const Duration missionRewardChestDuration = Duration(milliseconds: 820);

/// 보상을 받은 순간을 보여 주고, 코인이 있던 자리를 돌려준다.
///
/// 돌려준 자리에서 코인이 상단 카운터로 날아간다. 그래야 "여기 있던 것이
/// 저기로 갔다"가 눈에 이어진다. 화면에서 코인을 찾지 못하면 null 이다.
///
/// **레벨업 여부와 상관없이 받을 때마다 이 순간이 있어야 한다.** 카드가 조용히
/// `받음` 으로 바뀌기만 하면 그건 보상이 아니라 알림이다.
///
/// [levelUpFollows] 는 이 카드가 닫히자마자 레벨업 화면이 뜬다는 뜻이다. 그때는
/// 상자가 열린 뒤 머무는 시간을 줄인다. 두 연출이 그대로 이어 붙으면 받을
/// 때마다 보는 사람에게는 길이가 방해가 된다.
Future<Offset?> showMissionRewardCelebration(
  BuildContext context, {
  required String missionTitle,
  required MissionRewardType? rewardType,
  required int amount,
  bool levelUpFollows = false,
}) {
  return showGeneralDialog<Offset?>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '보상',
    // 검정 스크림을 쓰지 않는다. 축하는 어둡게 해서가 아니라 빛으로 낸다.
    barrierColor: Colors.white.withValues(alpha: 0.82),
    transitionDuration: AppMotion.normal,
    pageBuilder: (context, animation, secondaryAnimation) =>
        _MissionRewardCelebration(
      missionTitle: missionTitle,
      rewardType: rewardType,
      amount: amount,
      levelUpFollows: levelUpFollows,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // 라우트 애니메이션은 한 번만 감싼다. 빌더 안에서 만들면 프레임마다
      // CurvedAnimation 이 새로 생기고 리스너가 쌓인다.
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _MissionRewardCelebration extends StatefulWidget {
  final String missionTitle;
  final MissionRewardType? rewardType;
  final int amount;
  final bool levelUpFollows;

  const _MissionRewardCelebration({
    required this.missionTitle,
    required this.rewardType,
    required this.amount,
    required this.levelUpFollows,
  });

  @override
  State<_MissionRewardCelebration> createState() =>
      _MissionRewardCelebrationState();
}

class _MissionRewardCelebrationState extends State<_MissionRewardCelebration>
    with SingleTickerProviderStateMixin {
  /// 상자가 흔들리고 열리고 내용물을 내놓는 것 전부를 하나의 시계로 돌린다.
  /// 시계가 둘이면 열리는 순간과 숫자가 뜨는 순간이 조금씩 어긋난다.
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: missionRewardChestDuration,
  );

  /// 카드가 튀어오르며 들어오는 구간. 상자가 흔들리기 전에 끝난다.
  ///
  /// 빌더 안에서 만들면 프레임마다 새로 생기고 리스너가 쌓인다.
  late final Animation<double> _entered = CurvedAnimation(
    parent: _show,
    curve: const Interval(0, 0.34, curve: AppMotion.emphasized),
  );

  /// 보상 액수가 상자에서 떠오르는 구간.
  late final Animation<double> _amountRevealed = CurvedAnimation(
    parent: _show,
    curve: const Interval(
      MissionChestTiming.amountStart,
      1,
      curve: AppMotion.emphasized,
    ),
  );

  /// 미션 이름은 액수보다 한 박자 늦게 들어온다.
  late final Animation<double> _titleRevealed = CurvedAnimation(
    parent: _show,
    curve: const Interval(0.74, 1, curve: AppMotion.emphasized),
  );

  /// 코인의 자리를 재는 데 쓴다. 닫을 때 이 자리를 돌려준다.
  final GlobalKey _coinKey = GlobalKey();

  Timer? _timer;
  bool _closing = false;
  bool _started = false;

  /// 진동은 한 번씩만 준다. 프레임마다 리스너가 불리므로 지나간 것을 기억한다.
  bool _windUpBuzzed = false;
  bool _openBuzzed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final reduced = AppMotion.isReduced(context);
    if (reduced) {
      // 움직임을 뺀 기기에는 결과만 보여 준다. 그래도 받았다는 신호는 준다.
      AppHaptic.primary();
    } else {
      _show.addListener(_buzzOnCue);
      _show.forward();
    }

    _timer = Timer(_autoDismissOf(reduced), _close);
  }

  /// 스스로 닫히는 시간. 기다리게 하지 않는다.
  Duration _autoDismissOf(bool reduced) {
    if (reduced) {
      // 움직임이 없으니 상자가 열릴 시간을 기다릴 필요가 없다. 대신 글자를
      // 읽을 시간은 그대로 준다.
      return Duration(milliseconds: widget.levelUpFollows ? 700 : 1100);
    }
    // 상자가 다 열린 뒤 잠깐 머문다. 뒤에 레벨업이 붙으면 그 머무름을 줄인다.
    final dwell = widget.levelUpFollows ? 160 : 420;
    return missionRewardChestDuration + Duration(milliseconds: dwell);
  }

  /// 예비 동작에는 약한 진동, 뚜껑이 열리는 순간에는 센 진동을 준다.
  void _buzzOnCue() {
    final t = _show.value;

    if (!_windUpBuzzed && t >= MissionChestTiming.windUpStart) {
      _windUpBuzzed = true;
      AppHaptic.selection();
    }
    if (!_openBuzzed && t >= MissionChestTiming.openAt) {
      _openBuzzed = true;
      AppHaptic.primary();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _show.removeListener(_buzzOnCue);
    _show.dispose();
    super.dispose();
  }

  /// 코인이 지금 화면 어디에 있는지 재서 들고 나간다.
  ///
  /// **밖에서 이미 닫혔으면 아무것도 하지 않는다.** 시스템 뒤로가기나 바깥을
  /// 눌러 라우트가 사라진 뒤에도 이 함수가 불릴 수 있는데(자동 닫기 타이머,
  /// 닫히는 중에 들어온 탭), 그때 pop 을 부르면 **그 아래 미션 화면이 닫혀**
  /// 홈으로 튕긴다. 우리 라우트가 아직 맨 위에 있을 때만 닫는다.
  void _close() {
    if (_closing || !mounted) return;

    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      // 이미 닫혔거나 위에 다른 것이 떠 있다. 타이머만 걷는다.
      _closing = true;
      _timer?.cancel();
      return;
    }

    _closing = true;
    _timer?.cancel();

    final box = _coinKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(box.size.center(Offset.zero))
        : null;
    Navigator.of(context).pop(origin);
  }

  String get _amountLabel =>
      widget.rewardType == MissionRewardType.xp ? '+${widget.amount} XP' : '보상';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final reduced = AppMotion.isReduced(context);

    return Material(
      type: MaterialType.transparency,
      // 어디를 눌러도 바로 넘어간다. 연출이 길을 막으면 안 된다.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _buildCard(themeProvider.primaryColor, reduced),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Color primary, bool reduced) {
    final card = Container(
      key: missionRewardCelebrationKey,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChest(primary, reduced),
          const SizedBox(height: AppSpacing.lg),
          // 이게 주인공이다. 가장 크게 둔다.
          _Reveal(
            key: missionRewardAmountKey,
            animation: _amountRevealed,
            reduced: reduced,
            child: StandardText(
              text: _amountLabel,
              fontSize: 34,
              color: primary,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _Reveal(
            animation: _titleRevealed,
            reduced: reduced,
            child: StandardText(
              text: widget.missionTitle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (reduced) return card;

    // 스프링처럼 살짝 넘겼다 제자리로 온다.
    return AnimatedBuilder(
      animation: _entered,
      builder: (context, child) {
        return Transform.scale(scale: 0.7 + 0.3 * _entered.value, child: child);
      },
      child: card,
    );
  }

  /// 닫힌 상자가 흔들리다 열리고, 그 안에서 코인이 떠오른다.
  Widget _buildChest(Color primary, bool reduced) {
    // 작은 폰에서도 카드가 화면을 넘지 않게 화면 짧은 변에 맞춰 줄인다.
    final size =
        math.min(132.0, MediaQuery.sizeOf(context).shortestSide * 0.34);

    return MissionRewardChest(
      // 연출을 끈 기기에는 시계를 돌리지 않고 마지막 모습만 준다.
      progress: reduced ? const AlwaysStoppedAnimation<double>(1) : _show,
      size: size,
      tint: primary,
      // 상자 입 밖으로 윗부분만 올라온다. 이 코인이 그대로 카운터로 날아가서
      // 상자에서 나온 것이 어디로 갔는지가 눈에 이어진다.
      content: KeyedSubtree(
        key: _coinKey,
        child: MissionRewardToken(size: size * 0.22, color: primary),
      ),
    );
  }
}

/// 상자가 열린 뒤 아래에서 떠오르며 또렷해지는 글자.
///
/// 보이지 않는 동안에도 트리에서 빼지 않는다. 빼면 글자가 나타날 때 카드
/// 크기가 한 번 늘어나 화면이 들썩인다.
class _Reveal extends StatelessWidget {
  final Animation<double> animation;
  final bool reduced;
  final Widget child;

  const _Reveal({
    super.key,
    required this.animation,
    required this.reduced,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (reduced) return child;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, AppMotion.enterOffset * (1 - t)),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }
}
