import 'package:firebase_analytics_platform_interface/firebase_analytics_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Module/Util/UrlLauncher.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helpers/helpers.dart';

// FirebaseAnalytics 이벤트가 실제로 기록되는지까지 보고 싶어서,
// test/helpers/firebase_analytics_stub.dart 의 stubFirebaseAnalytics() 대신
// loggedEvents 를 밖에서 들여다볼 수 있는 자체 fake 를 둔다.
// (helpers 쪽 fake 클래스는 library-private 이라 이 파일에서 접근할 수 없다.)
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
  /// 기록된 (이벤트 이름, 파라미터) 목록. 테스트에서 검증에 쓴다.
  final List<MapEntry<String, Map<String, Object?>?>> loggedEvents = [];

  @override
  FirebaseAnalyticsPlatform delegateFor({
    required FirebaseApp app,
    Map<String, dynamic>? webOptions,
  }) =>
      this;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    loggedEvents.add(MapEntry(name, parameters));
  }
}

/// url_launcher 는 실제 플랫폼 채널(MethodChannel) 대신
/// [UrlLauncherPlatform.instance] 라는 plugin_platform_interface 델리게이트를
/// 통해 동작한다. 그래서 채널을 직접 stub 하지 않고도 이 델리게이트를
/// 가짜로 바꿔치우면 실제 URL 오픈 없이 canLaunchUrl/launchUrl 호출을 검증할 수 있다.
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  /// canLaunch 가 돌려줄 값. false 로 두면 "열 수 없음" 경로를 본다.
  bool canLaunchResult = true;

  final List<String> canLaunchCalls = [];
  final List<String> launchCalls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    canLaunchCalls.add(url);
    return canLaunchResult;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchCalls.add(url);
    return true;
  }
}

void main() {
  setUpOnoTest();

  late _FakeUrlLauncherPlatform fakePlatform;

  // FirebaseAnalytics.instance 는 앱 이름별로 자기 자신을 캐시하고, 그 안의
  // 플랫폼 델리게이트(_delegate)도 처음 접근할 때 한 번만 계산해 붙잡아 둔다.
  // 그래서 테스트마다 FirebaseAnalyticsPlatform.instance 를 새 객체로 바꿔치워도
  // 이미 한 번 쓰인 FirebaseAnalytics.instance 는 최초에 붙잡은 델리게이트를 계속
  // 쓴다. 델리게이트는 파일 전체에서 한 번만 만들고, 테스트 사이에는
  // loggedEvents 만 비워서 재사용한다.
  final fakeAnalytics = _FakeFirebaseAnalyticsPlatform();
  FirebasePlatform.instance = _FakeFirebasePlatform();
  FirebaseAnalyticsPlatform.instance = fakeAnalytics;

  setUp(() {
    fakePlatform = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;

    fakeAnalytics.loggedEvents.clear();
  });

  group('launchGuidePageURL', () {
    test('열 수 있으면 가이드 페이지 URL 로 launchUrl 을 호출하고 analytics 이벤트를 남긴다', () async {
      await UrlLauncher.launchGuidePageURL();

      expect(fakePlatform.canLaunchCalls, [AppConfig.guidePageUrl]);
      expect(fakePlatform.launchCalls, [AppConfig.guidePageUrl]);
      expect(fakeAnalytics.loggedEvents, hasLength(1));
      expect(fakeAnalytics.loggedEvents.single.key, 'ono_guide_button_click');
      expect(
        fakeAnalytics.loggedEvents.single.value,
        {'url': AppConfig.guidePageUrl},
      );
    });

    test('열 수 없으면 예외를 던지고 launch·analytics 이벤트 모두 발생하지 않는다', () async {
      fakePlatform.canLaunchResult = false;

      await expectLater(
        () => UrlLauncher.launchGuidePageURL(),
        throwsA(isA<String>()),
      );

      expect(fakePlatform.launchCalls, isEmpty);
      expect(fakeAnalytics.loggedEvents, isEmpty);
    });
  });

  group('launchFeedbackPageURL', () {
    test('열 수 있으면 피드백 페이지 URL 로 launchUrl 을 호출하고 analytics 이벤트를 남긴다', () async {
      await UrlLauncher.launchFeedbackPageURL();

      expect(fakePlatform.canLaunchCalls, [AppConfig.feedbackPageUrl]);
      expect(fakePlatform.launchCalls, [AppConfig.feedbackPageUrl]);
      expect(
        fakeAnalytics.loggedEvents.single.key,
        'feedbackPage_button_click',
      );
    });

    test('열 수 없으면 예외를 던진다', () async {
      fakePlatform.canLaunchResult = false;

      await expectLater(
        () => UrlLauncher.launchFeedbackPageURL(),
        throwsA(isA<String>()),
      );
      expect(fakeAnalytics.loggedEvents, isEmpty);
    });
  });

  group('launchUserTemPageURL', () {
    test('열 수 있으면 이용약관 페이지 URL 로 launchUrl 을 호출하고 analytics 이벤트를 남긴다',
        () async {
      await UrlLauncher.launchUserTemPageURL();

      expect(fakePlatform.canLaunchCalls, [AppConfig.userTermPageUrl]);
      expect(fakePlatform.launchCalls, [AppConfig.userTermPageUrl]);
      expect(
        fakeAnalytics.loggedEvents.single.key,
        'userTermPage_button_click',
      );
    });

    test('열 수 없으면 예외를 던진다', () async {
      fakePlatform.canLaunchResult = false;

      await expectLater(
        () => UrlLauncher.launchUserTemPageURL(),
        throwsA(isA<String>()),
      );
      expect(fakeAnalytics.loggedEvents, isEmpty);
    });
  });

  group('launchURL (범용)', () {
    test('전달한 문자열 URL 그대로 canLaunch/launch 에 넘기고 analytics 는 남기지 않는다',
        () async {
      const customUrl = 'https://example.com/path?query=1';

      await UrlLauncher.launchURL(customUrl);

      expect(fakePlatform.canLaunchCalls, [customUrl]);
      expect(fakePlatform.launchCalls, [customUrl]);
      expect(fakeAnalytics.loggedEvents, isEmpty);
    });

    test('열 수 없으면 예외를 던진다', () async {
      fakePlatform.canLaunchResult = false;

      await expectLater(
        () => UrlLauncher.launchURL('https://example.com'),
        throwsA(isA<String>()),
      );
    });

    test('커스텀 스킴 URL 도 그대로 전달한다', () async {
      const customUrl = 'mailto:test@example.com';

      await UrlLauncher.launchURL(customUrl);

      expect(fakePlatform.canLaunchCalls, [customUrl]);
      expect(fakePlatform.launchCalls, [customUrl]);
    });
  });
}
