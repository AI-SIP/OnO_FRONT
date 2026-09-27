import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Design/AppToast.dart';
import 'package:ono/Util/AppNavigator.dart';

import '../../helpers/helpers.dart';

/// lib/Module/Design/AppToast.dart 의 표시 시간 규칙을 검증한다.
///
/// 그동안 부르는 쪽마다 `duration` 을 적어서 같은 성격인데도 2초와 3초가
/// 섞여 있었다. 이제 성격이 시간을 정한다 (#279). 잘 됐다는 말은 읽지 않아도
/// 그만이라 짧게 지나가고, 잘못됐다는 말과 주의는 길게 남는다.
void main() {
  setUpOnoTest();

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
  }

  /// 앞 테스트에서 띄운 토스트가 남아 다음 테스트에 섞이지 않게 한다.
  Future<void> detach(WidgetTester tester) async {
    AppToast.dismiss();
    await tester.pumpWidget(const SizedBox.shrink());
  }

  /// 같은 문구가 800ms 안에 다시 오면 무시되므로 테스트마다 다른 문구를 쓴다.
  testWidgets('성공 알림은 2초 뒤에 사라진다', (tester) async {
    await pumpApp(tester);

    AppToast.success('성공 알림 시간');
    await tester.pump();
    expect(find.text('성공 알림 시간'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.text('성공 알림 시간'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('성공 알림 시간'), findsNothing);

    await detach(tester);
  });

  testWidgets('오류 알림은 3초까지 남는다', (tester) async {
    await pumpApp(tester);

    AppToast.error('오류 알림 시간');
    await tester.pump();

    // 성공이었다면 이미 사라졌을 시점에도 그대로 있어야 한다.
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('오류 알림 시간'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('오류 알림 시간'), findsNothing);

    await detach(tester);
  });

  testWidgets('주의 알림도 오류와 같은 시간을 쓴다', (tester) async {
    await pumpApp(tester);

    AppToast.info('주의 알림 시간');
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('주의 알림 시간'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('주의 알림 시간'), findsNothing);

    await detach(tester);
  });

  testWidgets('duration 을 직접 주면 규칙보다 그것을 따른다', (tester) async {
    await pumpApp(tester);

    AppToast.show(
      message: '직접 준 시간',
      type: ToastType.success,
      duration: const Duration(seconds: 5),
    );
    await tester.pump();

    // 성공 기본값인 2초가 지나도 사라지지 않는다.
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('직접 준 시간'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    expect(find.text('직접 준 시간'), findsNothing);

    await detach(tester);
  });
}
