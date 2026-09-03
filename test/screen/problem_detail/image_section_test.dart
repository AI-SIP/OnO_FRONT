import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/ProblemDetail/Widget/ImageGallerySection.dart';
import 'package:ono/Screen/ProblemDetail/Widget/ImageSection.dart';

import '../../helpers/helpers.dart';

Widget _wrap(Widget child) => Scaffold(body: child);

void main() {
  setUpOnoWidgetTest();

  late ThemeHandler theme;

  setUp(() {
    theme = ThemeHandler();
  });

  testWidgets('이미지 목록이 비어 있으면 안내 문구를 보여준다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildImageSection(context, const [], '문제 이미지', theme)),
      ),
    );

    expect(find.text('문제 이미지가 없습니다.'), findsOneWidget);
    expect(find.byType(ImageGallerySection), findsNothing);
  });

  testWidgets('라벨이 바뀌면 안내 문구도 함께 바뀐다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildImageSection(context, const [], '해설 이미지', theme)),
      ),
    );

    expect(find.text('해설 이미지가 없습니다.'), findsOneWidget);
  });

  testWidgets('이미지가 있으면 ImageGallerySection 을 그린다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) => _wrap(buildImageSection(
            context,
            const ['https://example.com/a.png'],
            '문제 이미지',
            theme,
          )),
        ),
      );
    });

    expect(find.byType(ImageGallerySection), findsOneWidget);
    expect(find.text('문제 이미지가 없습니다.'), findsNothing);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) => _wrap(buildImageSection(
            context,
            const ['https://example.com/a.png'],
            '문제 이미지',
            theme,
          )),
        ),
        surfaceSize: OnoSurface.tablet,
      );
    });

    expect(tester.takeException(), isNull);
  });
}
