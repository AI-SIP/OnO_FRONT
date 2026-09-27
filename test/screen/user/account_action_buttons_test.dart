import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/User/Widget/AccountActionButtons.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  Future<void> pumpButtons(
    WidgetTester tester, {
    required VoidCallback onLogoutTap,
    required VoidCallback onDeleteAccountTap,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: AccountActionButtons(
          onLogoutTap: onLogoutTap,
          onDeleteAccountTap: onDeleteAccountTap,
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('로그아웃과 회원 탈퇴 문구가 보인다', (tester) async {
    await pumpButtons(
      tester,
      onLogoutTap: () {},
      onDeleteAccountTap: () {},
    );

    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('회원 탈퇴'), findsOneWidget);
  });

  testWidgets('로그아웃을 탭하면 onLogoutTap 만 호출된다', (tester) async {
    var logoutCalled = 0;
    var deleteCalled = 0;

    await pumpButtons(
      tester,
      onLogoutTap: () => logoutCalled++,
      onDeleteAccountTap: () => deleteCalled++,
    );

    await tester.tap(find.text('로그아웃'));
    await tester.pump();

    expect(logoutCalled, 1);
    expect(deleteCalled, 0);
  });

  testWidgets('회원 탈퇴를 탭하면 onDeleteAccountTap 만 호출된다', (tester) async {
    var logoutCalled = 0;
    var deleteCalled = 0;

    await pumpButtons(
      tester,
      onLogoutTap: () => logoutCalled++,
      onDeleteAccountTap: () => deleteCalled++,
    );

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pump();

    expect(logoutCalled, 0);
    expect(deleteCalled, 1);
  });

  testWidgets('여러 번 탭하면 그만큼 콜백이 호출된다', (tester) async {
    var logoutCalled = 0;

    await pumpButtons(
      tester,
      onLogoutTap: () => logoutCalled++,
      onDeleteAccountTap: () {},
    );

    await tester.tap(find.text('로그아웃'));
    await tester.pump();
    await tester.tap(find.text('로그아웃'));
    await tester.pump();

    expect(logoutCalled, 2);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpButtons(
      tester,
      onLogoutTap: () {},
      onDeleteAccountTap: () {},
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AccountActionButtons), findsOneWidget);
  });

  testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpButtons(
      tester,
      onLogoutTap: () {},
      onDeleteAccountTap: () {},
      surfaceSize: OnoSurface.smallPhone,
    );

    expect(tester.takeException(), isNull);
  });
}
