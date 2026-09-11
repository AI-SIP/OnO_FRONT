import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Module/Theme/GridPainter.dart';
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

/// 쓰기 시작을 미루는 380ms 를 넘기는 시간.
const _beforeWriting = Duration(milliseconds: 400);

/// 다 쓰고 머무는 650ms 를 넘기는 시간.
const _hold = Duration(milliseconds: 700);

/// 글씨를 다 쓴 시점까지 흘려보낸다.
///
/// 시간을 한 번에 크게 흘리면 안 된다. 그러면 쓰기를 시작하는 타이머는 불리지만
/// 애니메이션은 프레임을 받아야 진행하므로 그 자리에 멈춰 있다. 기다리는
/// 구간은 [WidgetTester.pump] 로 넘기고, 움직이는 구간은 `pumpAndSettle` 로
/// 따라가야 한다.
Future<void> _writeThrough(WidgetTester tester) async {
  await tester.pump(_beforeWriting);
  await tester.pumpAndSettle();
}

/// 넘어갈 때까지 흘려보낸다.
Future<void> _runThroughSplash(WidgetTester tester) async {
  await _writeThrough(tester);
  await tester.pump(_hold);
  await tester.pumpAndSettle();
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('개구리와 문구가 보인다', (tester) async {
    // 로그인 화면도 같은 파일을 쓴다. 두 화면에 다른 그림을 두면 이어지는
    // 것이 아니라 다른 개구리 두 마리를 연달아 보는 것처럼 읽힌다.
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

    // 로그인 화면이 쓰는 공책 격자와는 다른 것이다. 그쪽은 화면 전체를 덮는
    // 모눈이고 여기는 가로줄만 긋는다.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is GridPainter,
      ),
      findsNothing,
    );

    // 자동 로그인과 연출이 타이머를 걸어 두고 있어서, 여기서 끝내면 남은
    // 타이머 때문에 테스트가 실패한다.
    await _runThroughSplash(tester);
  });

  testWidgets('로그아웃 상태면 로그인 화면으로 넘어간다', (tester) async {
    await pumpOnoWidget(
      tester,
      _splash(),
      userProvider: _userProvider(status: LoginStatus.logout),
      settle: false,
    );

    await _runThroughSplash(tester);

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

    await _runThroughSplash(tester);

    expect(find.text('홈'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('연출이 끝나기 전에는 넘어가지 않는다', (tester) async {
    // 자동 로그인이 아무리 빨라도 글씨가 적히는 것은 보여주고 넘어가야 한다.
    await pumpOnoWidget(
      tester,
      _splash(),
      userProvider: _userProvider(status: LoginStatus.logout),
      settle: false,
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await _runThroughSplash(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('다 쓰고 나서도 잠깐 머물다가 넘어간다', (tester) async {
    // 마지막 획이 끝나자마자 넘어가면 방금 적은 것을 읽을 새가 없다.
    await pumpOnoWidget(
      tester,
      _splash(),
      userProvider: _userProvider(status: LoginStatus.logout),
      settle: false,
    );

    // 글씨는 다 썼지만 아직 머무는 중이다.
    await _writeThrough(tester);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    // 머무는 시간이 지나면 넘어간다.
    await tester.pump(_hold);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('자동 로그인이 늦으면 그때까지 기다린다', (tester) async {
    await pumpOnoWidget(
      tester,
      _splash(),
      userProvider: _userProvider(
        status: LoginStatus.logout,
        delay: const Duration(seconds: 4),
      ),
      settle: false,
    );

    // 연출은 2.6초 안에 끝나지만 자동 로그인이 4초 걸린다. 연출만 끝났다고
    // 넘어가면 로그인 상태를 모르는 채로 화면이 바뀐다.
    await _runThroughSplash(tester);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
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
