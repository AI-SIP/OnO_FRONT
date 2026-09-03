import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemRegister/Widget/ActionButtons.dart';

import '../../helpers/helpers.dart';

/// 기준 파일 test/screen/user/login_screen_test.dart 의 모양을 따라간다.
void main() {
  setUpOnoWidgetTest();

  testWidgets('신규 등록 모드에서는 "작성 완료" 문구가 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      ActionButtons(isEdit: false, onCancel: () {}, onSubmit: () {}),
    );

    expect(find.text('작성 완료'), findsOneWidget);
    expect(find.text('수정 완료'), findsNothing);
  });

  testWidgets('편집 모드에서는 "수정 완료" 문구가 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      ActionButtons(isEdit: true, onCancel: () {}, onSubmit: () {}),
    );

    expect(find.text('수정 완료'), findsOneWidget);
    expect(find.text('작성 완료'), findsNothing);
  });

  testWidgets('버튼을 탭하면 onSubmit 콜백이 불린다', (tester) async {
    var submitCount = 0;
    await pumpOnoWidget(
      tester,
      ActionButtons(
        isEdit: false,
        onCancel: () {},
        onSubmit: () => submitCount++,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(submitCount, 1);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpOnoWidget(
      tester,
      ActionButtons(isEdit: false, onCancel: () {}, onSubmit: () {}),
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
