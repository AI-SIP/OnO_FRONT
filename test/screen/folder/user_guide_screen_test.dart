import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/Folder/UserGuideScreen.dart';

import '../../helpers/helpers.dart';

/// [test/screen/user/login_screen_test.dart] 의 모양을 따라간다.
void main() {
  setUpOnoWidgetTest();

  /// SvgPicture 안의 에셋 경로로 찾는다. 화면마다 안내 이미지가 하나씩이라
  /// 페이지가 바뀔 때마다 다른 경로를 찾아야 한다.
  Finder svgAsset(String path) => find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.bytesLoader is SvgAssetLoader &&
            (widget.bytesLoader as SvgAssetLoader).assetName == path,
      );

  testWidgets('처음 진입하면 첫 번째 안내 페이지가 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      UserGuideScreen(onFinish: () {}),
    );

    expect(find.text('OnO, 이렇게 사용하세요'), findsOneWidget);
    expect(svgAsset('assets/GuideScreen/GuideScreen1.svg'), findsOneWidget);
    expect(find.text('OnO에 오신걸 환영합니다!'), findsOneWidget);
    expect(find.textContaining('나만의 진정한 오답노트를 작성해보아요'), findsOneWidget);
  });

  testWidgets('첫 페이지에서는 다음 버튼이 보이고 확인 버튼은 보이지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      UserGuideScreen(onFinish: () {}),
    );

    expect(find.widgetWithText(ElevatedButton, '다음'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '확인'), findsNothing);
  });

  testWidgets('다음 버튼을 누르면 두 번째 안내 페이지로 넘어간다', (tester) async {
    await pumpOnoWidget(
      tester,
      UserGuideScreen(onFinish: () {}),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, '다음'));
    await tester.pumpAndSettle();

    expect(svgAsset('assets/GuideScreen/GuideScreen2.svg'), findsOneWidget);
    expect(find.text('오답노트 등록'), findsOneWidget);
    expect(find.text('OnO에 오신걸 환영합니다!'), findsNothing);
  });

  testWidgets('마지막 페이지까지 넘기면 확인 버튼으로 바뀐다', (tester) async {
    await pumpOnoWidget(
      tester,
      UserGuideScreen(onFinish: () {}),
    );

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.widgetWithText(ElevatedButton, '다음'));
      await tester.pumpAndSettle();
    }

    expect(find.text('이제 복습을 시작해볼까요?'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '확인'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '다음'), findsNothing);
  });

  testWidgets('마지막 페이지가 아니면 확인 버튼을 눌러도 onFinish 가 불리지 않는다', (tester) async {
    var finished = false;
    await pumpOnoWidget(
      tester,
      UserGuideScreen(onFinish: () => finished = true),
    );

    // 첫 페이지에서는 '다음' 버튼만 있으므로 onFinish 호출 경로 자체가 없다.
    await tester.tap(find.widgetWithText(ElevatedButton, '다음'));
    await tester.pumpAndSettle();

    expect(finished, isFalse);
  });

  testWidgets('마지막 페이지에서 확인 버튼을 누르면 onFinish 콜백이 불린다', (tester) async {
    var finished = false;
    await pumpOnoWidget(
      tester,
      UserGuideScreen(onFinish: () => finished = true),
    );

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.widgetWithText(ElevatedButton, '다음'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });

  testWidgets('페이지 인디케이터는 다섯 개이고 현재 페이지만 넓게 표시된다', (tester) async {
    await pumpOnoWidget(
      tester,
      UserGuideScreen(onFinish: () {}),
    );

    final indicators = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(Row).first,
        matching: find.byType(Container),
      ),
    );

    expect(indicators.length, 5);
    final widths = indicators.map((c) => c.constraints?.maxWidth).toList();
    // 활성 인디케이터(12.0)가 하나, 나머지 네 개는 비활성(8.0)이어야 한다.
    expect(widths.where((w) => w == 12.0).length, 1);
    expect(widths.where((w) => w == 8.0).length, 4);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpOnoWidget(
      tester,
      UserGuideScreen(onFinish: () {}),
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(UserGuideScreen), findsOneWidget);
  });

  testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpOnoWidget(
      tester,
      UserGuideScreen(onFinish: () {}),
      surfaceSize: OnoSurface.smallPhone,
    );

    expect(tester.takeException(), isNull);
  });
}
