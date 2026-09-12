import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../Model/User/UserInfoModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Motion/AnimatedCountText.dart';
import '../../../Module/Motion/AnimatedGauge.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Motion/TossBottomSheet.dart';
import '../../Mission/MissionPalette.dart';
import 'AbilityGuideSheet.dart';
import 'GrowthTypeScale.dart';

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

  /// 카드 껍데기를 스스로 그릴지.
  ///
  /// 무대의 성장 카드 안으로 들어간 뒤로는 false 다. 카드 안에 카드가 또 있으면
  /// 총 학습과 능력치 넷이 서로 다른 것을 말하는 것처럼 갈라져 보이고, 테두리와
  /// 안쪽 여백이 두 겹이라 세로도 그만큼 더 먹는다. 혼자 떨어져 놓일 때를 위해
  /// 기본값은 true 로 둔다.
  final bool framed;

  const AbilityStatPanel({
    super.key,
    this.userInfo,
    this.framed = true,
  });

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

    // 디버그 패널에서 옮겨 놓은 레벨은 여기서 따로 챙기지 않는다.
    // [UserProvider] 가 유저 정보를 내주는 자리에서 이미 갈아 끼운다.
    final stats = <_Ability>[
      _Ability(
        kind: MissionKind.attendance,
        level: info?.attendanceLevel ?? 1,
        point: info?.attendancePoint ?? 0,
      ),
      _Ability(
        kind: MissionKind.noteWrite,
        level: info?.noteWriteLevel ?? 1,
        point: info?.noteWritePoint ?? 0,
      ),
      _Ability(
        kind: MissionKind.problemPractice,
        level: info?.problemPracticeLevel ?? 1,
        point: info?.problemPracticePoint ?? 0,
      ),
      _Ability(
        kind: MissionKind.notePractice,
        level: info?.notePracticeLevel ?? 1,
        point: info?.notePracticePoint ?? 0,
      ),
    ];

    final dials = LayoutBuilder(
      builder: (context, constraints) {
        // 칸 넷을 같은 폭으로 나눈다. 눈금판은 그 칸에 들어가는 만큼만
        // 커진다. 태블릿에서 끝없이 커지지 않게 위도 막아 둔다.
        final cellWidth = (constraints.maxWidth - _dialGap * 3) / stats.length;
        final dial = cellWidth.clamp(_dialMin, _dialMax);

        // 넷의 글자를 **같은 크기로** 앉힌다.
        //
        // 칸마다 [FittedBox] 를 따로 두면 `출석` 은 그대로인데 `문제 복습`
        // 만 작아지고, `Lv.3` 옆에서 `Lv.12` 만 작아진다. 넷이 같은 틀이어야
        // 한다는 규칙이 바로 거기서 깨진다. 세 줄 각각 가장 넓은 것이 칸에
        // 들어가는 배율을 한 번 재서 넷에 똑같이 먹인다.
        final labelScale = GrowthType.uniformScale(
          context,
          [for (final stat in stats) MissionPalette.labelOfKind(stat.kind)],
          available: cellWidth - GrowthType.labelIcon - GrowthType.labelIconGap,
        );
        final meterScale = GrowthType.uniformScale(
          context,
          [
            for (final stat in stats)
              GrowthType.meter(stat.point, stat.requiredPoint),
          ],
          available: cellWidth,
        );
        final levelScale = GrowthType.uniformScale(
          context,
          [for (final stat in stats) GrowthType.level(stat.level)],
          available: dial - (_strokeOf(dial) + _dialTextInset) * 2,
          fontSize: GrowthType.abilityLevel,
          fontFamily: GrowthType.valueFamily,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < stats.length; index++) ...[
              if (index > 0) const SizedBox(width: _dialGap),
              Expanded(
                child: _AbilityDial(
                  ability: stats[index],
                  dialSize: dial,
                  labelScale: labelScale,
                  levelScale: levelScale,
                  meterScale: meterScale,
                  delay: _start + _gap * index,
                  onTap: () => _openGuide(context, stats[index].kind),
                ),
              ),
            ],
          ],
        );
      },
    );

    if (!framed) return dials;

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
      child: dials,
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

/// 고리의 두께. 지름을 따라가되 너무 얇거나 두꺼워지지 않게 막는다.
///
/// 고리 안쪽에 글자가 얼마나 들어가는지를 [AbilityStatPanel] 도 알아야 해서
/// 눈금판 밖에 둔다.
double _strokeOf(double dialSize) => (dialSize * 0.10).clamp(4.0, 6.0);

