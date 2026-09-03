import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/ProblemRegister/TemplateSelectionScreen.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

/// SvgPicture 를 에셋 경로로 찾는다. 상단 탭과 본문 이미지가 같은 SVG 를 쓸 수
/// 있으니, 화면에 실제로 그려져 있는 것만 잡힌다는 점을 이용한다.
Finder _svgAsset(String path) => find.byWidgetPredicate(
      (widget) =>
          widget is SvgPicture &&
          widget.bytesLoader is SvgAssetLoader &&
          (widget.bytesLoader as SvgAssetLoader).assetName == path,
    );

void main() {
  setUpOnoWidgetTest();

  late _FakeUserProvider userProvider;

  setUp(() {
    userProvider = _FakeUserProvider();
    when(() => userProvider.isLoggedIn).thenReturn(LoginStatus.login);
    when(() => userProvider.addListener(any())).thenReturn(null);
    when(() => userProvider.removeListener(any())).thenReturn(null);
    when(() => userProvider.dispose()).thenReturn(null);
  });

  testWidgets('기본으로 길잡이 템플릿(3번째 탭)이 선택되어 있다', (tester) async {
    await pumpOnoWidget(
      tester,
      const TemplateSelectionScreen(),
      userProvider: userProvider,
    );

    expect(find.text('길잡이 템플릿'), findsOneWidget);
    expect(
      find.textContaining('문제 분석을 통해 나의 취약점을 알아보아요'),
      findsOneWidget,
    );
  });

  testWidgets('설명 문구와 해시태그, 특징 태그가 함께 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      const TemplateSelectionScreen(),
      userProvider: userProvider,
    );

    expect(find.text('#AI 분석'), findsOneWidget);
    expect(find.text('필기 제거'), findsOneWidget);
    expect(find.text('문제 분석'), findsOneWidget);
  });

  testWidgets('상단 탭을 탭하면 해당 템플릿으로 전환된다', (tester) async {
    await pumpOnoWidget(
      tester,
      const TemplateSelectionScreen(),
      userProvider: userProvider,
    );

    expect(find.text('길잡이 템플릿'), findsOneWidget);

    // 상단 탭의 "암기왕"(simple) 아이콘을 감싼 GestureDetector 를 탭한다.
    final simpleTabIcon = _svgAsset('assets/Icon/PencilDetail.svg');
    expect(simpleTabIcon, findsOneWidget);
    await tester.tap(
      find.ancestor(
        of: simpleTabIcon,
        matching: find.byType(GestureDetector),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('암기왕 템플릿'), findsOneWidget);
  });

  testWidgets('오른쪽 화살표를 탭하면 다음 템플릿 설명으로 바뀐다', (tester) async {
    await pumpOnoWidget(
      tester,
      const TemplateSelectionScreen(),
      userProvider: userProvider,
    );

    expect(find.text('길잡이 템플릿'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_forward_ios));
    await tester.pumpAndSettle();

    expect(find.text('암기왕 템플릿'), findsOneWidget);
  });

  testWidgets('왼쪽 화살표를 탭하면 이전 템플릿 설명으로 바뀐다', (tester) async {
    await pumpOnoWidget(
      tester,
      const TemplateSelectionScreen(),
      userProvider: userProvider,
    );

    expect(find.text('길잡이 템플릿'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();

    expect(find.text('문풀왕 템플릿'), findsOneWidget);
  });

  testWidgets('로그인하지 않은 상태에서 작성 버튼을 누르면 로그인 안내 스낵바가 뜬다', (tester) async {
    when(() => userProvider.isLoggedIn).thenReturn(LoginStatus.logout);

    await pumpOnoWidget(
      tester,
      const TemplateSelectionScreen(),
      userProvider: userProvider,
    );

    await tester.tap(find.text('오답노트 작성하러 가기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('로그인 후에 오답노트를 작성할 수 있습니다!'), findsOneWidget);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpOnoWidget(
      tester,
      const TemplateSelectionScreen(),
      userProvider: userProvider,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
