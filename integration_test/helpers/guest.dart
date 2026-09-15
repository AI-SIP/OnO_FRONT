import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:provider/provider.dart';

import 'e2e_app.dart';

/// 로그인 화면에서 게스트로 들어가 홈이 뜰 때까지 간다.
///
/// 게스트는 매번 새 계정이라 튜토리얼이 뜬다. 건너뛰기를 누르고, dev 서버에 공지가
/// 걸려 있으면 닫는다.
Future<void> signInAsGuest(WidgetTester tester) async {
  await tapText(tester, '게스트로 시작하기');
  // 게스트 안내 다이얼로그.
  await tapText(tester, '확인');

  await pumpUntilFound(
    tester,
    find.text('오답노트 관리'),
    timeout: const Duration(seconds: 60),
  );
  await dismissHomeOverlays(tester);
}

/// 홈에 들어오자마자 뜨는 튜토리얼과 서비스 공지를 닫는다.
///
/// 둘 다 서버 응답과 계정 나이에 따라 뜰 수도 안 뜰 수도 있어서, 몇 초 동안 보이는
/// 대로 닫는다.
Future<void> dismissHomeOverlays(WidgetTester tester) async {
  final end = DateTime.now().add(const Duration(seconds: 6));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    final skip = find.text('건너뛰기');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip.last, warnIfMissed: false);
      continue;
    }
    final close = find.text('닫기');
    if (close.evaluate().isNotEmpty) {
      await tester.tap(close.last, warnIfMissed: false);
      continue;
    }
  }
}

/// 테스트가 만든 게스트 계정을 탈퇴시킨다.
///
/// 게스트로 들어갈 때마다 서버에 계정이 하나씩 생긴다. 끝날 때 지우지 않으면
/// 테스트를 돌릴수록 쌓인다. 로그인까지 못 갔으면 지울 계정이 없으니 건너뛴다.
Future<void> deleteGuestAccount(WidgetTester tester) async {
  final apps = find.byType(MaterialApp);
  if (apps.evaluate().isEmpty) return;
  final userProvider = Provider.of<UserProvider>(
    tester.element(apps.first),
    listen: false,
  );
  if (userProvider.isLoggedIn != LoginStatus.login) return;
  await userProvider.deleteAccount();
  await pumpFor(tester, const Duration(seconds: 1));
}