/// 고리 안쪽 글자가 테두리에서 떨어지는 거리. 테두리까지 물고 들어가면
/// 숫자가 고리에 걸려 읽히지 않는다.
const double _dialTextInset = 3.0;

/// 고리와 그 위아래 글자 사이의 틈.
///
/// 이름표를 고리 위로 올리면서 위아래 모두 [AppSpacing.xs] 를 뒀는데 글자가
/// 고리에 얹혀 있는 것처럼 붙어 보였다. 네모난 카드 사이라면 4 로도 떨어져
/// 보이지만 **고리는 둥글어서 글자와 가장 가까워지는 자리가 꼭대기와 바닥
/// 한 점뿐**이고, 눈은 그 한 점을 먼저 본다. 한 단계 올려 [AppSpacing.sm] 로
/// 둔다. 무대의 총 학습 줄이 글자와 막대 사이에 쓰는 값과 같은 값이라,
/// 성장 영역 다섯 덩어리가 글자와 게이지를 같은 간격으로 떼어 놓게 된다.
///
/// **위아래가 같은 값이다.** 한쪽만 벌리면 고리가 칸 안에서 위나 아래로
/// 밀려난 것처럼 보이고, 눈금판이 넷 나란히 선 자리에서는 그 어긋남이 네 번
/// 되풀이돼 더 눈에 띈다.
const double _dialTextGap = AppSpacing.sm;

/// 능력치 하나를 그리는 눈금판이다.
///
/// 위에서 아래로 [GrowthType] 의 세 층을 그대로 쌓는다.
///
/// 1. **이름표**: `[아이콘] 출석`. 무대의 총 학습 이름표와 같은 모양이다.
/// 2. **값**: 12시에서 시계 방향으로 차오르는 고리, 그 한가운데에 `Lv.3`.
///    이 칸에서 제일 크게 읽혀야 하는 숫자라서 고리 한가운데를 내준다.
/// 3. **진행도**: `8 / 30`. 예쁘기만 하고 이 숫자를 못 읽으면 실패다.
///
/// 이름표가 값 아래가 아니라 **위**인 것은 무대의 총 학습 줄과 순서를 맞추기
/// 위해서다. 다섯 덩어리 중 하나만 이름표가 아래에 붙어 있으면 그것이 먼저
/// 눈에 띈다.
///
/// 세 줄의 글자 크기는 [AbilityStatPanel] 이 넷을 한꺼번에 재서 넘겨준다.
/// 칸마다 따로 줄이면 넷의 크기가 어긋난다. 그래도 남는 넘침은 [FittedBox]
/// 가 막는다.
class _AbilityDial extends StatelessWidget {
  final _Ability ability;
  final double dialSize;

  /// 넷이 함께 쓰는 글자 배율. [GrowthType.uniformScale] 이 재 준 값이다.
  final double labelScale;
  final double levelScale;
  final double meterScale;

  final Duration delay;

  /// 누르면 올리는 법을 펼친다.
  final VoidCallback onTap;

  const _AbilityDial({
    required this.ability,
    required this.dialSize,
    required this.labelScale,
    required this.levelScale,
    required this.meterScale,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MissionPalette.of(ability.kind);
    final accent = colors.accent;
    final stroke = _strokeOf(dialSize);

    // 누를 수 있는 자리를 눈금판 하나 통째로 잡는다. 고리만 누르게 하면
    // 손가락보다 얇아서 잘 안 눌린다.
    return PressableScale(
      onTap: onTap,
      haptic: HapticLevel.none,
      scale: 0.95,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: GrowthLabel(
              icon: MissionPalette.iconOfKind(ability.kind),
              text: MissionPalette.labelOfKind(ability.kind),
              color: accent,
              scale: labelScale,
            ),
          ),
          const SizedBox(height: _dialTextGap),
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
                        stroke: stroke,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(stroke + _dialTextInset),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedCountText(
                        value: ability.level,
                        formatter: GrowthType.level,
                        fontSize: GrowthType.abilityLevel * levelScale,
                        fontFamily: GrowthType.valueFamily,
                        color: accent,
                        height: GrowthType.lineHeight,
                        delay: delay,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: _dialTextGap),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: GrowthMeterText(
              current: ability.point,
              goal: ability.requiredPoint,
              scale: meterScale,
              delay: delay,
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
