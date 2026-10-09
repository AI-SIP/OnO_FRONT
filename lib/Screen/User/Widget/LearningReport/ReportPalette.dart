import 'package:flutter/material.dart';

import '../../../../Module/Design/AppColors.dart';

/// 학습 보고서가 쓰는 색이다.
///
/// 대부분 테마색에서 만든다. 처음에는 초록, 주황, 빨강을 뜻 있는 색으로
/// 고정했는데 어느 테마에서나 같은 화면이라 내 앱 같지 않았다. 지금 고정색은
/// 폴더 정답률 글자(빨강, 주황, 초록)와 아직 안 한 것을 뜻하는 회색뿐이다.
///
/// 테마색에서 파생하는 값은 HSL 로 만든다. 테마마다 채도가 크게 달라서
/// 투명도로 섞으면 분홍은 옅고 파랑은 진하게 나온다. 밝기를 고정하고 채도에
/// 상한을 두면 어느 테마든 같은 무게로 보인다.
class ReportPalette {
  // ── 뜻이 정해진 색 ────────────────────────────────────────

  /// 폴더 정답률이 70% 이상일 때의 글자.
  static const Color greenText = Color(0xFF1F9D63);

  static const Color orangeInk = Color(0xFFE8710A);

  static const Color redInk = Color(0xFFE5484D);

  static const Color gray = Color(0xFFD1D6DB);

  // ── 글자와 면 ─────────────────────────────────────────────

  /// 날짜, 칸 이름처럼 본문보다 옅은 글자. 시안의 `#6B7684` 다.
  static const Color textMuted = Color(0xFF6B7684);

  /// 테마색 줄 안의 본문 글자. 시안의 `#333D4B` 다.
  static const Color textBody = Color(0xFF333D4B);

  /// 카드 안 구분선과 막대 바탕.
  static const Color divider = AppColors.surfaceMuted;

  static const double buttonRadius = 14;

  // ── 테마색에서 만드는 것 ──────────────────────────────────

  /// 막대 그래프. 테마색 그대로다.
  final Color base;

  /// 요약 세 칸의 바탕. 흰 화면 위라 아주 옅게 깐다.
  final Color page;

  /// 막대 트랙과 오늘 복습할 문제 아이콘 바탕.
  final Color soft;

  /// 오늘 막대, 오늘 알약, 아이콘 선. 파스텔 테마에서도 흰 글자가 읽힐 만큼
  /// 진하게 둔다.
  final Color deep;

  /// 오답노트 상태의 헷갈리는 문제. [deep] 과 나란히 놓여도 구분되게 밝게 둔다.
  final Color light;

  /// 요약 세 칸 사이의 선. 옅은 테마색 바탕 위라 회색 대신 같은 색을 한 단계
  /// 진하게 쓴다.
  final Color line;

  /// 요약 문장의 문제 수. 흰 바탕의 큰 글자라 [deep] 보다 한 단계 진하게 둬야
  /// 노랑이나 하늘색 테마에서도 읽힌다.
  final Color ink;

  const ReportPalette._({
    required this.base,
    required this.page,
    required this.soft,
    required this.deep,
    required this.ink,
    required this.light,
    required this.line,
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
      soft: tone(1.0, 0.95),
      deep: tone(0.65, 0.52),
      ink: tone(0.65, 0.42),
      light: tone(0.75, 0.80),
      line: tone(0.45, 0.89),
    );
  }

  /// 정답률에 맞는 글자색. 50% 미만 빨강, 70% 미만 주황, 그 위는 초록.
  static Color accuracyInk(double accuracy) {
    if (accuracy < 50) return redInk;
    if (accuracy < 70) return orangeInk;
    return greenText;
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
