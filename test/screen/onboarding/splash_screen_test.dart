import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/Onboarding/LoginScreen.dart';
import 'package:ono/Screen/Onboarding/OnboardingBrand.dart';
import 'package:ono/Screen/Onboarding/SplashScreen.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

/// 자동 로그인이 [delay] 만큼 걸린 뒤 [status] 로 끝나는 상황을 만든다.
_FakeUserProvider _userProvider({
  required LoginStatus status,
  Duration delay = Duration.zero,
}) {
  final provider = _FakeUserProvider();
  when(() => provider.loginStatus).thenReturn(status);
  when(() => provider.isLoggedIn).thenReturn(status);
  when(() => provider.addListener(any())).thenReturn(null);
  when(() => provider.removeListener(any())).thenReturn(null);
  when(() => provider.dispose()).thenReturn(null);
  when(() => provider.autoLogin())
      .thenAnswer((_) => Future<void>.delayed(delay));
  return provider;
}

Widget _splash() => SplashScreen(
      homeBuilder: (_) => const Scaffold(body: Text('홈')),
    );

void main() {
  setUpOnoWidgetTest();

  testWidgets('개구리와 문구가 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      _splash(),
      userProvider: _userProvider(status: LoginStatus.logout),
      settle: false,
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == OnboardingBrand.frogAsset,
      ),
      findsOneWidget,
    );
    expect(find.text(OnboardingBrand.phrase), findsOneWidget);

    // 자동 로그인과 연출이 타이머를 걸어 두고 있어서, 여기서 끝내면 남은
    // 타이머 때문에 테스트가 실패한다.
    await tester.pumpAndSettle();
  });

  testWidgets('로그아웃 상태면 로그인 화면으로 넘어간다', (tester) async {
    await pumpOnoWidget(
      tester,
      _splash(),
      userProvider: _userProvider(status: LoginStatus.logout),
      settle: false,
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('자동 로그인이 되어 있으면 홈으로 넘어간다', (tester) async {
    await pumpOnoWidget(
      tester,
      _splash(),
      userProvider: _userProvider(status: LoginStatus.login),
      settle: false,
    );

    await tester.pumpAndSettle();

    expect(find.text('홈'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('연출이 끝나기 전에는 넘어가지 않는다', (tester) async {
    // 자동 로그인이 아무리 빨라도 개구리가 떨어지고 글씨가 써지는 것은
    // 보여주고 넘어가야 한다.
    await pumpOnoWidget(
      tester,
      _splash(),
      userProvider: _userProvider(status: LoginStatus.logout),
      settle: false,
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('자동 로그인이 늦으면 그때까지 기다린다', (tester) async {
    await pumpOnoWidget(
      tester,
      _splash(),
      userProvider: _userProvider(
        status: LoginStatus.logout,
        delay: const Duration(seconds: 2),
      ),
      settle: false,
    );

    // 연출은 1초 안에 끝나지만 자동 로그인이 2초 걸린다. 연출만 끝났다고
    // 넘어가면 로그인 상태를 모르는 채로 화면이 바뀐다.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('동작 줄이기를 켜도 화면에서 멈추지 않는다', (tester) async {
    // 손글씨 연출이 끝나기를 기다렸다가 넘어가는 구조라, 움직임을 끈 기기에서
    // 그 신호가 오지 않으면 첫 화면에 갇힌다.
    disableAnimationsForTest(tester);

    await pumpOnoWidget(
      tester,
      _splash(),
      userProvider: _userProvider(status: LoginStatus.logout),
      settle: false,
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
