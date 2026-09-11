import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 보상 상자의 세 프레임. 셋은 상자 크기와 바닥선이 같아서 그대로 겹쳐 바꾼다.
abstract final class MissionChestFrame {
  /// 닫힌 상자. 연출이 시작될 때의 모습이다.
  static const String closed = 'assets/Reward/reward_chest_closed.png';

  /// 뚜껑이 열리고 안이 빛나는 상자. 열리는 순간부터 이것으로 바뀐다.
  static const String open = 'assets/Reward/reward_chest_open.png';

  /// 열린 상자 위로 별과 잎사귀가 떠오른 모습. 마지막에 겹쳐 들어온다.
  static const String reveal = 'assets/Reward/reward_chest_reveal.png';
}

/// 상자 연출의 시간표다. 0 에서 1 까지의 진행도를 구간으로 나눈다.
///
/// 이 값들이 곧 "언제 무엇이 보이는가"라서, 화면 코드와 테스트가 같은 것을
/// 보게 하려고 밖으로 열어 둔다. 숫자를 고치면 테스트도 같이 따라온다.
abstract final class MissionChestTiming {
  /// 상자가 흔들리며 눌리기 시작하는 때. 이 예비 동작이 있어야 열림이 산다.
  static const double windUpStart = 0.20;

  /// 뚜껑이 열리는 순간. 연출의 정점이다.
  static const double openAt = 0.46;

  /// 튀어오름이 잦아드는 때.
  static const double popEnd = 0.74;

  /// 별과 잎사귀가 떠오르기 시작하는 때.
  static const double revealStart = 0.62;

  /// 별과 잎사귀가 다 떠오른 때. 이때부터 열린 프레임은 걷는다.
  static const double revealEnd = 0.80;

  /// 상자 안의 것이 떠오르기 시작하는 때. **열린 뒤여야 한다.**
  static const double contentStart = 0.52;

  /// 떠오른 것이 제자리에 서는 때.
  static const double contentEnd = 0.86;

  /// 보상 액수가 떠오르기 시작하는 때. 상자에서 나온 것보다 살짝 늦다.
  static const double amountStart = 0.66;
}

/// 상자를 찾는 키. 테스트가 이 자리를 잡는 데 쓴다.
const Key missionRewardChestKey = Key('mission_reward_chest');

/// 그림 안에서 상자가 바닥에 닿는 높이. 정사각형 캔버스의 88% 쯤이다.
///
/// 눌리고 흔들리는 기준점이다. 네모의 맨 아래를 잡으면 상자 밑에 있지도 않은
/// 여백을 축으로 도니까 상자가 바닥에서 떠 보인다.
const Alignment missionChestBase = Alignment(0, 0.76);

/// 닫힘 → 열림 → 내용물 등장으로 이어지는 보상 상자다.
///
/// 컨트롤러를 스스로 들지 않고 [progress] 를 받는다. 상자와 보상 액수와 진동이
/// 같은 시계를 봐야 순서가 어긋나지 않기 때문이다. 연출을 끈 기기에서는 부르는
/// 쪽이 `AlwaysStoppedAnimation(1)` 을 넘기면 마지막 모습이 바로 나온다.
class MissionRewardChest extends StatelessWidget {
  /// 0 에서 1 까지의 진행도.
  final Animation<double> progress;

  /// 상자 한 변의 길이. 둘레의 빛과 조각까지 합친 자리는 이보다 넓다.
  final double size;

  /// 빛과 조각의 색. 사용자가 고른 테마색을 받는다.
  final Color tint;

  /// 상자에서 떠오르는 것. 코인이 들어온다.
  final Widget content;

  const MissionRewardChest({
    super.key,
    required this.progress,
    required this.size,
    required this.tint,
    required this.content,
  });

