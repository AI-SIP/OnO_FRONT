import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticAbilityLevels.dart';
import '../../../Model/User/UserInfoModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Motion/AnimatedCountText.dart';
import '../../../Module/Motion/AnimatedGauge.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Motion/TossBottomSheet.dart';
import '../../../Module/Text/StandardText.dart';
import '../../Mission/MissionPalette.dart';
import 'AbilityGuideSheet.dart';

/// 능력치 넷을 눈금판 네 개로 세운 **스탯창**이다.
///
/// 예전에는 `무엇으로 자랐나` 라는 제목 아래 넉 줄짜리 막대 목록이었다. 줄
/// 목록은 아래로만 길어져서 개구리를 밀어냈고, 무엇보다 목록으로 읽혔다.
/// 이 탭은 게임의 캐릭터 창에 가까워야 한다.
///
/// **왜 레이더(육각형)가 아닌가.** 능력치가 넷이라 축을 넷 그으면 육각형이
/// 아니라 마름모가 된다. 마름모는 값이 조금만 치우쳐도 찌그러진 사각형으로
/// 보이고, 넷 중 무엇이 어느 꼭짓점인지 매번 다시 읽어야 한다. 없는 축을
/// 만들어 억지로 육각형을 만드는 것은 더 나쁘다. 그래서 **축을 잇지 않고
/// 눈금판 넷을 나란히** 세웠다. 넷은 한 줄에 딱 들어가고, 서로 값을 비교하는
/// 대신 각자 다음 레벨까지 얼마나 남았는지를 말한다. 이 화면이 실제로
/// 궁금한 것도 그쪽이다.
///
/// 한 줄로 세운 데는 다른 이유도 있다. 개구리 · 능력치 넷 · 총 레벨 · 버튼
/// 둘이 **스크롤 없이** 한 화면에 들어가야 해서 세로가 빡빡하다. 눈금판을
/// 가로로 늘어놓으면 능력치 넷이 100 남짓한 높이에 다 들어간다.
///
/// 색과 아이콘은 [MissionPalette] 에서 가져온다. 미션 카드의 색과 같은 색이라,
/// 방금 받은 미션이 어느 눈금판을 올렸는지 색만 보고 알 수 있다.
///
/// **눈금판을 누르면 그 능력치를 어떻게 올리는지 알려 준다.** 색과 숫자는
/// 지금 어디에 서 있는지를 말해 주지만, 무엇을 해야 저 고리가 차는지는 말해
/// 주지 않는다. 미션 화면까지 가서 목록을 훑어야 짐작할 수 있었다.
/// [AbilityGuideSheet] 가 적립 규칙을 그 자리에서 펼친다.
class AbilityStatPanel extends StatelessWidget {
  /// 능력치의 출처. 아직 못 받았으면 전부 1레벨 0점으로 그린다. 값이 늦게
  /// 와도 카드 높이가 바뀌지 않아야 아래 버튼이 들썩이지 않는다.
  final UserInfoModel? userInfo;

  /// **디버그 전용.** 레벨만 이 값으로 덮어 그린다.
  ///
  /// 꾸미기 화면의 디버그 패널에서 능력치 레벨을 옮기면 이 눈금판도 같이
  /// 움직여야 한다. 두 화면이 같은 능력치를 다른 레벨로 말하면 어느 쪽이
  /// 진짜인지 알 수 없다. 경험치는 더미에 없어서 [userInfo] 의 것을 그대로
  /// 둔다. 필요량은 레벨을 따라가므로 덮어쓴 동안에는 `24 / 100` 처럼 진짜
  /// 값과 더미 필요량이 섞인 줄이 나온다. 디버그에서만 보이는 줄이다.
  final CosmeticAbilityLevels? levelOverrides;

  const AbilityStatPanel({super.key, this.userInfo, this.levelOverrides});

  /// 눈금판이 왼쪽부터 하나씩 차오르도록 매기는 간격이다. 넷이 한꺼번에
  /// 움직이면 산만하고, 너무 벌리면 마지막 것이 늦게 끝난다.
  static const Duration _start = Duration(milliseconds: 120);
  static const Duration _gap = Duration(milliseconds: 90);

  /// 눈금판 한 개의 지름. 칸 폭을 따라가되 이 사이를 벗어나지 않는다.
  static const double _dialMin = 40.0;
  static const double _dialMax = 64.0;

  /// 눈금판 사이의 틈.
  static const double _dialGap = 6.0;

