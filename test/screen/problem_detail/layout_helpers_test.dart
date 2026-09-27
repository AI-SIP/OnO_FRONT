import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemDetail/Widget/LayoutHelpers.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  testWidgets('withPadding 은 자식을 스크롤 가능한 상태로 감싼다', (tester) async {
    late BuildContext capturedContext;

    await pumpOnoWidget(
      tester,
      Builder(builder: (context) {
        capturedContext = context;
        return Scaffold(
          body: withPadding(context, const Text('본문')),
        );
      }),
    );

    expect(find.text('본문'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    // capturedContext 는 build 도중 캡처만 하고 별도로 쓰진 않는다.
    expect(capturedContext.mounted, isTrue);
  });

  testWidgets('verticalSpacer 는 화면 높이 비율만큼 SizedBox 를 만든다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(builder: (context) {
        return Scaffold(
          body: verticalSpacer(context, .5),
        );
      }),
    );

    final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
    // OnoSurface.phone 높이(844)의 절반.
    expect(sizedBox.height, closeTo(844 * .5, 0.5));
  });

  testWidgets('tileTitle 은 아이콘과 텍스트를 함께 보여준다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(builder: (context) {
        return Scaffold(
          body: tileTitle(context, '정답 확인', Colors.pink),
        );
      }),
    );

    expect(find.text('정답 확인'), findsOneWidget);
    expect(find.byIcon(Icons.touch_app), findsOneWidget);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(builder: (context) {
        return Scaffold(
          body: tileTitle(context, '정답 확인', Colors.pink),
        );
      }),
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