  /// 둘레의 빛과 조각까지 합친 자리.
  double get _fieldSize => size * 1.5;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: missionRewardChestKey,
      dimension: _fieldSize,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final t = progress.value.clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              // 뒤에서 퍼지는 빛. 밝은 바탕이라 검정 없이도 상자가 도드라진다.
              _Glow(tint: tint, t: t),
              // 뚜껑이 열리는 순간 한 번 번지는 파문.
              CustomPaint(
                size: Size.square(_fieldSize),
                painter: _BurstPainter(progress: _burstOf(t), color: tint),
              ),
              _ChestFrames(size: size, t: t),
              // 상자보다 앞에 둔다. 뒤에 두면 열린 뚜껑 안쪽 금색에 통째로
              // 가려서 무엇이 올라왔는지 보이지 않는다.
              _RisingContent(size: size, t: t, child: content),
            ],
          );
        },
      ),
    );
  }

  /// 열리는 순간에 맞춰 한 번 터지고 옅어진다.
  static double _burstOf(double t) {
    const span = 0.32;
    if (t <= MissionChestTiming.openAt) return 0;
    return ((t - MissionChestTiming.openAt) / span).clamp(0.0, 1.0);
  }
}

/// 상자 그림 세 장. 눌렸다 튀어오르는 움직임도 여기서 준다.
class _ChestFrames extends StatelessWidget {
  final double size;
  final double t;

  const _ChestFrames({required this.size, required this.t});

