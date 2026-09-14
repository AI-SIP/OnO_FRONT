import 'dart:async';

import 'package:flutter/material.dart';

import '../../../Module/Motion/AppMotion.dart';

/// 통째로 움직이는 모션의 한 지점이다. `assets/Animation/*.json` 의
/// `keyframes` 한 칸을 그대로 옮긴 것이다.
///
/// [translateY] 는 **512 캔버스 기준 픽셀**이다. 그림이 512 보다 작게
/// 그려지면 그만큼 줄여서 써야 한다. 안 줄이면 작게 그릴수록 과하게 움직인다.
@immutable
class FrogMotionKeyframe {
  /// 재생 구간 안에서의 위치. 0 이 시작, 1 이 끝이다.
  final double t;

  /// 위아래로 옮기는 거리. 음수가 위쪽이다.
  final double translateY;

  final double scaleX;
  final double scaleY;

  const FrogMotionKeyframe({
    required this.t,
    required this.translateY,
    required this.scaleX,
    required this.scaleY,
  });
}

/// 개구리 애니메이션 한 벌이다. `assets/Animation/<이름>.json` 을 옮겨 적었다.
///
/// **json 을 읽지 않고 상수로 들고 있는다.** 이 값들은 첫 프레임을 그리는
/// 순간부터 필요한데, 에셋을 읽는 것은 비동기라 그 사이 한 프레임이 비거나
/// 개구리가 한 번 튄다. 옮겨 적은 값이 manifest 와 갈라지면 아무도 모르게
/// 되므로 `test/screen/user/frog_motion_test.dart` 가 둘을 맞춰 본다.
@immutable
class FrogMotionClip {
  /// manifest 의 `name`.
  final String name;

  /// manifest 의 `durationMs`.
  final Duration duration;

  /// manifest 의 `loop`.
  final bool loop;

  /// 겹쳐 그릴 animated WebP. 키프레임으로 도는 것([keyframes] 가 있는 것)은
  /// null 이다.
  ///
  /// `idle` 과 `happy_bounce` 에도 원본에는 webp 가 있지만 그것은
  /// `animatedWebpPreview`, 즉 확인용이다. 그대로 재생하면 개구리 본체만 움직이고
  /// 입고 있는 치장은 제자리에 남는다. 그래서 여기에 담지 않는다.
  final String? webp;

  /// 통째로 움직이는 모션의 값들. 겹쳐 그리는 효과에는 비어 있다.
  final List<FrogMotionKeyframe> keyframes;

  const FrogMotionClip({
    required this.name,
    required this.duration,
    required this.loop,
    this.webp,
    this.keyframes = const [],
  });

  /// [t] 지점의 변환. 키프레임 사이는 직선으로 잇는다.
  ///
  /// 키프레임이 없으면 아무것도 움직이지 않은 상태를 준다. 첫 프레임이
  /// 깨져 보이면 안 되므로 범위 밖은 양 끝 값으로 눌러 둔다.
  FrogMotionKeyframe sampleAt(double t) {
    if (keyframes.isEmpty) {
      return const FrogMotionKeyframe(
        t: 0,
        translateY: 0,
        scaleX: 1,
        scaleY: 1,
      );
    }

    final clamped = t.clamp(0.0, 1.0);
    if (clamped <= keyframes.first.t) return keyframes.first;
    if (clamped >= keyframes.last.t) return keyframes.last;

    for (var i = 1; i < keyframes.length; i++) {
      final next = keyframes[i];
      if (clamped > next.t) continue;

      final prev = keyframes[i - 1];
      final span = next.t - prev.t;
      // 같은 t 가 두 번 오면 나눗셈이 무한대가 된다. 뒤엣것을 쓴다.
      final u = span <= 0 ? 1.0 : (clamped - prev.t) / span;
      return FrogMotionKeyframe(
        t: clamped,
        translateY: prev.translateY + (next.translateY - prev.translateY) * u,
        scaleX: prev.scaleX + (next.scaleX - prev.scaleX) * u,
        scaleY: prev.scaleY + (next.scaleY - prev.scaleY) * u,
      );
    }

    return keyframes.last;
  }
}