  /// 이 능력치를 어떻게 올리는지 펼친다.
  void _openGuide(BuildContext context, MissionKind kind) {
    AppHaptic.selection();
    showTossSheet<void>(
      context: context,
      builder: (_) => AbilityGuideSheet(kind: kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = userInfo;

    final overrides = levelOverrides;

    final stats = <_Ability>[
      _Ability(
        kind: MissionKind.attendance,
        level: overrides?.attendance ?? info?.attendanceLevel ?? 1,
        point: info?.attendancePoint ?? 0,
      ),
      _Ability(
        kind: MissionKind.noteWrite,
        level: overrides?.noteWrite ?? info?.noteWriteLevel ?? 1,
        point: info?.noteWritePoint ?? 0,
      ),
      _Ability(
        kind: MissionKind.problemPractice,
        level: overrides?.problemPractice ?? info?.problemPracticeLevel ?? 1,
        point: info?.problemPracticePoint ?? 0,
      ),
      _Ability(
        kind: MissionKind.notePractice,
        level: overrides?.notePractice ?? info?.notePracticeLevel ?? 1,
        point: info?.notePracticePoint ?? 0,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 칸 넷을 같은 폭으로 나눈다. 눈금판은 그 칸에 들어가는 만큼만
          // 커진다. 태블릿에서 끝없이 커지지 않게 위도 막아 둔다.
          final cellWidth =
              (constraints.maxWidth - _dialGap * 3) / stats.length;
          final dial = cellWidth.clamp(_dialMin, _dialMax);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < stats.length; index++) ...[
                if (index > 0) const SizedBox(width: _dialGap),
                Expanded(
                  child: _AbilityDial(
                    ability: stats[index],
                    dialSize: dial,
                    delay: _start + _gap * index,
                    onTap: () => _openGuide(context, stats[index].kind),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 능력치 한 가지의 값.
class _Ability {
  final MissionKind kind;

  final int level;
  final int point;

  const _Ability({
    required this.kind,
    required this.level,
    required this.point,
  });

  /// 다음 레벨까지 필요한 점수. 마이페이지 레벨 카드가 쓰던 식 그대로다.
  int get requiredPoint => 10 + (level - 1) * 10;

  double get progress =>
      requiredPoint > 0 ? (point / requiredPoint).clamp(0.0, 1.0) : 0.0;
}

/// 능력치 하나를 그리는 눈금판이다.
///
/// 위에서 아래로 세 층이다.
///
/// 1. **눈금판**: 12시에서 시작해 시계 방향으로 차오르는 고리. 가운데에
///    `Lv.3` 이 앉는다. 이 화면에서 가장 크게 읽혀야 하는 숫자라서 고리
///    한가운데를 내준다.
/// 2. **이름**: 미션과 같은 아이콘 + 능력치 이름.
/// 3. **남은 경험치**: `8 / 30`. 예쁘기만 하고 이 숫자를 못 읽으면 실패다.
///
/// 글자를 키운 기기에서는 셋 다 칸보다 넓어진다. 넘치게 두는 대신
/// [FittedBox] 로 줄여서 앉힌다. 기본 크기보다 작아지지는 않는다.
class _AbilityDial extends StatelessWidget {
  final _Ability ability;
  final double dialSize;
  final Duration delay;

  /// 누르면 올리는 법을 펼친다.
  final VoidCallback onTap;

  const _AbilityDial({
    required this.ability,
    required this.dialSize,
    required this.delay,
    required this.onTap,
  });

  /// 고리의 두께. 지름을 따라가되 너무 얇거나 두꺼워지지 않게 막는다.
  double get _stroke => (dialSize * 0.10).clamp(4.0, 6.0);

  @override
  Widget build(BuildContext context) {
    final colors = MissionPalette.of(ability.kind);
    final accent = colors.accent;

    // 누를 수 있는 자리를 눈금판 하나 통째로 잡는다. 고리만 누르게 하면
    // 손가락보다 얇아서 잘 안 눌린다.
    return PressableScale(
      onTap: onTap,
      haptic: HapticLevel.none,
      scale: 0.95,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: SizedBox(
              width: dialSize,
              height: dialSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedGaugeValue(
                    value: ability.progress,
                    delay: delay,
                    builder: (context, current) => CustomPaint(
                      size: Size.square(dialSize),
                      painter: _DialPainter(
                        progress: current,
                        color: accent,
                        trackColor: colors.surface,
                        stroke: _stroke,
                      ),
                    ),
                  ),
                  // 고리 안쪽에만 글자를 둔다. 테두리까지 물고 들어가면
                  // 숫자가 고리에 걸려 읽히지 않는다.
                  Padding(
                    padding: EdgeInsets.all(_stroke + 3),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedCountText(
                        value: ability.level,
                        formatter: (value) => 'Lv.${value.round()}',
                        fontSize: 13,
                        color: accent,
                        delay: delay,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  MissionPalette.iconOfKind(ability.kind),
                  color: accent,
                  size: 15,
                ),
                const SizedBox(width: 3),
                StandardText(
                  text: MissionPalette.labelOfKind(ability.kind),
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: StandardText(
              text: '${ability.point} / ${ability.requiredPoint}',
              fontSize: 10,
              color: AppColors.textTertiary,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 차오르는 고리 하나를 그린다.
///
/// `CircularProgressIndicator` 를 쓰지 않은 이유는 셋이다. 3시에서 시작하고,
/// 끝이 각지고, 바탕 고리의 두께를 따로 줄 수 없다. 스탯창의 눈금판은 12시에서
/// 시작해 끝이 둥글어야 시계가 아니라 게이지로 읽힌다.
class _DialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double stroke;

  const _DialPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.stroke,
  });

  /// 12시. 캔버스의 0도는 3시라서 사분의 일 바퀴를 되돌린다.
  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= stroke) return;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (side - stroke) / 2,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawArc(rect, _start, math.pi * 2, false, track);

    final filled = progress.clamp(0.0, 1.0);
    if (filled <= 0) return;

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, _start, math.pi * 2 * filled, false, fill);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.stroke != stroke;
  }
}
