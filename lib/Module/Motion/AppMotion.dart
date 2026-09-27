import 'package:flutter/material.dart';

/// 앱 전체가 공유하는 모션 값이다.
///
/// 화면 코드에서 `Duration(milliseconds: 300)` 이나 `Curves.easeInOut` 을 직접
/// 적지 않고 여기 상수를 가져다 쓴다. 전환 속도나 감속 느낌을 바꿔야 할 때
/// 이 파일 하나만 고치면 앱 전체가 같이 바뀐다.
///
/// 값을 새로 추가하기 전에 기존 것으로 표현할 수 있는지 먼저 본다. 종류가
/// 늘어나면 애초에 토큰을 만든 이유가 없어진다.
abstract final class AppMotion {
  // ── 지속 시간 ──────────────────────────────────────────────

  /// 눌림 축소와 복귀. 손가락 움직임을 따라가야 해서 가장 짧다.
  static const Duration press = Duration(milliseconds: 110);

  /// 색이 바뀌거나 체크가 켜지는 정도의 작은 상태 변화.
  static const Duration fast = Duration(milliseconds: 150);

  /// 펼침과 접힘, 위젯 교체 같은 일반적인 변화. 기본값으로 쓴다.
  static const Duration normal = Duration(milliseconds: 250);

  /// 화면 전환. Cupertino 기본값(500ms)은 토스 감각에 비해 느려서 줄였다.
  static const Duration page = Duration(milliseconds: 320);

  /// 바텀시트가 올라오고 내려가는 시간.
  static const Duration sheet = Duration(milliseconds: 300);

  /// 목록이 나타나거나 성공 표시가 그려지는 정도의 큰 움직임.
  static const Duration slow = Duration(milliseconds: 350);

  /// 게이지가 차오르고 숫자가 올라가는 시간. 눈으로 변화를 따라갈 수 있어야
  /// 해서 다른 값보다 길다.
  static const Duration gauge = Duration(milliseconds: 700);

  /// 목록 항목이 차례로 나타날 때 항목 사이의 간격.
  static const Duration stagger = Duration(milliseconds: 40);

  // ── 커브 ─────────────────────────────────────────────────

  /// 기본 커브. 시작과 끝이 모두 부드럽다.
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);

  /// 끝에서 길게 감속한다. 화면 전환처럼 크게 움직이는 것에 쓴다.
  /// 토스 특유의 "쭉 밀려와서 스르륵 멈추는" 느낌이 여기서 나온다.
  static const Curve emphasized = Cubic(0.22, 1.0, 0.36, 1.0);

  /// 화면 밖에서 들어오는 것. 빠르게 시작해서 천천히 자리를 잡는다.
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1.0);

  /// 화면 밖으로 나가는 것. 천천히 시작해서 빠르게 사라진다.
  static const Curve exit = Cubic(0.3, 0.0, 0.8, 0.15);

  // ── 미리 묶어 둔 것 ───────────────────────────────────────

  /// 바텀시트가 올라오고 내려가는 방식.
  ///
  /// showModalBottomSheet 를 직접 부르는 곳에 이것만 넘기면 구조를 건드리지
  /// 않고 속도와 커브를 맞출 수 있다. 새로 만드는 시트는 showTossSheet 을
  /// 쓰는 쪽이 손잡이와 모서리까지 같이 맞춰져서 낫다.
  static const AnimationStyle sheetStyle = AnimationStyle(
    duration: sheet,
    curve: enter,
    reverseDuration: normal,
    reverseCurve: exit,
  );

  // ── 그 밖의 값 ────────────────────────────────────────────

  /// 눌렀을 때 줄어드는 비율. 카드처럼 큰 것에도 버튼에도 이 값을 쓴다.
  static const double pressedScale = 0.97;

  /// 목록 항목이 나타날 때 아래에서 올라오는 거리.
  static const double enterOffset = 8.0;

  // ── 접근성 ────────────────────────────────────────────────

  /// 기기 설정에서 애니메이션을 껐는지.
  ///
  /// iOS 의 "동작 줄이기", 안드로이드의 "애니메이션 제거" 를 켠 사용자에게는
  /// 움직임을 빼야 한다. 모션 위젯이 build 안에서 이걸 보고 스스로 끄므로
  /// 화면 코드가 따로 신경 쓸 일이 없다.
  static bool isReduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