/// 개구리 애니메이션 여섯 벌과, 그것을 켜고 끄는 스위치다.
abstract final class FrogMotion {
  /// 에셋이 그려진 좌표계의 한 변. [FrogMotionKeyframe.translateY] 의 기준이다.
  static const double canvasSide = 512;

  /// 통째로 움직일 때의 기준점. manifest 의 `transformOriginAlignment` 다.
  ///
  /// `[0.0, 0.67]` 은 Flutter [Alignment] 의 좌표계다. 가로 0.0 이 왼쪽 끝이
  /// 아니라 **가운데**이므로 0~1 비율이 아니라 -1~1 정렬값으로 읽는다. 세로
  /// 0.67 은 그림 위에서 83% 지점, 개구리 발치다. 발을 붙인 채 몸이 늘었다
  /// 줄었다 해야 뛰는 것으로 보인다.
  static const Alignment origin = Alignment(0.0, 0.67);

  /// 반복 모션(대기, 눈 깜빡임)을 앱 전체에서 켤지.
  ///
  /// **테스트를 위한 스위치다.** `pumpAndSettle` 은 예약된 프레임이 없어질
  /// 때까지 펌프하는데, 끝나지 않는 모션이 있으면 영원히 안 끝난다. 개구리는
  /// 앱 곳곳에 서 있어서 이게 켜져 있으면 개구리를 그리는 화면의 테스트가
  /// 전부 타임아웃난다. `setUpOnoWidgetTest()` 가 꺼 둔다.
  ///
  /// 한 번만 재생하는 것들은 스스로 멈추므로 이 스위치를 보지 않는다.
  static bool loopsEnabled = true;

  /// 레벨이 오를 때 금빛 링과 파티클이 올라간다. 캐릭터 위에 겹친다.
  static const FrogMotionClip levelUp = FrogMotionClip(
    name: 'level_up',
    duration: Duration(milliseconds: 1740),
    loop: false,
    webp: 'assets/Animation/level_up.webp',
  );

  /// 미션 보상을 받을 때 체크 휘장이 나타난다. 캐릭터 위에 겹친다.
  static const FrogMotionClip missionComplete = FrogMotionClip(
    name: 'mission_complete',
    duration: Duration(milliseconds: 1280),
    loop: false,
    webp: 'assets/Animation/mission_complete.webp',
  );

  /// 치장을 갈아입을 때 반짝인다. 캐릭터 위에 겹친다.
  static const FrogMotionClip equipEffect = FrogMotionClip(
    name: 'equip_effect',
    duration: Duration(milliseconds: 840),
    loop: false,
    webp: 'assets/Animation/equip_effect.webp',
  );

  /// 눈을 깜빡인다. **BASE 그림 한 장을 대신한다.** 치장 좌표는 그대로다.
  static const FrogMotionClip blink = FrogMotionClip(
    name: 'blink',
    duration: Duration(milliseconds: 2040),
    loop: true,
    webp: 'assets/Animation/blink.webp',
  );

  /// 가만히 서 있을 때의 잔잔한 숨쉬기. 치장까지 통째로 움직인다.
  static const FrogMotionClip idle = FrogMotionClip(
    name: 'idle',
    duration: Duration(milliseconds: 1520),
    loop: true,
    keyframes: [
      FrogMotionKeyframe(t: 0.000, translateY: 0, scaleX: 1.000, scaleY: 1.000),
      FrogMotionKeyframe(
          t: 0.143, translateY: -1, scaleX: 0.999, scaleY: 1.002),
      FrogMotionKeyframe(
          t: 0.286, translateY: -2, scaleX: 0.998, scaleY: 1.004),
      FrogMotionKeyframe(
          t: 0.429, translateY: -3, scaleX: 0.997, scaleY: 1.006),
      FrogMotionKeyframe(
          t: 0.571, translateY: -2, scaleX: 0.998, scaleY: 1.004),
      FrogMotionKeyframe(
          t: 0.714, translateY: -1, scaleX: 0.999, scaleY: 1.002),
      FrogMotionKeyframe(t: 0.857, translateY: 0, scaleX: 1.000, scaleY: 1.000),
      FrogMotionKeyframe(t: 1.000, translateY: 0, scaleX: 1.000, scaleY: 1.000),
    ],
  );

