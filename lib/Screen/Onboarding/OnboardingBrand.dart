import 'package:flutter/material.dart';

/// 스플래시와 로그인이 함께 쓰는 값이다.
///
/// 두 화면은 개구리가 이어지는 하나의 흐름이라 같은 그림과 같은 색을 써야
/// 하는데, 값이 양쪽에 흩어져 있으면 한쪽만 고쳐 두고 넘어가기 쉽다.
abstract final class OnboardingBrand {
  /// 앱을 켤 때 깔리는 색.
  ///
  /// 네이티브 런치스크린도 같은 값을 쓴다. 여기를 고치면 아래 두 곳을 반드시
  /// 같이 고쳐야 하고, 그러지 않으면 앱을 켤 때 색이 한 번 튄다.
  ///
  /// - `ios/Runner/Base.lproj/LaunchScreen.storyboard`
  /// - `android/app/src/main/res/values/colors.xml`
  static const Color background = Color(0xFFCBEAB7);

  /// 온보딩에 쓰는 개구리.
  ///
  /// 마이 페이지의 레벨별 개구리(`assets/FrogCharacter/`)와 그림체가 다르다.
  /// 레벨별 개구리를 새 그림으로 바꾸는 작업이 따로 있어서, 그때 이 파일도
  /// 같이 정리한다.
  static const String frogAsset = 'assets/Logo/FrogLogo.png';

  /// 스플래시의 개구리가 로그인 화면의 개구리로 이어지게 묶는 이름.
  static const String frogHeroTag = 'onboarding-frog';

  /// 스플래시에서 써 나가는 문구.
  ///
  /// 로그인 화면에는 문구를 두지 않는다. 두 화면이 개구리로 이어져 있어서
  /// 같은 문장이 연달아 두 번 나오면 눈에 걸린다.
  static const String phrase = '"나만의 진정한 오답노트, OnO"';
}
