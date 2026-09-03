import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/User/Widget/ThemeChangeButton.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  Future<void> pumpThemeButton(
    WidgetTester tester, {
    required VoidCallback onTap,
    bool compact = false,
    double horizontalMarginFactor = 0.04,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: ThemeChangeButton(
          themeProvider: ThemeHandler(),
          onTap: onTap,
          compact: compact,
          horizontalMarginFactor: horizontalMarginFactor,
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('기본(compact 아님) 모드에서는 제목과 설명이 보인다', (tester) async {
    await pumpThemeButton(tester, onTap: () {});

    expect(find.text('테마 변경'), findsOneWidget);
    expect(find.text('오답노트의 템플릿 색상을 변경하세요'), findsOneWidget);
  });

  testWidgets('compact 모드에서는 줄바꿈 제목만 있고 설명은 없다', (tester) async {
    await pumpThemeButton(tester, onTap: () {}, compact: true);

    expect(find.text('테마\n변경'), findsOneWidget);
    expect(find.text('테마 변경'), findsNothing);
    expect(find.text('오답노트의 템플릿 색상을 변경하세요'), findsNothing);
  });

  testWidgets('탭하면 onTap 이 호출된다', (tester) async {
    var tapCount = 0;

    await pumpThemeButton(tester, onTap: () => tapCount++);

    await tester.tap(find.byType(ThemeChangeButton));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('여러 번 탭하면 그만큼 호출된다', (tester) async {
    var tapCount = 0;

    await pumpThemeButton(tester, onTap: () => tapCount++);

    await tester.tap(find.byType(ThemeChangeButton));
    await tester.pump();
    await tester.tap(find.byType(ThemeChangeButton));
    await tester.pump();

    expect(tapCount, 2);
  });

  testWidgets('가로 여백 비율이 극단적으로 커도 예외 없이 그려진다', (tester) async {
    await pumpThemeButton(tester, onTap: () {}, horizontalMarginFactor: 0.3);

    expect(tester.takeException(), isNull);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpThemeButton(
      tester,
      onTap: () {},
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ThemeChangeButton), findsOneWidget);
  });

  testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpThemeButton(
      tester,
      onTap: () {},
      surfaceSize: OnoSurface.smallPhone,
    );

    expect(tester.takeException(), isNull);
  });
}
