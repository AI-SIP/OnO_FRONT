import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../Module/Design/AppColors.dart';
import '../../../Module/Motion/AnimatedCountText.dart';
import '../../../Module/Text/StandardText.dart';

/// 옷장 탭 **성장 영역**이 함께 쓰는 글자 위계다.
///
/// 성장 영역은 무대 위쪽의 총 학습 이름표와 그 아래 스탯창의 눈금판 넷,
/// 모두 다섯 덩어리다. 다섯이 각자 크기와 굵기와 정렬과 색을 정하면 눈이
/// 어디를 먼저 봐야 할지 모르게 된다. 그래서 **층을 셋만 두고 다섯이 전부
/// 같은 규칙을 따른다.**
///
/// 1. **값** — `Lv.11`. 능력치 넷은 **색이 들어가는 유일한 글자**다. 색은 그
///    값이 무엇인지 말한다. 미션과 같은 제 능력치 색이다. 총 학습만 색이
///    없는데([totalLevelColor]), 혼자여서 색으로 가를 형제가 없기 때문이다.
///    대신 한 치수 크다. 넷을 합산해 오르는 위쪽 값이라서 위계에서도 위에
///    있어야 한다.
/// 2. **이름표** — `[아이콘] 총 학습`. **언제나 값보다 앞**이다. 가로로 놓이면
///    왼쪽, 세로로 쌓이면 위. 어떤 것은 값 위에 어떤 것은 값 아래에 붙는 일이
///    없어야 한다.
/// 3. **진행도** — `198 / 440`. **언제나 값보다 뒤**다. 가로면 오른쪽 끝,
///    세로면 맨 아래. 총 학습은 막대의 오른쪽 끝과 맞물리고, 능력치는 고리
///    바로 아래에 온다.
///
/// **굵기는 글꼴로 낸다.** 앱에 등록된 Pretendard 는 Bold 와 Light 둘뿐이라
/// `w600` 과 `w800` 을 적어 봐야 화면에서는 구분되지 않는다. 값은 Bold,
/// 이름표와 진행도는 Light 다. 그래서 굵기도 크기처럼 세 층을 따라간다.
///
/// **숫자 서식도 한 가지씩이다.** 레벨은 `Lv.N`, 진행도는 `N / M`. 한쪽에만
/// `XP` 같은 꼬리표가 붙으면 두 숫자가 다른 종류로 읽힌다.
abstract final class GrowthType {
  /// 총 학습 레벨. 이 영역에서 가장 큰 글자다.
  static const double totalLevel = 20.0;

  /// 능력치 레벨. 고리 안에 앉는다.
  static const double abilityLevel = 14.0;

  /// 이름표와 진행도. 값을 거드는 것은 전부 이 크기다.
  static const double supporting = 11.0;

  /// 값에 쓰는 글꼴.
  static const String valueFamily = 'PretendardBold';

  /// 이름표와 진행도에 쓰는 글꼴.
  static const String supportingFamily = 'PretendardLight';

  /// 이름표 색. 값보다 한 단계 물러난다.
  static const Color labelColor = AppColors.textSecondary;

  /// 진행도 색. 이름표보다 한 단계 더 물러난다.
  static const Color meterColor = AppColors.textTertiary;

  /// 총 학습 레벨 값의 색.
  ///
  /// **다섯 덩어리 중 여기만 색이 없다.** 능력치 넷은 서로를 구분해야 해서
  /// 색이 곧 정보지만, 총 학습은 혼자라 색으로 가를 형제가 없다. 이 영역에서
  /// 가장 큰 글자([totalLevel])여서 색이 없어도 가장 먼저 읽히고, 덜어 낸
  /// 색은 바로 아래 막대가 가져간다. 무대가 화면을 덮은 뒤로 카드가 배경
  /// 그림 위에 앉게 돼서, 색을 아껴야 그림과 싸우지 않는다.
  static const Color totalLevelColor = AppColors.textPrimary;

  /// 숫자 줄의 행간.
  ///
  /// [StandardText] 기본값 1.8 은 여러 줄 본문에 맞춘 값이다. 한 줄짜리 숫자를
  /// 세 개 쌓는 이 영역에서는 글자마다 빈 줄이 하나씩 끼어 있는 꼴이 되어,
  /// 간격을 여백 위젯으로 아무리 맞춰도 눈에는 제각각으로 보인다. 행간을
  /// 좁히고 간격은 여백 위젯으로만 준다.
  static const double lineHeight = 1.2;

