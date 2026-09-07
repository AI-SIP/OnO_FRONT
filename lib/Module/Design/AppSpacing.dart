/// 여백이다.
///
/// 4 의 배수로만 둔다. 화면마다 13, 18, 26 처럼 애매한 값이 섞이면 요소들이
/// 미묘하게 어긋나 보인다.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  /// 화면 좌우 여백.
  static const double screenHorizontal = 20.0;

  /// 카드 안쪽 여백.
  static const double cardPadding = 20.0;

  /// 카드와 카드 사이.
  static const double cardGap = 12.0;
}
