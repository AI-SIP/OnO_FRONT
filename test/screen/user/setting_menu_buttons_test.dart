import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/User/Widget/SettingMenuButtons.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  Future<void> pumpMenu(
    WidgetTester tester, {
    required bool notificationEnabled,
    required VoidCallback onGuideTap,
    required VoidCallback onFeedbackTap,
    required VoidCallback onTermsTap,
    required ValueChanged<bool> onNotificationChanged,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: SettingMenuButtons(
          themeProvider: ThemeHandler(),
          onGuideTap: onGuideTap,
          onFeedbackTap: onFeedbackTap,
          onTermsTap: onTermsTap,
          notificationEnabled: notificationEnabled,
          onNotificationChanged: onNotificationChanged,
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('메뉴 4개가 모두 보인다', (tester) async {
    await pumpMenu(
      tester,
      notificationEnabled: true,
      onGuideTap: () {},
      onFeedbackTap: () {},
      onTermsTap: () {},
      onNotificationChanged: (_) {},
    );

    expect(find.text('복습 알림'), findsOneWidget);
    expect(find.text('OnO 가이드'), findsOneWidget);
    expect(find.text('의견 남기기'), findsOneWidget);
    expect(find.text('OnO 이용약관'), findsOneWidget);
  });

  testWidgets('notificationEnabled 값이 스위치에 그대로 반영된다', (tester) async {
    await pumpMenu(
      tester,
      notificationEnabled: true,
      onGuideTap: () {},
      onFeedbackTap: () {},
      onTermsTap: () {},
      onNotificationChanged: (_) {},
    );

    final onSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(onSwitch.value, isTrue);
  });

  testWidgets('알림이 꺼진 상태도 반영된다', (tester) async {
    await pumpMenu(
      tester,
      notificationEnabled: false,
      onGuideTap: () {},
      onFeedbackTap: () {},
      onTermsTap: () {},
      onNotificationChanged: (_) {},
    );

    final offSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(offSwitch.value, isFalse);
  });

  testWidgets('스위치를 탭하면 반대 값으로 onNotificationChanged 가 불린다', (tester) async {
    bool? changedTo;

    await pumpMenu(
      tester,
      notificationEnabled: true,
      onGuideTap: () {},
      onFeedbackTap: () {},
      onTermsTap: () {},
      onNotificationChanged: (value) => changedTo = value,
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(changedTo, isFalse);
  });

  testWidgets('OnO 가이드를 탭하면 onGuideTap 이 불린다', (tester) async {
    var guideCalled = 0;

    await pumpMenu(
      tester,
      notificationEnabled: true,
      onGuideTap: () => guideCalled++,
      onFeedbackTap: () {},
      onTermsTap: () {},
      onNotificationChanged: (_) {},
    );

    await tester.tap(find.text('OnO 가이드'));
    await tester.pump();

    expect(guideCalled, 1);
  });

  testWidgets('의견 남기기를 탭하면 onFeedbackTap 이 불린다', (tester) async {
    var feedbackCalled = 0;

    await pumpMenu(
      tester,
      notificationEnabled: true,
      onGuideTap: () {},
      onFeedbackTap: () => feedbackCalled++,
      onTermsTap: () {},
      onNotificationChanged: (_) {},
    );

    await tester.tap(find.text('의견 남기기'));
    await tester.pump();

    expect(feedbackCalled, 1);
  });

  testWidgets('OnO 이용약관을 탭하면 onTermsTap 이 불린다', (tester) async {
    var termsCalled = 0;

    await pumpMenu(
      tester,
      notificationEnabled: true,
      onGuideTap: () {},
      onFeedbackTap: () {},
      onTermsTap: () => termsCalled++,
      onNotificationChanged: (_) {},
    );

    await tester.tap(find.text('OnO 이용약관'));
    await tester.pump();

    expect(termsCalled, 1);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpMenu(
      tester,
      notificationEnabled: true,
      onGuideTap: () {},
      onFeedbackTap: () {},
      onTermsTap: () {},
      onNotificationChanged: (_) {},
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