  /// 이름표 앞에 붙는 아이콘 크기. 다섯 덩어리가 같은 값을 쓴다.
  static const double labelIcon = 13.0;

  /// 이름표 아이콘과 글자 사이.
  static const double labelIconGap = 4.0;

  /// 레벨 글자. `Lv.7`.
  static String level(num value) => 'Lv.${value.round()}';

  /// 진행도 글자. `24 / 60`.
  static String meter(num current, int goal) => '${current.round()} / $goal';

  /// 여러 글자를 **같은 크기로** 앉히기 위한 배율.
  ///
  /// 칸마다 [FittedBox] 를 따로 두면 `출석` 은 그대로인데 `문제 복습` 만
  /// 작아진다. 넷이 같은 틀이어야 한다는 규칙이 바로 거기서 깨지고, 글자
  /// 하나가 튀는 것이 제일 먼저 눈에 띈다. 그래서 **가장 넓은 글자가 칸에
  /// 들어가는 배율을 한 번 재서 넷에 똑같이 먹인다.**
  ///
  /// [available] 은 글자가 쓸 수 있는 폭이다. 글자를 실제로 그릴 때 한 번 더
  /// 곱해지는 기기 글자 배율까지 함께 재야 1.6배에서도 맞는다.
  static double uniformScale(
    BuildContext context,
    Iterable<String> texts, {
    required double available,
    double fontSize = supporting,
    String fontFamily = supportingFamily,
  }) {
    // 여기서 잰 폭과 실제로 그려지는 폭 사이에는 글꼴 반올림만큼의 차이가
    // 남는다. 그 차이가 딱 칸을 넘기면 뒤에 둔 [FittedBox] 가 **가장 긴 것
    // 하나만** 2% 쯤 더 줄이고, 넷을 같은 크기로 앉히려던 것이 그 2% 에서
    // 깨진다. 한 픽셀을 미리 떼어 두어 그 일이 없게 한다.
    available -= 1.0;
    if (available <= 0) return 1.0;

    final scaler = MediaQuery.textScalerOf(context);
    final style = TextStyle(
      fontSize: scaler.scale(fontSize),
      fontFamily: fontFamily,
      fontWeight: FontWeight.bold,
      height: lineHeight,
    );

    var widest = 0.0;
    for (final text in texts) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
    }

    if (widest <= available) return 1.0;
    return available / widest;
  }
}

/// 이름표 한 줄. `[아이콘] 이름`.
///
/// 총 학습과 능력치 넷이 같은 위젯을 쓴다. 아이콘만 그 값의 색이고 글자는
/// 다섯 다 같은 회색이다. 아이콘이 무엇인지 말하고 글자는 거들기만 한다.
class GrowthLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  /// 아이콘 색. 그 값의 색이다.
  final Color color;

  /// [GrowthType.uniformScale] 이 재 준 배율. 넷을 같은 크기로 앉힐 때 쓴다.
  final double scale;

  const GrowthLabel({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: GrowthType.labelIcon, color: color),
        const SizedBox(width: GrowthType.labelIconGap),
        StandardText(
          text: text,
          fontSize: GrowthType.supporting * scale,
          fontFamily: GrowthType.supportingFamily,
          color: GrowthType.labelColor,
          height: GrowthType.lineHeight,
          maxLines: 1,
        ),
      ],
    );
  }
}

/// 진행도 한 줄. `24 / 60`.
///
/// 옆이나 위의 게이지와 **같은 시간에 같은 속도로** 올라간다. 막대는 차오르는데
/// 숫자는 처음부터 끝값으로 박혀 있으면 둘이 다른 것을 말하는 것처럼 보인다.
class GrowthMeterText extends StatelessWidget {
  final int current;
  final int goal;

  /// [GrowthType.uniformScale] 이 재 준 배율.
  final double scale;

  /// 올라가기 시작하는 시점. 게이지에 준 것과 같은 값을 준다.
  final Duration delay;

  const GrowthMeterText({
    super.key,
    required this.current,
    required this.goal,
    this.scale = 1.0,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCountText(
      value: current,
      formatter: (value) => GrowthType.meter(value, goal),
      fontSize: GrowthType.supporting * scale,
      fontFamily: GrowthType.supportingFamily,
      color: GrowthType.meterColor,
      height: GrowthType.lineHeight,
      delay: delay,
    );
  }
}
