// 테스트 공용 Firebase 스텁.
//
// StudyRoomProvider / ScreenIndexProvider / TutorialProvider / UserProvider 는
// FirebaseAnalytics.instance 를 fire-and-forget 으로 호출한다. 단위 테스트 환경에는
// 진짜 Firebase 앱이 초기화되어 있지 않아 `Firebase.app()` 이 즉시
// `[core/no-app]` 예외를 던지고, 이게 notifyListeners() 호출 전에 발생하는 메서드도
// 있어 테스트 자체가 실패한다.
//
// firebase_core/firebase_analytics 는 plugin_platform_interface 패턴을 쓰므로
// 실제 플랫폼 채널을 타지 않고 `FirebasePlatform.instance` /
// `FirebaseAnalyticsPlatform.instance` 를 가짜로 바꿔치기할 수 있다.

import 'package:firebase_analytics_platform_interface/firebase_analytics_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeFirebaseAppPlatform extends FirebaseAppPlatform {
  _FakeFirebaseAppPlatform()
      : super(
          defaultFirebaseAppName,
          const FirebaseOptions(
            apiKey: 'test-api-key',
            appId: 'test-app-id',
            messagingSenderId: 'test-sender-id',
            projectId: 'test-project-id',
          ),
        );
}

class _FakeFirebasePlatform extends FirebasePlatform
    with MockPlatformInterfaceMixin {
  final FirebaseAppPlatform _app = _FakeFirebaseAppPlatform();

  @override
  List<FirebaseAppPlatform> get apps => [_app];

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) => _app;

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async =>
      _app;
}

class _FakeFirebaseAnalyticsPlatform extends FirebaseAnalyticsPlatform
    with MockPlatformInterfaceMixin {
  /// 실제로 기록된 이벤트 이름들. 필요하면 테스트에서 검증에 쓸 수 있다.
  final List<String> loggedEvents = [];

  @override
  FirebaseAnalyticsPlatform delegateFor({
    required FirebaseApp app,
    Map<String, dynamic>? webOptions,
  }) =>
      this;

  // FirebaseAnalytics.logScreenView() / logLogin() 은 플랫폼 인터페이스에
  // 별도 메서드가 없다 — 둘 다 결국 이 logEvent() 하나로 위임된다
  // (screen_view / login 이라는 이벤트 이름으로).
  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    loggedEvents.add(name);
  }
}

/// FirebaseAnalytics 관련 호출이 예외 없이 무시되도록 플랫폼 델리게이트를 바꿔치운다.
/// 각 테스트 파일의 `setUpAll` 에서 한 번 부르면 된다.
void stubFirebaseAnalytics() {
  FirebasePlatform.instance = _FakeFirebasePlatform();
  FirebaseAnalyticsPlatform.instance = _FakeFirebaseAnalyticsPlatform();
}