  /// 좋은 일이 있을 때 한 번 통통 튄다. 치장까지 통째로 움직인다.
  static const FrogMotionClip happyBounce = FrogMotionClip(
    name: 'happy_bounce',
    duration: Duration(milliseconds: 890),
    loop: false,
    keyframes: [
      FrogMotionKeyframe(t: 0.000, translateY: 0, scaleX: 1.000, scaleY: 1.000),
      FrogMotionKeyframe(t: 0.079, translateY: 2, scaleX: 1.035, scaleY: 0.965),
      FrogMotionKeyframe(
          t: 0.157, translateY: -8, scaleX: 0.995, scaleY: 1.005),
      FrogMotionKeyframe(
          t: 0.247, translateY: -20, scaleX: 0.975, scaleY: 1.025),
      FrogMotionKeyframe(
          t: 0.348, translateY: -25, scaleX: 0.980, scaleY: 1.020),
      FrogMotionKeyframe(
          t: 0.449, translateY: -17, scaleX: 0.990, scaleY: 1.010),
      FrogMotionKeyframe(
          t: 0.539, translateY: -6, scaleX: 1.010, scaleY: 0.990),
      FrogMotionKeyframe(t: 0.618, translateY: 2, scaleX: 1.040, scaleY: 0.960),
      FrogMotionKeyframe(t: 0.719, translateY: 0, scaleX: 1.000, scaleY: 1.000),
      FrogMotionKeyframe(t: 1.000, translateY: 0, scaleX: 1.000, scaleY: 1.000),
    ],
  );
}

/// 캐릭터 위에 한 번 겹쳐 재생하고 사라지는 효과다.
///
/// `layerUsage` 가 `transparent-effect-overlay` 인 것들(레벨업, 미션 완료,
/// 장착)이 여기로 온다. 치장 층 순서에서 맨 위라 [Stack] 의 마지막에 놓는다.
///
/// Flutter 의 animated WebP 에는 재생이 끝났다는 신호가 없다. 그래서
/// [FrogMotionClip.duration] 만큼 두었다가 걷어낸다. 남겨 두면 마지막 프레임이
/// 화면에 박힌 채로 남는다.
class FrogEffectOverlay extends StatefulWidget {
  /// 재생할 효과. [FrogMotionClip.webp] 가 있는 것이어야 한다.
  final FrogMotionClip clip;

  /// 재생 신호. 이 값이 **바뀔 때마다** 다시 튼다.
  ///
  /// 0 이면 아직 아무 일도 없었다는 뜻이라 처음에는 틀지 않는다. 화면에
  /// 뜨자마자 한 번 틀 자리(레벨업 축하처럼)는 1 을 그대로 넘기면 된다.
  final int tick;

  /// 효과 한 변의 길이. 개구리보다 넓게 잡으면 바깥으로 번진다.
  final double size;

  const FrogEffectOverlay({
    super.key,
    required this.clip,
    required this.tick,
    required this.size,
  });

  @override
  State<FrogEffectOverlay> createState() => _FrogEffectOverlayState();
}

