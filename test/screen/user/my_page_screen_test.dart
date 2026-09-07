import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/User/LoginScreen.dart';
import 'package:ono/Screen/User/MyPageScreen.dart';
import 'package:ono/Screen/User/Widget/ReviewReportScreen.dart';
import 'package:ono/Screen/User/Widget/StreakCard.dart';
import 'package:ono/Screen/User/Widget/UserLevelCard.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

class _MockNavigatorObserver extends Mock implements NavigatorObserver {}

class _FakeRoute extends Fake implements Route<dynamic> {}

/// MyPageScreen(파일명) 의 위젯 클래스 이름은 SettingScreen 이다.
void main() {
  setUpOnoWidgetTest();

  setUpAll(() {
    registerFallbackValue(_FakeRoute());
  });

  setUp(() {
    // StreakCard 가 화면 본문에 그대로 붙어 있어, 로그인 상태를 그리는 테스트는
    // 전부 내부에서 SharedPreferences.getInstance() 를 탄다. 목 초기값을 깔아
    // 두지 않으면 플랫폼 채널이 없어 MissingPluginException 이 조용히 새어나간다.
    SharedPreferences.setMockInitialValues({});
  });

  UserInfoModel buildUserInfo({
    String? name = '테스터',
    String? profileImageUrl,
    bool notificationEnabled = true,
    int userId = 1,
  }) {
    return UserInfoModel(
      userId: userId,
      name: name,
      profileImageUrl: profileImageUrl,
      notificationEnabled: notificationEnabled,
    );
  }

  _FakeUserProvider buildLoggedOutUserProvider() {
    final provider = _FakeUserProvider();
    when(() => provider.isLoggedIn).thenReturn(LoginStatus.logout);
    when(() => provider.loginStatus).thenReturn(LoginStatus.logout);
    when(() => provider.userInfoModel).thenReturn(null);
    when(() => provider.addListener(any())).thenReturn(null);
    when(() => provider.removeListener(any())).thenReturn(null);
    when(() => provider.dispose()).thenReturn(null);
    return provider;
  }

  _FakeUserProvider buildLoggedInUserProvider({UserInfoModel? info}) {
    final provider = _FakeUserProvider();
    final userInfo = info ?? buildUserInfo();
    when(() => provider.isLoggedIn).thenReturn(LoginStatus.login);
    when(() => provider.loginStatus).thenReturn(LoginStatus.login);
    when(() => provider.userInfoModel).thenReturn(userInfo);
    when(() => provider.addListener(any())).thenReturn(null);
    when(() => provider.removeListener(any())).thenReturn(null);
    when(() => provider.dispose()).thenReturn(null);
    when(() => provider.fetchUserInfo()).thenAnswer((_) async {});
    // signOut / deleteAccount 는 실제 Provider 처럼, 성공하면 로그인 상태를
    // logout 으로 바꿔 둔다. 그래야 이후 LoginScreen 이 다시 로그인 상태로
    // 오인해 MyHomePage 로 자동 리다이렉트하지 않는다.
    when(() => provider.signOut()).thenAnswer((_) async {
      when(() => provider.loginStatus).thenReturn(LoginStatus.logout);
      when(() => provider.isLoggedIn).thenReturn(LoginStatus.logout);
    });
    when(() => provider.deleteAccount()).thenAnswer((_) async {
      when(() => provider.loginStatus).thenReturn(LoginStatus.logout);
      when(() => provider.isLoggedIn).thenReturn(LoginStatus.logout);
    });
    return provider;
  }

  /// 설정 화면으로 진입해 AccountActionButtons 의 확인 다이얼로그를 연다.
  Future<void> openAccountActionDialog(
    WidgetTester tester,
    String buttonText,
  ) async {
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.text(buttonText));
    await tester.pumpAndSettle();
  }

  group('비로그인 상태', () {
    testWidgets('로그인 안내 문구만 보이고 학습 기록 위젯은 없다', (tester) async {
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: buildLoggedOutUserProvider(),
        );
      });

      expect(find.text('로그인을 통해 설정을 변경해보세요!'), findsOneWidget);
      expect(find.byType(UserLevelCard), findsNothing);
      expect(find.byType(StreakCard), findsNothing);
      expect(find.text('학습 리포트'), findsNothing);
    });
  });

  group('로그인 상태', () {
    testWidgets('사용자 이름과 학습 리포트 카드가 보인다', (tester) async {
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: buildLoggedInUserProvider(
            info: buildUserInfo(name: '오노프렌즈'),
          ),
        );
      });

      expect(find.textContaining('오노프렌즈님의 학습 기록'), findsOneWidget);
      expect(find.text('학습 리포트'), findsOneWidget);
      expect(find.byType(UserLevelCard), findsOneWidget);
      expect(find.byType(StreakCard), findsOneWidget);
    });

    testWidgets('이름이 없으면 기본 문구로 대체된다', (tester) async {
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: buildLoggedInUserProvider(
            info: buildUserInfo(name: null),
          ),
        );
      });

      expect(find.textContaining('이름 없음님의 학습 기록'), findsOneWidget);
    });

    testWidgets('학습 리포트 카드를 탭하면 ReviewReportScreen 으로 이동한다', (tester) async {
      final navigatorObserver = _MockNavigatorObserver();
      when(() => navigatorObserver.didPush(any(), any())).thenReturn(null);

      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: buildLoggedInUserProvider(),
          navigatorObservers: [navigatorObserver],
        );
      });

      await tester.tap(find.text('학습 리포트'));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewReportScreen), findsOneWidget);
    });

    testWidgets('설정 아이콘을 탭하면 프로필과 계정 메뉴가 보인다', (tester) async {
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: buildLoggedInUserProvider(
            info: buildUserInfo(name: '오노프렌즈'),
          ),
        );
      });

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('설정'), findsOneWidget);
      expect(find.text('오노프렌즈'), findsOneWidget);
      expect(find.text('로그아웃'), findsOneWidget);
      expect(find.text('회원 탈퇴'), findsOneWidget);
    });

    testWidgets('태블릿 세로 크기에서도 예외 없이 그려진다', (tester) async {
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: buildLoggedInUserProvider(),
          surfaceSize: OnoSurface.tablet,
        );
      });

      expect(tester.takeException(), isNull);
      expect(find.byType(UserLevelCard), findsOneWidget);
      expect(find.byType(StreakCard), findsOneWidget);
    });

    testWidgets('태블릿 가로 크기에서는 카드가 한 줄로 배치되고 예외가 없다', (tester) async {
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: buildLoggedInUserProvider(),
          // 가로 폭이 세로보다 큰 태블릿: isTabletLandscape 분기를 탄다.
          surfaceSize: const Size(1194, 834),
        );
      });

      expect(tester.takeException(), isNull);
      expect(find.byType(UserLevelCard), findsOneWidget);
      expect(find.byType(StreakCard), findsOneWidget);
    });
  });

  group('로그아웃 — 되돌릴 수 없는 동작 확인', () {
    testWidgets('로그아웃을 탭하면 확인 다이얼로그가 뜬다', (tester) async {
      final userProvider = buildLoggedInUserProvider();

      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: userProvider,
        );
      });

      await openAccountActionDialog(tester, '로그아웃');

      expect(find.textContaining('정말 로그아웃 하시겠습니까'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('취소를 누르면 signOut 이 호출되지 않는다', (tester) async {
      final userProvider = buildLoggedInUserProvider();

      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: userProvider,
        );
      });

      await openAccountActionDialog(tester, '로그아웃');

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(() => userProvider.signOut());
      // 다이얼로그가 닫히고 설정 화면은 그대로 남아 있다.
      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('확인을 누르면 signOut 이 호출되고 로그인 화면으로 전환된다', (tester) async {
      final userProvider = buildLoggedInUserProvider();

      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: userProvider,
        );
      });

      await openAccountActionDialog(tester, '로그아웃');

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      verify(() => userProvider.signOut()).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('회원 탈퇴 — 되돌릴 수 없는 동작 확인', () {
    testWidgets('회원 탈퇴를 탭하면 확인 다이얼로그가 뜬다', (tester) async {
      final userProvider = buildLoggedInUserProvider();

      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: userProvider,
        );
      });

      await openAccountActionDialog(tester, '회원 탈퇴');

      expect(find.textContaining('이 작업은 되돌릴 수 없습니다'), findsOneWidget);
    });

    testWidgets('취소를 누르면 deleteAccount 가 호출되지 않는다', (tester) async {
      final userProvider = buildLoggedInUserProvider();

      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: userProvider,
        );
      });

      await openAccountActionDialog(tester, '회원 탈퇴');

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(() => userProvider.deleteAccount());
      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('확인을 누르면 deleteAccount 가 호출되고 로그인 화면으로 전환된다', (tester) async {
      final userProvider = buildLoggedInUserProvider();

      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          const SettingScreen(),
          userProvider: userProvider,
        );
      });

      await openAccountActionDialog(tester, '회원 탈퇴');

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      verify(() => userProvider.deleteAccount()).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
