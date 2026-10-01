import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Model/Problem/AnswerStatus.dart';
import '../../../Model/Problem/ProblemSolveTrend.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Motion/AnimatedGauge.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Text/mobile_font_size.dart';
import 'ReviewStatusStyle.dart';

/// 복습 기록 탭 맨 위에 놓는 복습 추이 카드들이다.
///
/// 회차 카드를 하나씩 펼쳐 보지 않아도 이 문제를 점점 맞히게 됐는지, 풀이
/// 시간이 줄었는지를 한눈에 보게 한다. 바로 아래 회차 카드와 같은 틀(2px
/// 테두리, 아이콘 상자와 굵은 제목, 오른쪽 배지)에 글자 크기도 맞춘다.
class ReviewTrendPanel extends StatelessWidget {
  final ProblemSolveTrend trend;
  final Color accentColor;
  final bool isWide;

  /// 높이가 낮은 화면에서는 복습 흐름 카드 하나만 보여 준다.
  final bool compact;

  /// 복습 흐름에서 테두리를 둘러 보여 줄 회차(1부터)다.
  final int? selectedRound;

  /// 복습 흐름의 동그라미를 눌렀을 때 회차 번호(1부터)를 넘긴다.
  final ValueChanged<int> onRoundTap;

  const ReviewTrendPanel({
    super.key,
    required this.trend,
    required this.accentColor,
    required this.isWide,
    required this.onRoundTap,
    this.compact = false,
    this.selectedRound,
  });

  /// 태블릿에서 카드 셋을 같은 높이로 나란히 둘 때의 높이다.
  static const double _wideCardHeight = 220;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _FlowCard(
        trend: trend,
        accentColor: accentColor,
        selectedRound: selectedRound,
        onRoundTap: onRoundTap,
      ),
      if (!compact && trend.hasTimeTrend)
        _TimeCard(trend: trend, accentColor: accentColor),
    ];

    if (!isWide || cards.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            cards[i],
          ],
        ],
      );
    }

    final flowHeight = _wideCardHeight + (trend.hasEarlyRecentCompare ? 56 : 0);
    // 풀이 시간은 회차마다 한 줄이라 줄 수만큼 높아진다.
    final timeHeight = 140.0 + trend.timeBars.length * 26;
    final height = flowHeight > timeHeight ? flowHeight : timeHeight;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(flex: i == 0 ? 5 : 4, child: cards[i]),
          ],
        ],
      ),
    );
  }
}

/// 글자 크기는 회차 카드와 같은 네 단계만 쓴다.
abstract final class _Type {
  /// 카드 제목 (회차 카드의 「6회차」).
  static double title(BuildContext c) => MobileFontSize.reduced(c, 16);

  /// 카드의 핵심 한 줄.
  static double body(BuildContext c) => MobileFontSize.reduced(c, 15);

  /// 보조 글씨 (회차 카드의 날짜 줄).
  static double sub(BuildContext c) => MobileFontSize.reduced(c, 13);

  /// 그래프 눈금과 배지.
  static const double tiny = 12;

  static final Color subColor = Colors.grey[600]!;
}

