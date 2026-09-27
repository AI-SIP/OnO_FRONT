/// 모서리 둥글기다.
///
/// 지금 앱에는 2, 4, 6, 8, 10, 12, 14, 15, 16, 20, 999 가 섞여 있다. 10 과
/// 12 처럼 눈으로 구분되지 않는 차이가 화면마다 다르게 쓰여서 정돈되지 않은
/// 느낌을 준다. 네 단계로 줄인다.
abstract final class AppRadius {
  /// 칩, 배지, 작은 버튼.
  static const double small = 8.0;

  /// 입력칸, 목록 항목, 보통 버튼.
  static const double medium = 12.0;

  /// 카드.
  static const double large = 16.0;

  /// 바텀시트와 큰 카드.
  static const double xlarge = 20.0;

  /// 완전히 둥근 것. 손잡이, 진행 막대, 원형 배지.
  static const double full = 999.0;
}
