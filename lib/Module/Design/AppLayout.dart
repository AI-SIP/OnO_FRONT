import 'package:flutter/widgets.dart';

/// 넓은 화면에서 본문이 쓸 폭을 정한다.
///
/// 그동안 화면마다 `BoxConstraints(maxWidth: 420 / 520 / 640)` 처럼 고정값을
/// 박아 두었다. 폰에서는 화면보다 넓은 값이라 아무 일도 하지 않지만, 태블릿에
/// 가면 그 숫자가 그대로 본문 폭이 되어 좌우가 크게 빈다. 아이패드 13인치를
/// 가로로 두면 폭이 1376 이라 520 짜리 화면은 양쪽에 428 씩 남겼다.
///
/// 기기 종류로 가르지 않고 실제로 쓸 수 있는 폭에서 비율을 뗀다. 폰은 예전처럼
/// 화면을 다 쓰고, 태블릿은 화면이 커진 만큼 본문도 같이 넓어진다.
abstract final class AppLayout {
  /// 이 폭 아래로는 본문을 좁히지 않는다. 폰은 화면을 그대로 다 쓴다.
  static const double phoneMaxWidth = 600.0;

  /// [available] 중 본문이 쓸 폭이다.
  ///
  /// [ratio] 는 넓은 화면에서 본문이 가져갈 비율, [min] 과 [max] 는 그 결과를
  /// 가두는 범위다. 격자처럼 넓을수록 좋은 화면은 비율과 [max] 를 크게, 입력
  /// 폼처럼 한 줄이 너무 길면 읽기 힘든 화면은 작게 준다.
  static double contentWidth(
    double available, {
    required double ratio,
    required double min,
    required double max,
  }) {
    if (available < phoneMaxWidth) return available;
    return (available * ratio).clamp(min, max);
  }
}

/// 넓은 화면에서 본문을 가운데로 모은다.
///
/// 리포트, 미션, 훈장, 스터디룸 목록처럼 카드가 세로로 쌓이는 화면이 태블릿
/// 가로에서 화면 끝까지 늘어나지 않게 감싼다. 폰에서는 아무 일도 하지 않는다.
class AppContentWidth extends StatelessWidget {
  final Widget child;
  final double ratio;
  final double min;
  final double max;

  const AppContentWidth({
    super.key,
    required this.child,
    this.ratio = 0.8,
    this.min = 600,
    this.max = 960,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.contentWidth(
              constraints.maxWidth,
              ratio: ratio,
              min: min,
              max: max,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