  @override
  Widget build(BuildContext context) {
    final squash = missionChestSquash(t);
    final hop = missionChestHop(t) * size;
    final tilt = missionChestTilt(t);

    return Transform.translate(
      offset: Offset(0, hop),
      // 흔들림도 눌림도 상자가 바닥에 닿는 데를 붙들고 일어난다.
      child: Transform.rotate(
        angle: tilt,
        alignment: missionChestBase,
        child: Transform.scale(
          scaleX: 1 - 0.10 * squash,
          scaleY: 1 + 0.14 * squash,
          alignment: missionChestBase,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (final frame in _framesAt(t))
                  Opacity(
                    opacity: frame.opacity,
                    child: Image.asset(
                      frame.asset,
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 지금 그려야 할 프레임들. 보이지 않는 것은 아예 빼서 트리에 남기지 않는다.
  static List<({String asset, double opacity})> _framesAt(double t) {
    if (t < MissionChestTiming.openAt) {
      return [(asset: MissionChestFrame.closed, opacity: 1.0)];
    }
    if (t >= MissionChestTiming.revealEnd) {
      return [(asset: MissionChestFrame.reveal, opacity: 1.0)];
    }

    const span = MissionChestTiming.revealEnd - MissionChestTiming.revealStart;
    final fade = ((t - MissionChestTiming.revealStart) / span).clamp(0.0, 1.0);
    if (fade <= 0) {
      return [(asset: MissionChestFrame.open, opacity: 1.0)];
    }
    return [
      (asset: MissionChestFrame.open, opacity: 1.0),
      (asset: MissionChestFrame.reveal, opacity: fade),
    ];
  }
}

/// 눌림에서 튀어오름까지 하나로 이어지는 값. -1 이 가장 눌린 것이다.
///
/// 예비 동작이 끝나는 지점과 튀어오름이 시작되는 지점이 둘 다 -1 이라 중간에
/// 튀는 프레임이 없다. 끝에서는 정확히 0 으로 잦아든다.
double missionChestSquash(double t) {
  if (t <= MissionChestTiming.windUpStart) return 0;

  if (t < MissionChestTiming.openAt) {
    const span = MissionChestTiming.openAt - MissionChestTiming.windUpStart;
    final u = (t - MissionChestTiming.windUpStart) / span;
    return -Curves.easeIn.transform(u);
  }

  const span = MissionChestTiming.popEnd - MissionChestTiming.openAt;
  final v = (t - MissionChestTiming.openAt) / span;
  if (v >= 1) return 0;
  // 눌린 데서 튕겨 올라 한 번 넘겼다가 잦아든다.
  return -math.cos(v * 2 * math.pi) * math.exp(-3.2 * v) * (1 - v);
}

/// 열리는 순간 상자가 살짝 떠오르는 높이. 상자 한 변에 대한 비율이고 음수가 위다.
double missionChestHop(double t) {
  if (t < MissionChestTiming.openAt) return 0;

  const span = MissionChestTiming.popEnd - MissionChestTiming.openAt;
  final v = (t - MissionChestTiming.openAt) / span;
  if (v >= 1) return 0;
  return -0.09 * math.sin(math.pi * v);
}

/// 예비 동작에서 좌우로 흔들리는 각도. 열리는 순간에 정확히 0 으로 돌아온다.
double missionChestTilt(double t) {
  if (t <= MissionChestTiming.windUpStart) return 0;
  if (t >= MissionChestTiming.openAt) return 0;

  const span = MissionChestTiming.openAt - MissionChestTiming.windUpStart;
  final u = (t - MissionChestTiming.windUpStart) / span;
  // 점점 크게 흔들리다가 u=1 에서 sin 이 0 이 되며 멈춘다.
  return math.sin(u * 3 * math.pi) * 0.032 * u;
}

/// 상자 안에서 떠오르는 것의 자리와 크기. [dy] 는 상자 한 변에 대한 비율이다.
///
/// [t] 가 [MissionChestTiming.contentStart] 에 닿기 전에는 투명도가 0 이다.
/// **상자가 열리기 전에 보상이 먼저 보이면 상자를 여는 의미가 없다.**
///
/// 상자 위로 높이 띄우지 않는다. 그림의 열린 상자 위에는 이미 별과 잎사귀가
/// 떠 있어서, 거기까지 올리면 둘이 겹쳐 지저분해진다. 상자 안쪽 깊은 데서
/// 출발해 열린 입에 와서 서는 정도로만 올린다.
({double opacity, double dy, double scale}) missionChestContentAt(double t) {
  const start = 0.14;
  const end = 0.05;
  const span = MissionChestTiming.contentEnd - MissionChestTiming.contentStart;
  final raw = ((t - MissionChestTiming.contentStart) / span).clamp(0.0, 1.0);
  if (raw <= 0) return (opacity: 0, dy: start, scale: 0.55);

  final eased = Curves.easeOutCubic.transform(raw);
  return (
    // 자리를 옮기는 것보다 빨리 또렷해져야 안에서 나온 것으로 읽힌다.
    opacity: (raw * 2.4).clamp(0.0, 1.0),
    dy: start + (end - start) * eased,
    scale: 0.55 + 0.45 * eased,
  );
}

/// 상자 안에서 떠올라 위에 서는 것.
class _RisingContent extends StatelessWidget {
  final double size;
  final double t;
  final Widget child;

  const _RisingContent({
    required this.size,
    required this.t,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final at = missionChestContentAt(t);

    // 보이지 않아도 트리에서 빼지 않는다. 연출 도중에 화면을 눌러 닫으면
    // 부르는 쪽이 이것의 자리를 재서 코인을 날리는데, 빼 두면 잴 것이 없다.
    return Transform.translate(
      offset: Offset(0, at.dy * size),
      child: Opacity(
        opacity: at.opacity,
        child: Transform.scale(scale: at.scale, child: child),
      ),
    );
  }
}

/// 상자 뒤에서 퍼지는 빛. 열리는 순간에 가장 밝다.
class _Glow extends StatelessWidget {
  final Color tint;
  final double t;

  const _Glow({required this.tint, required this.t});

  @override
  Widget build(BuildContext context) {
    // 열리기 전에는 은은하게 깔려 있다가 열리면서 한 번 밝아진다.
    final lift = t < MissionChestTiming.openAt
        ? 0.0
        : Curves.easeOut.transform(
            ((t - MissionChestTiming.openAt) / 0.24).clamp(0.0, 1.0),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            tint.withValues(alpha: 0.12 + 0.16 * lift),
            tint.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// 뚜껑이 열리는 순간 한 번 번져 나가는 파문이다.
///
/// 예전에는 둘레에 같은 크기의 점 열 개를 빙 둘러 찍었는데, 그림에 이미
/// 작가가 그려 넣은 별과 반짝임이 있어서 그 위에 기계로 찍은 듯한 점이 겹치면
/// 둘 다 죽었다. 선 하나가 퍼졌다 사라지는 쪽이 그림을 가리지 않는다.
class _BurstPainter extends CustomPainter {
  /// 0 에서 1. 퍼져 나간 정도.
  final double progress;
  final Color color;

  const _BurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final eased = Curves.easeOutCubic.transform(progress);
    // 끝으로 갈수록 옅어지고 얇아진다.
    final fade = 1 - progress;
    final radius = size.shortestSide / 2 * (0.34 + 0.62 * eased);

    canvas.drawCircle(
      size.center(Offset.zero),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + 2.4 * fade
        ..color = color.withValues(alpha: 0.34 * fade),
    );
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
