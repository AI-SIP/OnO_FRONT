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

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == OnboardingBrand.frogAsset,
      ),
      findsOneWidget,
    );
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

  // 테마의 플랫폼으로 분기한다. 예전에는 dart:io 의 Platform 으로 갈라서 개발자
  // macOS 에서는 버튼이 있고 Linux CI 에서는 없었고, 테스트도 호스트 OS 를 보고
  // 단언을 바꿔야 했다. 이제는 테마로 플랫폼을 흉내 내서 어느 OS 에서든 두 갈래를
  // 같이 본다.
  for (final entry in <TargetPlatform, bool>{
    TargetPlatform.iOS: true,
    TargetPlatform.macOS: true,
    TargetPlatform.android: false,
  }.entries) {
    testWidgets(
        '애플 로그인 버튼은 ${entry.key.name} 에서 ${entry.value ? '보인다' : '안 보인다'}',
        (tester) async {
      await pumpOnoWidget(
        tester,
        onTargetPlatform(entry.key, const LoginScreen()),
        userProvider: userProvider,
      );

      expect(
        svgAsset('assets/SocialLogin/AppleLogin.svg'),
        entry.value ? findsOneWidget : findsNothing,
      );
    });
  }

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

  // 아이패드 mini 를 가로로 두면 짧은 쪽이 744 라 태블릿으로 걸리는데 세로로
  // 쓸 수 있는 길이는 700 밖에 안 됐다. 개구리 180 과 그 아래 간격 56 이
  // 고정이라 맨 아래 게스트로 시작하기가 밀려 스크롤해야 보였다.
  group('세로로 짧은 화면', () {
    const sizes = <String, Size>{
      '아이패드 mini 가로': Size(1133, 744),
      '아이패드 10.9 가로': Size(1180, 820),
      '아이패드 Pro 11 가로': Size(1194, 834),
      '아이패드 Pro 11 세로': Size(834, 1194),
    };

    for (final entry in sizes.entries) {
      for (final scale in <double>[1.0, 1.3]) {
        testWidgets('${entry.key} 글자 ${scale}배에서 게스트로 시작하기가 스크롤 없이 보인다',
            (tester) async {
          // 상태 표시줄과 홈 인디케이터를 실제 기기처럼 둔다. 이것이 없으면
          // 세로 길이가 그만큼 넉넉해져서 밀리는 것이 재현되지 않는다.
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
          addTearDown(tester.view.resetPadding);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await withMockedNetworkImages(() async {
            await pumpOnoWidget(
              tester,
              const LoginScreen(),
              surfaceSize: entry.value,
              settle: false,
            );
          });
          await tester.pump(const Duration(seconds: 1));

          final position = tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;

          expect(position.maxScrollExtent, 0,
              reason: '${entry.key} 에서 스크롤해야 끝까지 보인다');
          expect(
            tester.getRect(find.text('게스트로 시작하기')).bottom,
            lessThanOrEqualTo(position.viewportDimension + 24),
            reason: '${entry.key} 에서 게스트로 시작하기가 화면 밖으로 밀렸다',
          );
        });
      }
    }
  });
}
