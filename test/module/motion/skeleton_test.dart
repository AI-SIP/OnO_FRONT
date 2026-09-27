// Skeleton 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/Skeleton.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  testWidgets('animate 가 false 면 흐르는 효과 없이 회색으로만 둔다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: SkeletonBox(height: 20, width: 100, animate: false),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, isNotNull);
  });

  testWidgets('animate 가 true 면 빛이 흐르고 시간이 지나면 위치가 바뀐다', (tester) async {
    // 끝나지 않는 애니메이션이라 settle 하면 타임아웃난다.
    await pumpOnoWidget(
      tester,
      const Scaffold(body: SkeletonBox(height: 20, width: 100)),
      settle: false,
    );

    Alignment beginOf(WidgetTester tester) {
      final container = tester.widget<Container>(find.byType(Container));
      final gradient =
          (container.decoration! as BoxDecoration).gradient! as LinearGradient;
      return gradient.begin as Alignment;
    }

    final first = beginOf(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(beginOf(tester), isNot(first));
  });

  testWidgets('animate 를 끄면 애니메이션이 멈춰 settle 이 끝난다', (tester) async {
    // 화면 테스트에서 로딩 상태를 지나쳐야 할 때 쓰는 길이다.
    await pumpOnoWidget(
      tester,
      const Scaffold(
        body: SkeletonBox(height: 20, width: 100, animate: false),
      ),
    );

    expect(find.byType(SkeletonBox), findsOneWidget);
  });

  group('SkeletonList', () {
    testWidgets('지정한 줄 수만큼 그린다', (tester) async {
      await pumpOnoWidget(
        tester,
        const Scaffold(body: SkeletonList(itemCount: 4, animate: false)),
      );

      expect(find.byType(SkeletonBox), findsNWidgets(4));
    });

    testWidgets('줄 높이를 실제 항목 높이에 맞출 수 있다', (tester) async {
      await pumpOnoWidget(
        tester,
        const Scaffold(
          body: SkeletonList(itemCount: 2, itemHeight: 90, animate: false),
        ),
      );

      final boxes = tester.widgetList<SkeletonBox>(find.byType(SkeletonBox));
      expect(boxes.every((box) => box.height == 90), isTrue);
    });
  });
}
