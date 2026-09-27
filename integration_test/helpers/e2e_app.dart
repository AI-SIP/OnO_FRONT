import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/main.dart' as app;
import 'package:ono/Util/AppErrorReporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱을 처음 설치한 상태로 띄우고 [body] 를 돌린다.
///
/// 진짜 `main()` 을 그대로 부른다. `flutter run --dart-define=ENV=...` 로 개발할 때와
/// 같은 길이라 Firebase, Sentry, 알림 초기화까지 다 탄다.
///
/// 로그인 토큰과 튜토리얼 완료 기록을 먼저 지운다. 같은 시뮬레이터에서 앞 테스트가
/// 남긴 토큰이 있으면 스플래시가 곧장 홈으로 넘어가 버린다.
///
/// `main()` 은 `FlutterError.onError` 를 앱의 오류 보고기로 바꾼다. 테스트 틀은 본문이
/// 끝나는 순간 이것이 원래대로인지 검사하고, `addTearDown` 은 그 검사보다 늦게 돈다.
/// 그래서 실패해도 되돌리도록 `finally` 에서 되돌린다. 되돌리지 않으면 진짜 실패
/// 원인 앞에 "onError 를 되돌리지 않았다" 는 단언이 먼저 찍혀 원인이 가려진다.
///
/// [cleanup] 도 `finally` 에서 부른다. 테스트가 중간에 실패해도 게스트 계정을 지운다.
Future<void> runFreshApp(
  WidgetTester tester,
  Future<void> Function() body, {
  Future<void> Function()? cleanup,
}) async {
  await const FlutterSecureStorage().deleteAll();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  final testOnError = FlutterError.onError;
  // 테스트의 실패와 시드 데이터가 Sentry 와 Discord 에 운영 이슈처럼 쌓였다.
  AppErrorReporter.enabled = false;
  unawaited(app.main());
  try {
    await body();
  } finally {
    try {
      await cleanup?.call();
    } finally {
      FlutterError.onError = testOnError;
    }
  }
}

/// [finder] 가 화면에 나타날 때까지 프레임을 넘기며 기다린다.
///
/// `pumpAndSettle` 은 쓰지 않는다. 홈은 탭 다섯을 한꺼번에 띄우고, 개구리의 대기
/// 모션이나 로딩 스켈레톤처럼 끝나지 않는 연출이 있어서 영영 안정되지 않는다.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure(
    '$timeout 동안 기다렸지만 나타나지 않았다: $finder\n'
    '지금 화면의 글자: ${visibleTexts()}',
  );
}

/// 지금 화면에 그려진 글자들. 기다리던 것이 안 나왔을 때 어디서 멈췄는지 보려고
/// 실패 메시지에 붙인다.
List<String> visibleTexts() {
  return find
      .byType(Text)
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .where((text) => text.trim().isNotEmpty)
      .toSet()
      .take(40)
      .toList();
}

/// [finder] 가 화면에서 사라질 때까지 기다린다.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('$timeout 동안 기다렸지만 사라지지 않았다: $finder');
}

/// 잠깐 프레임을 넘긴다. 눌린 뒤 화면이 넘어가는 연출을 흘려보낼 때 쓴다.
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// [text] 가 보일 때까지 기다렸다가 누른다. 같은 글자가 여럿이면 마지막 것을
/// 누른다. 다이얼로그는 화면 맨 위에 쌓이므로 대개 마지막 것이 다이얼로그 버튼이다.
///
/// 누르기 전에 화면 안으로 스크롤한다. 목록 아래쪽 버튼은 만들어져 있어도 화면
/// 밖이라, 그냥 누르면 아무 일도 안 일어난 채 다음 단계에서 멈춘다.
Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await pumpUntilFound(tester, finder);
  await tester.ensureVisible(finder.last);
  await pumpFor(tester, const Duration(milliseconds: 300));
  await tester.tap(finder.last, warnIfMissed: false);
  await pumpFor(tester, const Duration(milliseconds: 600));
}
