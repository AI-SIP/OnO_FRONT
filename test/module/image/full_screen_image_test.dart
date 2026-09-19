// 이미지 상세 화면(FullScreenImage) 테스트.
//
// 한 문제에 여러 장을 올렸을 때 그 자리에서 앞뒤로 넘길 수 있는지 본다.
// 전에는 이미지 하나만 받아서 두 번째 장을 보려면 뒤로 나갔다 들어와야 했다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Image/FullScreenImage.dart';

import '../../helpers/helpers.dart';

const _urls = [
  'https://example.com/a.png',
  'https://example.com/b.png',
  'https://example.com/c.png',
];

Future<void> _pump(
  WidgetTester tester, {
  List<String> imagePaths = _urls,
  int initialIndex = 0,
  Size surfaceSize = OnoSurface.phone,
}) async {
  await withMockedNetworkImages(() async {
    await pumpOnoWidget(
      tester,
      FullScreenImage(imagePaths: imagePaths, initialIndex: initialIndex),
      surfaceSize: surfaceSize,
      // 이미지를 기다리는 동그라미가 끝나지 않아서 settle 이 시간 초과난다.
      settle: false,
    );
  });
  await tester.pump();
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('넘긴 자리에서 시작한다', (tester) async {
    await _pump(tester, initialIndex: 1);

    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('옆으로 밀면 다음 장으로 넘어간다', (tester) async {
    await _pump(tester);
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('되돌아가는 방향으로도 넘어간다', (tester) async {
    await _pump(tester, initialIndex: 2);
    expect(find.text('3 / 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('아래 썸네일을 누르면 그 장으로 간다', (tester) async {
    await _pump(tester);

    // 썸네일 줄은 이미지 수만큼 있다. 마지막 것을 누른다.
    final thumbnails = find.byType(AnimatedContainer);
    expect(thumbnails, findsNWidgets(_urls.length));

    await tester.tap(thumbnails.last);
    // 한 번은 애니메이션을 걸고, 한 번은 끝까지 흘려 보낸다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('한 장뿐이면 장수 표시와 썸네일 줄을 두지 않는다', (tester) async {
    await _pump(tester, imagePaths: const ['https://example.com/only.png']);

    expect(find.text('1 / 1'), findsNothing);
    expect(find.byType(AnimatedContainer), findsNothing);
  });

  testWidgets('single 생성자는 빈 주소를 한 장으로 세지 않는다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        FullScreenImage.single(null),
        settle: false,
      );
    });
    await tester.pump();

    expect(find.byType(PageView), findsNothing);
    expect(find.text('이미지를 불러오지 못했습니다'), findsOneWidget);
  });

  testWidgets('화면을 누르면 위아래 버튼이 사라진다', (tester) async {
    await _pump(tester);

    double chromeOpacity() => tester
        .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
        .first
        .opacity;

    expect(chromeOpacity(), 1.0);

    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    await tester.pump(const Duration(milliseconds: 400));

    expect(chromeOpacity(), 0.0);
  });

  testWidgets('태블릿에서도 같은 방식으로 넘어간다', (tester) async {
    await _pump(tester, surfaceSize: OnoSurface.tablet);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2 / 3'), findsOneWidget);
  });
}