/// 회차 카드와 같은 틀이다. 테두리 색만 정답 여부 대신 테마 색을 쓴다.
class _TrendCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String title;
  final Widget? badge;
  final Widget child;

  const _TrendCard({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.child,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // 태블릿에서는 카드 높이가 정해져 있어서 큰 글씨일 때 넘치지 않도록 카드
      // 안을 스크롤되게 한다. 폰에서는 높이 제한이 없으므로 감싸지 않는다.
      // 감싸 두면 카드 위에서 시작한 세로 드래그를 카드가 가져가서 바깥 목록이
      // 스크롤되지 않는다.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Padding(
            padding: const EdgeInsets.all(16),
            child: _content(context),
          );
          if (!constraints.hasBoundedHeight) return content;
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: content,
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: StandardText(
                  text: title,
                  fontSize: _Type.title(context),
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            if (badge != null) badge!,
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

/// 회차 카드의 「정답」 배지와 같은 모양이다.
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color? textColor;

  const _Badge(this.text, {required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: StandardText(
        text: text,
        fontSize: _Type.tiny,
        color: textColor ?? color,
        height: 1.4,
      ),
    );
  }
}

Widget _sub(BuildContext context, String text, {double? size}) {
  return StandardText(
    text: text,
    fontSize: size ?? _Type.sub(context),
    color: _Type.subColor,
    height: 1.3,
  );
}

class _FlowCard extends StatelessWidget {
  final ProblemSolveTrend trend;
  final Color accentColor;
  final int? selectedRound;
  final ValueChanged<int> onRoundTap;

  const _FlowCard({
    required this.trend,
    required this.accentColor,
    required this.selectedRound,
    required this.onRoundTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = trend.total;
    final correct = trend.correctCount;

    return _TrendCard(
      accentColor: accentColor,
      icon: Icons.timeline_rounded,
      title: '복습 흐름',
      badge: _badge(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StandardText(
            text: total == 1
                ? '1번 복습했어요'
                : correct == 0
                    ? '$total번 중 아직 못 맞혔어요'
                    : '$total번 중 $correct번 맞혔어요',
            fontSize: _Type.body(context),
            color: AppColors.textPrimary,
            height: 1.4,
          ),
          if (total == 1) ...[
            const SizedBox(height: 4),
            _sub(context, '한 번 더 복습하면 흐름을 보여 드릴게요'),
          ],
          if (trend.hasEarlyRecentCompare) ...[
            const SizedBox(height: 12),
            _buildEarlyRecent(context),
          ],
          if (total >= 2) ...[
            const SizedBox(height: 16),
            _buildDots(context),
          ],
        ],
      ),
    );
  }

  /// 지금 흐름을 짧게 말하는 배지. 해당하는 흐름이 없으면 회차 수를 보인다.
  Widget _badge() {
    final count = trend.badgeCount;
    final badge = trend.badge;
    if (badge == null) {
      return _Badge('${trend.total}회', color: accentColor);
    }
    final (String label, AnswerStatus tone) = switch (badge) {
      ReviewTrendBadge.correctStreak => ('$count연속 정답', AnswerStatus.CORRECT),
      ReviewTrendBadge.relapsed => ('다시 틀렸어요', AnswerStatus.PARTIAL),
      ReviewTrendBadge.wrongStreak => ('$count연속 오답', AnswerStatus.PARTIAL),
    };
    return _Badge(
      label,
      color: ReviewStatusStyle.color(tone),
      textColor: ReviewStatusStyle.textColor(tone),
    );
  }

  Widget _buildEarlyRecent(BuildContext context) {
    const window = ProblemSolveTrend.compareWindow;
    final early = trend.earlyCorrectCount;
    final recent = trend.recentCorrectCount;

    Widget cell(String label, int count, bool highlight) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: highlight
                ? accentColor.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Row(
            children: [
              Expanded(child: _sub(context, label)),
              StandardText(
                text: '$count번',
                fontSize: _Type.sub(context),
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: '처음 $window번 중 $early번, 최근 $window번 중 $recent번 맞혔어요',
      excludeSemantics: true,
      child: Row(
        children: [
          cell('처음 $window번', early, false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded,
                size: 16, color: _Type.subColor),
          ),
          cell('최근 $window번', recent, true),
        ],
      ),
    );
  }

  Widget _buildDots(BuildContext context) {
    const dotWidth = 40.0;
    const minGap = 6.0;
    const scrollGap = 14.0;
    final total = trend.total;

    return LayoutBuilder(builder: (context, constraints) {
      final fits =
          total * dotWidth + (total - 1) * minGap <= constraints.maxWidth;

      Widget line({double? width}) => Container(
            width: width,
            height: 2,
            margin: const EdgeInsets.only(top: 15),
            color: AppColors.border,
          );

      // 들어가면 폭에 맞춰 고르게 벌리고, 넘칠 때만 가로로 넘긴다. 넘길 때는
      // reverse 로 오른쪽 끝(최근)부터 보이고, 더 넘길 수 있는 쪽에 화살표를
      // 띄운다.
      if (fits) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) Expanded(child: line()),
              _buildDot(context, i, dotWidth),
            ],
          ],
        );
      }
      return _DotScroller(
        itemCount: total,
        accentColor: accentColor,
        itemBuilder: (context, i) {
          final index = total - 1 - i;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) line(width: scrollGap),
              _buildDot(context, index, dotWidth),
            ],
          );
        },
      );
    });
  }

  Widget _buildDot(BuildContext context, int index, double width) {
    final solve = trend.solves[index];
    final round = index + 1;
    final status = solve.answerStatus;
    final selected = selectedRound == round;
    final date = DateFormat('M/d').format(solve.practicedAt);

    return Semantics(
      button: true,
      label: '$round회차 ${status.displayName}, $date',
      excludeSemantics: true,
      child: PressableScale(
        haptic: HapticLevel.selection,
        onTap: () => onRoundTap(round),
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accentColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        ReviewStatusStyle.color(status).withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    ReviewStatusStyle.icon(status),
                    size: 18,
                    color: ReviewStatusStyle.color(status),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 16,
                child: FittedBox(child: _sub(context, date, size: _Type.tiny)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 복습 흐름 동그라미가 카드 폭을 넘칠 때 가로로 넘기는 줄이다.
///
/// 처음에는 오른쪽 끝(최근)이 보이고, 더 넘길 수 있는 쪽 끝에만 화살표를
/// 띄운다. 화살표를 누르면 한 화면만큼 넘어간다.
class _DotScroller extends StatefulWidget {
  final int itemCount;
  final Color accentColor;

  /// [index] 0 이 오른쪽 끝(최근)이다.
  final IndexedWidgetBuilder itemBuilder;

  const _DotScroller({
    required this.itemCount,
    required this.accentColor,
    required this.itemBuilder,
  });

  @override
  State<_DotScroller> createState() => _DotScrollerState();
}

class _DotScrollerState extends State<_DotScroller> {
  final _controller = ScrollController();
  bool _canOlder = false;
  bool _canNewer = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    // 처음 그린 뒤에야 넘길 거리를 알 수 있다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    // reverse 라서 0 이 오른쪽 끝(최근), 최댓값이 왼쪽 끝(1회차)이다.
    final canOlder = position.pixels < position.maxScrollExtent - 1;
    final canNewer = position.pixels > 1;
    if (canOlder != _canOlder || canNewer != _canNewer) {
      setState(() {
        _canOlder = canOlder;
        _canNewer = canNewer;
      });
    }
  }

  void _page(bool older) {
    final position = _controller.position;
    final step = position.viewportDimension * 0.8;
    final target = (position.pixels + (older ? step : -step))
        .clamp(0.0, position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: AppMotion.page,
      curve: AppMotion.emphasized,
    );
  }

  Widget _arrow({required bool older}) {
    return Semantics(
      button: true,
      label: older ? '이전 회차 보기' : '최근 회차 보기',
      excludeSemantics: true,
      child: PressableScale(
        haptic: HapticLevel.selection,
        onTap: () => _page(older),
        // 화살표는 작아도 누르는 자리는 넉넉하게 둔다.
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                older
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: widget.accentColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Stack(
        children: [
          Positioned.fill(
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: widget.itemCount,
              itemBuilder: widget.itemBuilder,
            ),
          ),
          // 동그라미 가운데 높이(16)에 화살표 가운데를 맞춘다.
          Positioned(
            left: 0,
            top: -2,
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: _canOlder
                  ? _arrow(older: true)
                  : const SizedBox.shrink(key: ValueKey('none')),
            ),
          ),
          Positioned(
            right: 0,
            top: -2,
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: _canNewer
                  ? _arrow(older: false)
                  : const SizedBox.shrink(key: ValueKey('none')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final ProblemSolveTrend trend;
  final Color accentColor;

  const _TimeCard({required this.trend, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final diff = trend.timeImprovementSeconds ?? 0;
    const similar = ProblemSolveTrend.similarTimeSeconds;
    final String summary;
    if (diff > similar) {
      summary = '처음보다 ${_formatDuration(diff)} 빨라졌어요';
    } else if (diff < -similar) {
      summary = '처음보다 ${_formatDuration(-diff)} 더 걸렸어요';
    } else {
      summary = '처음과 비슷하게 걸렸어요';
    }

    final bars = trend.timeBars;
    final maxSeconds =
        bars.map((b) => b.seconds).reduce((a, b) => a > b ? a : b);

    return _TrendCard(
      accentColor: accentColor,
      icon: Icons.timer_outlined,
      title: '풀이 시간',
      badge: trend.isTimeBarsTrimmed
          ? _Badge('최근 ${ProblemSolveTrend.maxTimeBars}회', color: accentColor)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StandardText(
            text: summary,
            fontSize: _Type.body(context),
            color: AppColors.textPrimary,
            height: 1.4,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < bars.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: _TimeRow(
                bar: bars[i],
                maxSeconds: maxSeconds,
                accentColor: accentColor,
                isLatest: i == bars.length - 1,
                delay: AppMotion.stagger * i,
              ),
            ),
        ],
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    if (minutes == 0) return '$rest초';
    if (rest == 0) return '$minutes분';
    return '$minutes분 $rest초';
  }
}

/// 풀이 시간 한 줄이다. 「6회 ▇▇▇▇──── 2분 30초」.
///
/// 막대를 세로로 세우면 칸이 좁아서 「2분 30초」를 한 줄에 못 쓴다. 가로로
/// 눕히면 시간을 줄이지 않고 그대로 적을 수 있다. 위에서부터 오래된 회차이고
/// 맨 아래 가장 최근 회차만 진하게 칠한다.
class _TimeRow extends StatelessWidget {
  final ReviewTimeBar bar;
  final int maxSeconds;
  final Color accentColor;
  final bool isLatest;
  final Duration delay;

  const _TimeRow({
    required this.bar,
    required this.maxSeconds,
    required this.accentColor,
    required this.isLatest,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final time = _TimeCard._formatDuration(bar.seconds);
    final textColor = isLatest ? AppColors.textPrimary : _Type.subColor;

    return Semantics(
      label: '${bar.round}회차 $time',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: StandardText(
              text: '${bar.round}회',
              fontSize: _Type.tiny,
              color: textColor,
              height: 1.3,
            ),
          ),
          Expanded(
            child: AnimatedGaugeValue(
              value: bar.seconds / maxSeconds,
              delay: delay,
              builder: (context, value) => ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  height: 10,
                  color: AppColors.surfaceMuted,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.02, 1.0),
                    child: Container(
                      color: isLatest
                          ? accentColor
                          : accentColor.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: StandardText(
              text: time,
              fontSize: _Type.tiny,
              color: textColor,
              textAlign: TextAlign.end,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
