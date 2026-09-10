import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/Onboarding/LoginScreen.dart';
import 'package:ono/Screen/Onboarding/OnboardingBrand.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

/// 알림을 실제로 보내는 스텁이다.
///
/// 로그인이 끝나면 [UserProvider] 가 알림을 보내고 화면이 다시 그려지는데,
/// 그 경로를 그대로 재현해야 화면을 여러 번 넘기지 않는지 확인할 수 있다.
/// mocktail 의 Mock 은 addListener 까지 가짜라서 다시 그려지지 않는다.
class _NotifyingUserProvider extends ChangeNotifier implements UserProvider {
  LoginStatus _status;

  _NotifyingUserProvider(this._status);

  @override
  LoginStatus? get loginStatus => _status;

  @override
  LoginStatus get isLoggedIn => _status;

  void emit(LoginStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 화면이 몇 번 바뀌었는지 센다.
class _ReplaceCounter extends NavigatorObserver {
  int replaced = 0;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replaced++;
  }
}

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

  /// SvgPicture 안의 에셋 경로로 찾는다. 소셜 로그인 버튼이 전부 SvgPicture
  /// 라서 타입만으로는 구분이 안 된다.
  Finder svgAsset(String path) => find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.bytesLoader is SvgAssetLoader &&
            (widget.bytesLoader as SvgAssetLoader).assetName == path,
      );

  testWidgets('개구리가 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      const LoginScreen(),
      userProvider: userProvider,
    );

    expect(svgAsset(OnboardingBrand.frogAsset), findsOneWidget);
  });

  testWidgets('개구리 아래에 손글씨 문구가 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      const LoginScreen(),
      userProvider: userProvider,
    );

    expect(find.text(OnboardingBrand.phrase), findsOneWidget);
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

    // `if (Platform.isIOS || Platform.isMacOS)` 로 분기한다. 위젯 테스트는
    // 호스트 플랫폼에서 돌기 때문에, 개발자 macOS 에서는 버튼이 있고 리눅스
    // CI 에서는 없다. 한쪽만 단언하면 다른 쪽에서 깨진다.
    final appleButton = svgAsset('assets/SocialLogin/AppleLogin.svg');
    if (Platform.isIOS || Platform.isMacOS) {
      expect(appleButton, findsOneWidget);
    } else {
      expect(appleButton, findsNothing);
    }
  });

  testWidgets('게스트로 시작하기를 누르면 안내가 뜬다', (tester) async {
    await pumpOnoWidget(
      tester,
      const LoginScreen(),
      userProvider: userProvider,
    );

    await tester.tap(find.text('게스트로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('게스트 로그인 안내'), findsOneWidget);
  });

  testWidgets('태블릿 폭에서 버튼이 화면 끝까지 늘어나지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      const LoginScreen(),
      userProvider: userProvider,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);

    // 예전에는 화면 폭의 80% 였다. 태블릿에서는 버튼 하나가 화면을 가로질러
    // 길게 늘어났다.
    final button =
        tester.getSize(svgAsset('assets/SocialLogin/GoogleLogin.svg'));
    expect(button.width, lessThanOrEqualTo(400));
    expect(button.width, lessThan(OnoSurface.tablet.width * 0.8));
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

  group('로그인 상태가 되었을 때', () {
    testWidgets('여러 번 알림이 와도 화면은 한 번만 넘어간다', (tester) async {
      // 예전에는 중복을 막는 플래그가 build 안의 지역 변수였다. 알림이 올
      // 때마다 false 로 되돌아가서 넘기는 예약이 여러 번 걸릴 수 있었다.
      final notifying = _NotifyingUserProvider(LoginStatus.logout);
      final counter = _ReplaceCounter();

      await pumpOnoWidget(
        tester,
        LoginScreen(homeBuilder: (_) => const Scaffold(body: Text('홈'))),
        userProvider: notifying,
        navigatorObservers: [counter],
      );
      // 홈은 탭 넷을 한꺼번에 만들어서 여기서 띄울 것이 아니다. 확인하려는
      // 것은 넘어가는 횟수다.

      notifying.emit(LoginStatus.login);
      await tester.pump();
      notifying.emit(LoginStatus.login);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(counter.replaced, 1);
    });

    testWidgets('로그아웃 상태에서는 넘어가지 않는다', (tester) async {
      final notifying = _NotifyingUserProvider(LoginStatus.logout);
      final counter = _ReplaceCounter();

      await pumpOnoWidget(
        tester,
        LoginScreen(homeBuilder: (_) => const Scaffold(body: Text('홈'))),
        userProvider: notifying,
        navigatorObservers: [counter],
      );
      // 홈은 탭 넷을 한꺼번에 만들어서 여기서 띄울 것이 아니다. 확인하려는
      // 것은 넘어가는 횟수다.

      notifying.emit(LoginStatus.logout);
      await tester.pumpAndSettle();

      expect(counter.replaced, 0);
    });
  });
}
