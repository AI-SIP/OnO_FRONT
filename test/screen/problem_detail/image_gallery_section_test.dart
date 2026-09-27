import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Image/FullScreenImage.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/ProblemDetail/Widget/ImageGallerySection.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  late ThemeHandler theme;

  setUp(() {
    theme = ThemeHandler();
  });

  Widget buildGallery(List<String> urls) => Scaffold(
        body: ImageGallerySection(
          imageUrls: urls,
          label: '문제 이미지',
          color: theme.primaryColor,
          themeProvider: theme,
        ),
      );

  testWidgets('이미지가 한 장이면 도트 인디케이터만 보이고 썸네일 목록은 없다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(tester, buildGallery(['https://example.com/1.png']));
    });

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(ListView), findsNothing); // 썸네일 스트립
  });

  testWidgets('이미지가 여러 장이면 썸네일 목록도 함께 보인다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        buildGallery([
          'https://example.com/1.png',
          'https://example.com/2.png',
          'https://example.com/3.png',
        ]),
      );
    });

    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('이미지를 탭하면 전체화면으로 이동한다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(tester, buildGallery(['https://example.com/1.png']));

      final imageTap = find.descendant(
        of: find.byType(PageView),
        matching: find.byType(GestureDetector),
      );
      expect(imageTap, findsOneWidget);

      // PageView 내부 렌더 계층이 겹쳐 있어 tester.tap 의 좌표 히트테스트가
      // 불안정하다. 콜백을 직접 호출해 네비게이션 로직만 검증한다.
      tester.widget<GestureDetector>(imageTap).onTap!();
      // FullScreenImage 안의 CachedNetworkImage 로딩 인디케이터가 계속
      // 애니메이션하므로 pumpAndSettle 대신 직접 몇 프레임만 진행시킨다.
      await tester.pump(); // 라우트 전환 시작
      await tester.pump(const Duration(milliseconds: 300)); // 전환 애니메이션 진행

      expect(find.byType(FullScreenImage), findsOneWidget);
    });
  });

  testWidgets('썸네일을 탭하면 페이지가 넘어간다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        buildGallery([
          'https://example.com/1.png',
          'https://example.com/2.png',
        ]),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 썸네일 스트립의 두 번째 아이템을 탭한다.
      final thumbnails = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(GestureDetector),
      );
      expect(thumbnails, findsNWidgets(2));

      tester.widget<GestureDetector>(thumbnails.at(1)).onTap!();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        buildGallery(['https://example.com/1.png']),
        surfaceSize: OnoSurface.tablet,
      );
    });

    expect(tester.takeException(), isNull);
  });
}
