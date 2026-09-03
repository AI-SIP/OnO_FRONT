import 'dart:io' show Platform;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/User/LoginScreen.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

/// 위젯 테스트 하네스가 실제로 도는지 확인하는 기준 테스트.
/// 새 화면 테스트를 쓸 때 이 파일의 모양을 따라간다.
void main() {
  setUpOnoWidgetTest();

  late _FakeUserProvider userProvider;

  setUp(() {
    userProvider = _FakeUserProvider();
    when(() => userProvider.loginStatus).thenReturn(LoginStatus.logout);
    when(() => userProvider.isLoggedIn).thenReturn(LoginStatus.logout);
    // ChangeNotifierProvider 가 구독할 때 부른다.
    when(() => userProvider.addListener(any())).thenReturn(null);
    when(() => userProvider.removeListener(any())).thenReturn(null);
    when(() => userProvider.dispose()).thenReturn(null);
  });

  /// SvgPicture 안의 에셋 경로로 찾는다. 로고와 소셜 로그인 버튼이 전부
  /// SvgPicture 라서 타입만으로는 구분이 안 된다.
  Finder svgAsset(String path) => find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.bytesLoader is SvgAssetLoader &&
            (widget.bytesLoader as SvgAssetLoader).assetName == path,
      );

  testWidgets('로그아웃 상태면 로고와 문구가 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      const LoginScreen(),
      userProvider: userProvider,
    );

    expect(svgAsset('assets/Logo/GreenFrog.svg'), findsOneWidget);
    expect(find.textContaining('나만의 진정한 오답노트'), findsOneWidget);
  });

  testWidgets('로그아웃 상태면 구글과 카카오 로그인 버튼이 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      const LoginScreen(),
      userProvider: userProvider,
    );

    expect(svgAsset('assets/SocialLogin/GoogleLogin.svg'), findsOneWidget);
    expect(svgAsset('assets/SocialLogin/KakaoLogin.svg'), findsOneWidget);
  });

  testWidgets('애플 로그인 버튼은 iOS 와 macOS 에서만 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      const LoginScreen(),
      userProvider: userProvider,
    );

    // LoginScreen.dart:111 이 `if (Platform.isIOS || Platform.isMacOS)` 로 분기한다.
    // 위젯 테스트는 호스트 플랫폼에서 돌기 때문에, 개발자 macOS 에서는 버튼이 있고
    // 리눅스 CI 에서는 없다. 한쪽만 단언하면 다른 쪽에서 깨진다.
    final appleButton = svgAsset('assets/SocialLogin/AppleLogin.svg');
    if (Platform.isIOS || Platform.isMacOS) {
      expect(appleButton, findsOneWidget);
    } else {
      expect(appleButton, findsNothing);
    }
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpOnoWidget(
      tester,
      const LoginScreen(),
      userProvider: userProvider,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('작은 폰 폭에서도 오버플로우가 나지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      const LoginScreen(),
      userProvider: userProvider,
      surfaceSize: OnoSurface.smallPhone,
    );

    expect(tester.takeException(), isNull);
  });
}
