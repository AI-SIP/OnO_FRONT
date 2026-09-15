// 마이페이지(설정 화면) 골든 테스트.
//
// 스트릭 카드의 `2026년 9월 학습 달력` 머리글이 지금 시각에 매여 있어서 골든
// 시계(goldenNow) 로 고정된 채 뜬다. 달력 자료는 서버에서 받는데 이 테스트에서는
// 받지 못해서 머리글만 그려진다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/User/MyPageScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '마이페이지',
    fileName: 'my_page_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: () async {
      // 스트릭 카드가 SharedPreferences 를 읽는다. 목 초기값이 없으면 플랫폼
      // 채널이 없어 MissingPluginException 이 난다.
      SharedPreferences.setMockInitialValues({});

      final userProvider = _FakeUserProvider();
      when(() => userProvider.isLoggedIn).thenReturn(LoginStatus.login);
      when(() => userProvider.loginStatus).thenReturn(LoginStatus.login);
      when(() => userProvider.userInfoModel).thenReturn(
        UserInfoModel(userId: 1, name: '오노프렌즈', notificationEnabled: true),
      );
      when(() => userProvider.addListener(any())).thenReturn(null);
      when(() => userProvider.removeListener(any())).thenReturn(null);
      when(() => userProvider.dispose()).thenReturn(null);
      when(() => userProvider.fetchUserInfo()).thenAnswer((_) async {});

      return buildOnoApp(
        const SettingScreen(),
        cosmeticProvider: await loadedCosmeticProvider(),
        userProvider: userProvider,
      );
    },
  );
}
