import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Image/FullScreenImage.dart';
import 'package:ono/Module/Image/ImageCompareScreen.dart';

import '../../helpers/helpers.dart';

/// 내 풀이와 문제, 정답을 칩으로 오가며 보고, 넓은 화면에서는 나란히 두는지 본다.
void main() {
  setUpOnoWidgetTest();

  const groups = [
    ImageCompareGroup(
        label: '내 풀이', imagePaths: ['https://test.ono.local/s.png']),
    ImageCompareGroup(
        label: '문제', imagePaths: ['https://test.ono.local/p.png']),
    ImageCompareGroup(label: '정답', imagePaths: []),
  ];

  testWidgets('빈 묶음은 빼고 칩으로 바꿔 본다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const ImageCompareScreen(groups: groups),
        settle: false,
      );
      await tester.pump();

      expect(find.text('내 풀이 1'), findsOneWidget);
      expect(find.text('문제 1'), findsOneWidget);
      expect(find.text('정답 0'), findsNothing);
      expect(find.byType(FullScreenImage), findsOneWidget);

      await tester.tap(find.text('문제 1'));
      await tester.pump();
    });

    expect(
      tester.widget<FullScreenImage>(find.byType(FullScreenImage)).imagePaths,
      ['https://test.ono.local/p.png'],
    );
  });

  testWidgets('넓은 화면에서는 두 묶음을 나란히 둔다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const ImageCompareScreen(groups: groups),
        surfaceSize: const Size(1194, 834),
        settle: false,
      );
      await tester.pump();
    });

    expect(find.byType(FullScreenImage), findsNWidgets(2));
  });
}
