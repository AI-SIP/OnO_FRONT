import 'package:flutter/material.dart';

/// 보상의 색이다.
///
/// 테마 색상이 24종이라 보상까지 테마색으로 칠하면 사용자마다 보상의 인상이
/// 달라진다. 어떤 사람에게는 분홍 보상, 어떤 사람에게는 회색 보상이 된다.
/// **테마색은 진행과 강조에, 금색은 보상에** 쓴다. 그래서 이 색만 테마와
/// 무관하게 고정한다.
abstract final class AppRewardColors {
  /// 코인의 본색.
  static const Color coin = Color(0xFFF2B01E);

  /// 코인의 그늘과 테두리. 본색만으로는 원이 납작해 보인다.
  static const Color coinDeep = Color(0xFFC98A06);

  /// 금색 위에 얹는 밝은 면. 위쪽이 밝아야 금속처럼 보인다.
  static const Color coinLight = Color(0xFFFFD976);

  /// 칩의 옅은 바탕.
  static const Color coinSurface = Color(0xFFFFF6E0);

  /// 금색 바탕 위의 글자.
  static const Color onCoin = Color(0xFF7A5200);
}