class _FrogEffectOverlayState extends State<FrogEffectOverlay> {
  Timer? _timer;
  bool _visible = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 여기서 처음 튼다. initState 에서는 "동작 줄이기" 설정을 볼 수 없다.
    if (_started) return;
    _started = true;
    if (widget.tick > 0) _play();
  }

  @override
  void didUpdateWidget(covariant FrogEffectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tick != widget.tick) _play();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _play() async {
    final path = widget.clip.webp;
    if (path == null) return;
    // 움직임을 줄이기로 한 사용자에게는 아예 띄우지 않는다. 이건 정보를
    // 담은 그림이 아니라 축하 장식이라 빼도 잃는 것이 없다.
    if (AppMotion.isReduced(context)) return;

    _timer?.cancel();

    // 이미지 캐시는 animated WebP 의 재생 위치까지 들고 있다. 지우지 않으면
    // 두 번째부터는 지난번에 멈춘 프레임에서 이어져서, 한 번 재생하고 사라지는
    // 효과가 거의 안 보인다.
    await AssetImage(path).evict();
    if (!mounted) return;

    setState(() => _visible = true);
    _timer = Timer(widget.clip.duration, () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.clip.webp;
    if (!_visible || path == null) return const SizedBox.shrink();

    // 효과가 개구리를 덮고 있는 동안 누름이 막히면 안 된다.
    return IgnorePointer(
      child: Image.asset(
        path,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        // 그림 한 장을 못 읽었다고 축하 화면이 통째로 깨지면 안 된다.
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

/// 개구리와 입고 있는 치장을 **통째로** 움직인다.
///
/// `layerUsage` 가 `whole-cosmetic-stack-transform` 인 것들(대기, 통통 튀기)이
/// 여기로 온다. BASE 만 바뀌는 webp 를 재생하면 모자와 옷이 제자리에 남아
/// 개구리만 몸에서 빠져나간다. 그래서 그림이 아니라 [Transform] 으로 층 전체를
/// 함께 민다.
class FrogStackMotion extends StatefulWidget {
  /// 재생할 모션. [FrogMotionClip.keyframes] 가 있는 것이어야 한다.
  final FrogMotionClip clip;

  /// 개구리가 실제로 그려지는 한 변의 길이.
  ///
  /// 키프레임의 이동 거리는 512 기준이라 이 값으로 비례해서 줄인다.
  final double size;

  /// 한 번짜리 모션을 다시 트는 신호. 반복 모션에서는 보지 않는다.
  ///
  /// 0 이면 처음에는 틀지 않는다. 화면에 뜨자마자 한 번 틀 자리는 1 을 넘긴다.
  final int tick;

  final Widget child;

  const FrogStackMotion({
    super.key,
    required this.clip,
    required this.size,
    required this.child,
    this.tick = 0,
  });

  @override
  State<FrogStackMotion> createState() => _FrogStackMotionState();
}

class _FrogStackMotionState extends State<FrogStackMotion>
    with SingleTickerProviderStateMixin {
  /// 늦게 만들지 않는다. "동작 줄이기"를 켠 기기에서 build 가 컨트롤러를
  /// 건드리지 않고 끝나면, dispose 가 그제서야 만들면서 죽는다.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.clip.duration,
  );

  bool _reduced = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = AppMotion.isReduced(context);

    if (_reduced) {
      // 멈춘 자리는 항상 키프레임 0, 즉 원래 자세다. 정지 상태에서도 개구리가
      // 제대로 보인다.
      _controller.stop();
      _controller.value = 0;
      return;
    }

    if (widget.clip.loop) {
      if (FrogMotion.loopsEnabled && !_controller.isAnimating) {
        _controller.repeat();
      }
      return;
    }

    if (_started) return;
    _started = true;
    if (widget.tick > 0) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant FrogStackMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clip.loop || _reduced) return;
    if (oldWidget.tick != widget.tick) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final frame = widget.clip.sampleAt(_controller.value);
        // 이동 거리는 512 캔버스 기준이다. 그려지는 크기에 맞춰 줄이지 않으면
        // 작게 그릴수록 과하게 움직인다.
        final dy = frame.translateY * widget.size / FrogMotion.canvasSide;

        // 옮기는 것과 늘이는 것을 나눠 건다. 옮기는 거리는 기준점과 상관없고,
        // 늘이는 것만 발치를 붙박아 둬야 뛰는 것으로 보인다.
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scaleX: frame.scaleX,
            scaleY: frame.scaleY,
            alignment: FrogMotion.origin,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
