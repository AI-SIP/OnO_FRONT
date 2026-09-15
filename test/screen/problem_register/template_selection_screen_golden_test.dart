// 템플릿 선택 화면 골든 테스트.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/ProblemRegister/TemplateSelectionScreen.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '템플릿 선택 화면',
    fileName: 'template_selection_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: () async {
      final userProvider = _FakeUserProvider();
      when(() => userProvider.isLoggedIn).thenReturn(LoginStatus.login);
      when(() => userProvider.addListener(any())).thenReturn(null);
      when(() => userProvider.removeListener(any())).thenReturn(null);
      when(() => userProvider.dispose()).thenReturn(null);

      return buildOnoApp(
        const TemplateSelectionScreen(),
        cosmeticProvider: await loadedCosmeticProvider(),
        userProvider: userProvider,
      );
    },
  );
}
