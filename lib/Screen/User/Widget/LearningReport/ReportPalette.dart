import 'package:flutter/material.dart';

import '../../../../Module/Design/AppColors.dart';

/// 학습 보고서가 쓰는 색이다.
///
/// 초록, 주황, 빨강, 회색은 뜻이 정해진 색이라 테마와 상관없이 고정한다.
/// 초록은 좋아졌다와 안다, 주황은 헷갈린다, 빨강은 많이 틀린다와 줄었다,
/// 회색은 아직 안 했다. 테마색은 오늘과 내 앱을 가리킬 때만 쓴다.
///
/// 테마색에서 파생하는 값은 HSL 로 만든다. 테마마다 채도가 크게 달라서
/// 투명도로 섞으면 분홍은 옅고 파랑은 진하게 나온다. 밝기를 고정하고 채도에
/// 상한을 두면 어느 테마든 같은 무게로 보인다.
class ReportPalette {
  // ── 뜻이 정해진 색 ────────────────────────────────────────

  static const Color green = Color(0xFF2FB67C);
  static const Color greenInk = Color(0xFF16794D);
  static const Color greenBg = Color(0xFFE6F6EE);
  static const Color greenSoft = Color(0xFFF0FAF5);

  /// 작은 숫자(`+8%p`, 폴더 정답률)에 쓰는 초록. 알약 글자보다 한 단계 밝다.
  static const Color greenText = Color(0xFF1F9D63);

  static const Color orange = Color(0xFFFFB547);
  static const Color orangeInk = Color(0xFFE8710A);
  static const Color orangeBg = Color(0xFFFFF1E5);

  static const Color redInk = Color(0xFFE5484D);
  static const Color redBg = Color(0xFFFDECEC);

  static const Color gray = Color(0xFFD1D6DB);

  // ── 글자와 면 ─────────────────────────────────────────────

  /// 날짜, 칸 이름처럼 본문보다 옅은 글자. 시안의 `#6B7684` 다.
  static const Color textMuted = Color(0xFF6B7684);

  /// 초록 줄 안의 본문 글자. 시안의 `#333D4B` 다.
  static const Color textBody = Color(0xFF333D4B);

  /// 카드 안 구분선과 막대 바탕.
  static const Color divider = AppColors.surfaceMuted;

  static const double cardRadius = 24;
  static const double buttonRadius = 14;

  // ── 테마색에서 만드는 것 ──────────────────────────────────

  /// 막대 그래프. 테마색 그대로다.
  final Color base;

  /// 화면 바탕. 카드가 흰색이라 아주 옅게 깐다.
  final Color page;

  /// 세그먼트 트랙.
  final Color track;

  /// 막대 트랙과 오늘 복습할 문제 아이콘 바탕.
  final Color soft;

  /// 오늘 막대, 오늘 알약, 아이콘 선. 파스텔 테마에서도 흰 글자가 읽힐 만큼
  /// 진하게 둔다.
  final Color deep;

  const ReportPalette._({
    required this.base,
    required this.page,
    required this.track,
    required this.soft,
    required this.deep,
  });

  factory ReportPalette.of(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    Color tone(double maxSaturation, double lightness) => hsl
        .withSaturation(hsl.saturation.clamp(0.0, maxSaturation))
        .withLightness(lightness)
        .toColor();

    return ReportPalette._(
      base: primary,
      page: tone(0.45, 0.965),
      track: tone(0.30, 0.90),
      soft: tone(1.0, 0.95),
      deep: tone(0.65, 0.52),
    );
  }

  /// 정답률에 맞는 글자색. 50% 미만 빨강, 70% 미만 주황, 그 위는 초록.
  static Color accuracyInk(double accuracy) {
    if (accuracy < 50) return redInk;
    if (accuracy < 70) return orangeInk;
    return greenText;
  }

  /// 정답률에 맞는 바탕색.
  static Color accuracyBg(double accuracy) {
    if (accuracy < 50) return redBg;
    if (accuracy < 70) return orangeBg;
    return greenBg;
  }
}

/// 자간을 좁힌다.
///
/// [StandardText] 는 자간을 받지 않는다. 대신 스타일을 이어받게 되어 있어서
/// 위에서 기본 스타일에 자간만 얹으면 그대로 적용된다. 시안의 큰 제목과
/// 숫자는 자간을 좁혀야 덩어리로 읽힌다.
class ReportTracking extends StatelessWidget {
  final double letterSpacing;
  final Widget child;

  const ReportTracking({
    super.key,
    required this.letterSpacing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(letterSpacing: letterSpacing),
      child: child,
    );
  }
}

/// 숫자 폭을 고르게 한다. 0 부터 올라가는 숫자가 자릿수마다 흔들리지 않게
/// 화면 전체에 깐다.
const TextStyle reportTabularFigures = TextStyle(
  fontFeatures: [FontFeature.tabularFigures()],
);
