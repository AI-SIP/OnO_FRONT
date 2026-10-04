import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import '../../Model/Common/LoginStatus.dart';
import '../../Module/Dialog/UnsavedChangesScope.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Provider/UserProvider.dart';
import '../../Screen/User/LearningCalendarScreen.dart';
import '../../Util/AppAnalytics.dart';
import '../../Util/AppNavigator.dart';
import '../../Util/NotificationService.dart';

/// 홈 화면 위젯을 눌러 들어온 주소를 앱 화면 이동으로 바꾼다.
///
/// | 주소 | 이동 |
/// |---|---|
/// | `onowidget://review-due?homeWidget&size=...` | 복습 예정 화면 |
/// | `onowidget://problem/{id}?homeWidget&size=large` | 문제 상세 |
/// | `onowidget://calendar?homeWidget&size=...` | 학습 달력 |
///
/// 복습 예정과 문제 상세는 알림 라우터에 이미 있어서 알림 data 모양으로 바꿔
/// 그쪽을 **부르기만** 한다. 달력은 알림에 없는 대상이라 같은 순서(로그인 확인,
/// 첫 화면까지 되돌린 뒤 push)로 여기서 연다.
///
/// `homeWidget` 쿼리는 iOS 의 home_widget 플러그인이 위젯 주소를 알아보는
/// 표시다. 없으면 iOS 가 이 주소를 앱에 넘기지 않는다.
class HomeWidgetRouter {
  HomeWidgetRouter._();

  static final HomeWidgetRouter instance = HomeWidgetRouter._();

  static const String scheme = 'onowidget';

  Future<void>? _initialCapture;
  Uri? _pendingUri;
  StreamSubscription<Uri?>? _clickSubscription;

  /// 앱이 꺼진 상태에서 위젯으로 열렸는지 읽어 둔다. `_bootstrapApp` 에서 부른다.
  ///
  /// 이때는 아직 로그인도 홈 화면도 없어서 바로 옮기지 않고, 홈 화면이 뜬 뒤
  /// [processPending] 에서 처리한다. 프로세스마다 한 번만 읽는다. 같은 값이
  /// 앱이 살아 있는 내내 남아 있어서, 다시 읽으면 재로그인할 때마다 같은
  /// 화면으로 끌려간다.
  void captureInitialLaunch() {
    _initialCapture ??= _captureInitialLaunch();
  }

  Future<void> _captureInitialLaunch() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (_isWidgetUri(uri)) _pendingUri = uri;
    } catch (error) {
      debugPrint('HomeWidgetRouter initial launch read failed: $error');
    }
  }

  /// 홈 화면이 뜬 뒤 부른다. 앱이 꺼진 상태에서 위젯으로 열렸으면 그 화면으로
  /// 옮긴다.
  Future<void> processPending() async {
    try {
      await _initialCapture;
    } catch (_) {}
    final uri = _pendingUri;
    _pendingUri = null;
    if (uri != null) await open(uri);
  }

  /// 앱이 떠 있을 때 위젯을 누른 것을 받는다. 홈 화면 `initState` 에서 부른다.
  void listenClicks() {
    _clickSubscription?.cancel();
    try {
      _clickSubscription = HomeWidget.widgetClicked.listen(
        (uri) {
          if (uri != null) unawaited(open(uri));
        },
        onError: (Object error) {
          debugPrint('HomeWidgetRouter click stream error: $error');
        },
      );
    } catch (error) {
      debugPrint('HomeWidgetRouter listen failed: $error');
    }
  }

  /// 홈 화면 `dispose` 에서 부른다.
  void stopListening() {
    _clickSubscription?.cancel();
    _clickSubscription = null;
  }

  /// 위젯 주소 하나를 연다. 옮겼으면 `home_widget_open` 을 남긴다.
  Future<void> open(Uri uri) async {
    try {
      final target = _HomeWidgetTarget.parse(uri);
      if (target == null) return;

      final opened = await _navigate(target);
      if (!opened) return;

      AppAnalytics.logEvent('home_widget_open', {
        'source': target.source,
        'destination': target.destination,
      });
    } catch (error) {
      debugPrint('HomeWidgetRouter open failed: $error');
    }
  }

  Future<bool> _navigate(_HomeWidgetTarget target) async {
    final navigator = AppNavigator.navigatorKey.currentState;
    final context = AppNavigator.navigatorKey.currentContext;
    if (navigator == null || context == null) return false;

    // 알림 라우터와 같은 조건이다. 로그아웃 상태면 로그인 화면 위에 데이터가
    // 필요한 화면을 얹지 않는다. waiting, unreachable 은 자동 로그인이 진행
    // 중이거나 잠깐 끊긴 것이라 막지 않는다.
    if (_readLoginStatus(context) == LoginStatus.logout) return false;

    switch (target.destination) {
      case _HomeWidgetTarget.reviewDue:
        // ignore: invalid_use_of_visible_for_testing_member
        await NotificationService.instance.navigateByNotificationData(
          const {'type': 'review_due'},
        );
        return true;
      case _HomeWidgetTarget.problem:
        // ignore: invalid_use_of_visible_for_testing_member
        await NotificationService.instance.navigateByNotificationData({
          'type': 'problem_review_reminder',
          'problemId': target.problemId,
        });
        return true;
      case _HomeWidgetTarget.calendar:
        final leave = await UnsavedChangesScope.confirmBeforeLeavingAll(
          source: 'home_widget',
        );
        if (!leave) return false;
        navigator.popUntil((route) => route.isFirst);
        navigator.push(
          TossPageRoute(builder: (_) => const LearningCalendarScreen()),
        );
        return true;
    }
    return false;
  }

  static LoginStatus? _readLoginStatus(BuildContext context) {
    try {
      return Provider.of<UserProvider>(context, listen: false).isLoggedIn;
    } catch (_) {
      return null;
    }
  }

  static bool _isWidgetUri(Uri? uri) =>
      uri != null && uri.scheme.toLowerCase() == scheme;
}

/// 위젯 주소에서 읽어 낸 이동 대상.
class _HomeWidgetTarget {
  static const String reviewDue = 'review_due';
  static const String problem = 'problem';
  static const String calendar = 'calendar';

  /// `review_due`, `problem`, `calendar`. Analytics `destination` 값과 같다.
  final String destination;

  /// `widget_small`, `widget_medium`, `widget_large`.
  final String source;

  final int? problemId;

  const _HomeWidgetTarget(this.destination, this.source, {this.problemId});

  static const Set<String> _sizes = {'small', 'medium', 'large'};

  static _HomeWidgetTarget? parse(Uri uri) {
    if (!HomeWidgetRouter._isWidgetUri(uri)) return null;

    final size = uri.queryParameters['size']?.toLowerCase();
    final source = _sizes.contains(size) ? 'widget_$size' : 'widget_unknown';

    switch (uri.host.toLowerCase()) {
      case 'review-due':
        return _HomeWidgetTarget(reviewDue, source);
      case 'calendar':
        return _HomeWidgetTarget(calendar, source);
      case 'problem':
        final segments = uri.pathSegments.where((s) => s.isNotEmpty);
        final problemId =
            segments.isEmpty ? null : int.tryParse(segments.first);
        if (problemId == null) return null;
        return _HomeWidgetTarget(problem, source, problemId: problemId);
    }
    return null;
  }
}
