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
  ///
  /// 원래는 연두색이었다. 그 위에 개구리와 문구를 얹었더니 개구리는 배경에
  /// 묻히고 흰 글씨는 씻긴 것처럼 보였다. 다음에 오는 로그인 화면도 흰
  /// 바탕이라, 흰색으로 두면 앱을 켜서 로그인 화면에 닿을 때까지 색이 한 번도
  /// 바뀌지 않는다.
  static const Color background = Color(0xFFFFFFFF);

  /// 흰 종이 위에 적는 글씨의 색.
  ///
  /// 앱 로고(`assets/Logo/OnO.svg`)에 쓰인 초록을 그대로 가져왔다. 검정으로
  /// 뒀더니 서비스와 상관없는 화면처럼 보였다.
  ///
  /// 사용자가 테마에서 고른 색은 쓰지 않는다. [ThemeHandler] 는 기본색으로
  /// 시작해서 저장된 색을 나중에 불러오므로, 글씨를 쓰는 도중에 색이 한 번
  /// 바뀐다.
  static const Color ink = Color(0xFF68D076);

  /// 밑줄 색.
  ///
  /// 공책에서 중요한 줄에 빨간 밑줄을 긋는 것과 같다. 글씨와 같은 색으로
  /// 그으면 밑줄이 글씨의 일부처럼 보여서 그은 것이 눈에 안 들어온다.
  static const Color underline = Color(0xFFE5484D);

  /// 뒤에 깔리는 공책 줄의 색.
  ///
  /// 진하면 글씨보다 줄이 먼저 보인다. 종이의 결 정도로만 남긴다.
  static const Color rule = Color(0xFFE9F1EA);

  /// 스플래시와 로그인이 같이 쓰는 개구리.
  ///
  /// 앱 아이콘(`ios/Runner/Assets.xcassets/AppIcon.appiconset`)이 이 개구리다.
  /// 사용자가 누른 그림이 그대로 첫 화면에 나와야 방금 연 앱이 맞다는 것이
  /// 바로 읽힌다.
  ///
  /// 한때 스플래시에만 새로 그린 3D 개구리를 썼다가 뺐다. 로그인 화면의 이
  /// 그림과 그림체가 달라서, 이어지는 것이 아니라 다른 개구리 두 마리를 연달아
  /// 보는 것처럼 읽혔다. 같은 그림을 쓰면 [Hero] 로 이어 붙일 수도 있다.
  ///
  /// 새 그림체로 옮기는 것은 레벨별 개구리를 한꺼번에 바꾸는 작업에서 한다.
  /// 그때 앱 아이콘도 같이 바꿔야 이 화면이 아이콘과 어긋나지 않는다.
  static const String frogAsset = 'assets/Logo/GreenFrog.svg';

  /// 스플래시의 개구리가 로그인 화면의 개구리로 이어지게 묶는 이름.
  static const String frogHeroTag = 'onboarding-frog';

  /// 두 화면이 함께 쓰는 문구.
  ///
  /// 스플래시에서는 이 문장을 왼쪽부터 써 나가고, 로그인 화면에서는 개구리가
  /// 자리를 잡은 뒤에 같은 문장이 떠오른다. 로그인 화면에서 다시 쓰는 연출을
  /// 하지 않는 것은 방금 스플래시에서 쓰는 것을 봤기 때문이다.
  static const String phrase = '"나만의 진정한 오답노트, OnO"';
}
