// 로그인 화면 골든 테스트.
//
// 애플 로그인 버튼이 iOS 와 macOS 에서만 보여서 두 플랫폼을 따로 뜬다. 테마로
// 플랫폼을 흉내 내는 것이라 이미지는 호스트 OS 와 상관없이 같다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/Onboarding/LoginScreen.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

void main() {
  setUpOnoWidgetTest();

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    screenGoldenTest(
      '로그인 화면 ${platform.name}',
      fileName: 'login_screen_${platform.name.toLowerCase()}',
      surfaces: GoldenSurface.layouts,
      buildApp: () async {
        final userProvider = _FakeUserProvider();
        when(() => userProvider.loginStatus).thenReturn(LoginStatus.logout);
        when(() => userProvider.isLoggedIn).thenReturn(LoginStatus.logout);
        when(() => userProvider.addListener(any())).thenReturn(null);
        when(() => userProvider.removeListener(any())).thenReturn(null);
        when(() => userProvider.dispose()).thenReturn(null);

        return buildOnoApp(
          onTargetPlatform(platform, const LoginScreen()),
          cosmeticProvider: await loadedCosmeticProvider(),
          userProvider: userProvider,
        );
      },
    );
  }
}
