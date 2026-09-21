import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ono/Config/AppConfig.dart';
import 'package:provider/provider.dart';

import '../Config/firebase_options.dart';
import '../Model/Common/LoginStatus.dart';
import '../Model/StudyRoom/SharedProblemModel.dart';
import '../Provider/PracticeNoteProvider.dart';
import '../Provider/ScreenIndexProvider.dart';
import '../Provider/StudyRoomProvider.dart';
import '../Provider/TokenProvider.dart';
import '../Provider/UserProvider.dart';
import '../Screen/PracticeNote/PracticeDetailScreen.dart';
import '../Screen/ProblemDetail/ProblemDetailScreen.dart';
import '../Screen/ReviewDue/ReviewDueScreen.dart';
import '../Screen/StudyRoom/SharedProblemDetailScreen.dart';
import '../Screen/StudyRoom/StudyRoomDetailScreen.dart';
import '../Service/Api/HttpService.dart';
import 'AppAnalytics.dart';
import 'AppErrorReporter.dart';
import 'AppNavigator.dart';
import '../Module/Motion/TossPageRoute.dart';

/// 알림을 눌렀을 때 열어야 하는 화면.
enum NotificationDestination {
  /// 열 화면이 없다. 아무것도 하지 않는다.
  none,

  /// 홈으로만 돌아간다.
  home,

  /// 복습할 문제 목록 화면.
  reviewDue,

  /// 문제 상세 화면.
  problemDetail,

  /// 스터디룸 상세 화면.
  studyRoom,

  /// 공유 문제 상세 화면.
  sharedProblem,

  /// 복습 노트 상세 화면.
  practiceNote,
}

/// 알림 data 가 가리키는 목적지와, 그 화면을 열 때 필요한 id.
@immutable
class NotificationTarget {
  const NotificationTarget(
    this.destination, {
    this.problemId,
    this.roomId,
    this.sharedProblemId,
    this.practiceId,
  });

  static const NotificationTarget none =
      NotificationTarget(NotificationDestination.none);

  final NotificationDestination destination;
  final int? problemId;
  final int? roomId;
  final int? sharedProblemId;
  final int? practiceId;

  /// FCM data 를 읽어 목적지를 정한다.
  ///
  /// type 은 대소문자를 구분하지 않는다. 백엔드가 알림 종류 표기를 소문자
  /// 스네이크로 통일했지만(AI-SIP/OnO_BACKEND#312), 그 배포 전의 구버전 서버가
  /// 대문자를 보내는 기간이 있고 이미 예약되어 큐에 남은 알림도 있어서
  /// `SHARED_PROBLEM` 과 `shared_problem` 이 같은 화면으로 가야 한다.
  ///
  /// 함께 오는 id 가 없으면 열 화면을 정할 수 없으므로 아무것도 하지 않는다.
  /// 모르는 type 도 마찬가지다.
  factory NotificationTarget.fromData(Map<String, dynamic>? data) {
    if (data == null) return none;

    final rawType = data['type'];
    final type = rawType is String ? rawType.trim().toLowerCase() : '';

    switch (type) {
      case 'review_due':
        return const NotificationTarget(NotificationDestination.reviewDue);
      case 'reengagement':
      case 'reengagement_monthly':
        return const NotificationTarget(NotificationDestination.home);
      case 'problem_review_reminder':
        final problemId = _readId(data, 'problemId');
        if (problemId == null) return none;
        return NotificationTarget(
          NotificationDestination.problemDetail,
          problemId: problemId,
        );
      case 'challenge_notification':
      case 'challenge_completed':
        final roomId = _readId(data, 'roomId');
        if (roomId == null) return none;
        return NotificationTarget(
          NotificationDestination.studyRoom,
          roomId: roomId,
        );
      case 'shared_problem':
      case 'shared_problem_reaction':
      case 'shared_problem_comment':
        final roomId = _readId(data, 'roomId');
        if (roomId == null) return none;
        final sharedProblemId = _readId(data, 'sharedProblemId');
        // 공유 문제 id 가 없으면 방까지만 연다.
        if (sharedProblemId == null) {
          return NotificationTarget(
            NotificationDestination.studyRoom,
            roomId: roomId,
          );
        }
        return NotificationTarget(
          NotificationDestination.sharedProblem,
          roomId: roomId,
          sharedProblemId: sharedProblemId,
        );
      case 'practice_note_reminder':
        break;
    }

    // 복습 노트 알림은 #312 이전까지 type 없이 practiceId 만 왔다. 예약되어
    // 큐에 남은 것이 당분간 그대로 올 수 있어서, type 이름이 아니라 함께 온
    // practiceId 로 가른다. 이름이 붙은 것과 안 붙은 것이 같은 화면으로 간다.
    final practiceId = _readId(data, 'practiceId');
    if (practiceId != null) {
      return NotificationTarget(
        NotificationDestination.practiceNote,
        practiceId: practiceId,
      );
    }

    return none;
  }

  /// FCM data 의 값은 문자열로 내려온다. 숫자로 오는 경우도 함께 받는다.
  static int? _readId(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

class NotificationService {
  NotificationService._({
    HttpService? httpService,
    TokenProvider? tokenProvider,
    FirebaseMessaging? messaging,
    DeviceInfoPlugin? deviceInfo,
  })  : httpService = httpService ?? HttpService(),
        _tokenProvider = tokenProvider ?? TokenProvider(),
        _injectedMessaging = messaging,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  static final instance = NotificationService._();

  /// 테스트 전용 생성자. 운영 코드는 [instance] 만 쓴다.
  /// FCM 발송 경로라 실제 동작은 건드리지 않고, 가짜 의존성을 넣을 자리만 열었다.
  @visibleForTesting
  factory NotificationService.forTest({
    HttpService? httpService,
    TokenProvider? tokenProvider,
    FirebaseMessaging? messaging,
    DeviceInfoPlugin? deviceInfo,
  }) =>
      NotificationService._(
        httpService: httpService,
        tokenProvider: tokenProvider,
        messaging: messaging,
        deviceInfo: deviceInfo,
      );

  final HttpService httpService;
  final TokenProvider _tokenProvider;
  final DeviceInfoPlugin _deviceInfo;

  /// 주입된 것이 없으면 예전처럼 전역 인스턴스를 쓴다.
  /// 필드가 아니라 getter 인 이유는, 생성 시점에 Firebase 가 아직 초기화되지 않았어도
  /// 객체를 만들 수 있게 하기 위해서다.
  final FirebaseMessaging? _injectedMessaging;
  FirebaseMessaging get _messaging =>
      _injectedMessaging ?? FirebaseMessaging.instance;

  bool _tokenRefreshListenerConfigured = false;

  /// 앱 실행 시 한 번만 호출
  Future<void> init() async {
    // iOS 시뮬레이터라면 초기화 스킵
    if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      if (!iosInfo.isPhysicalDevice) {
        debugPrint('iOS Simulator detected – skipping FCM init');
        return;
      }
    }

    await _requestPermission();
    _configureMessageHandlers();
  }

  Future<void> _requestPermission() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Map<String, dynamic>? _pendingNotificationData;

  /// main.dart 의 하단 탭 순서와 같아야 한다. 상세 화면을 열지 못했을 때
  /// 최소한 관련 탭까지는 보내 준다.
  static const int _practiceNoteTabIndex = 1;
  static const int _studyRoomTabIndex = 3;

  void _configureMessageHandlers() {
    // 포그라운드 메시지
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('Foreground message: ${msg.notification?.title}');
    });

    // 백그라운드 상태에서 알림 탭
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('Notification tapped (background), data: ${msg.data}');
      _handleNotificationNavigation(msg.data);
    });

    // 종료 상태에서 알림 탭으로 앱 실행 — 홈 화면 전환 후 처리하도록 저장
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) {
        debugPrint('Notification tapped (terminated), data: ${msg.data}');
        // type 만 들고 있으면 problemId, roomId 같이 화면을 여는 데 필요한
        // 값이 사라진다. data 를 통째로 들고 있는다.
        _pendingNotificationData = Map<String, dynamic>.from(msg.data);
      }
    });

    if (!_tokenRefreshListenerConfigured) {
      _tokenRefreshListenerConfigured = true;
      _messaging.onTokenRefresh.listen((token) async {
        try {
          // 첫 실행 시 로그인 전에도 토큰이 발급되는데, 그대로 서버에 보내면
          // 리프레시 토큰이 없어 401 로 죽는다 (Sentry FLUTTER-11Y).
          if (!await _isLoggedIn()) {
            debugPrint('FCM token refreshed before login - skip upload');
            return;
          }
          await _sendTokenValueToServer(token);
        } catch (error, stackTrace) {
          await AppErrorReporter.report(
            error,
            stackTrace,
            source: 'fcm_token_refresh',
            severity: AppErrorSeverity.warning,
          );
        }
      });
    }
  }

  /// SplashScreen이 홈 화면으로 전환한 뒤 호출 — 저장된 알림 처리
  void processPendingNotification() {
    final data = _pendingNotificationData;
    if (data == null) return;
    _pendingNotificationData = null;
    _handleNotificationNavigation(data);
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    unawaited(navigateByNotificationData(data));
  }

  /// 알림 data 로 화면을 연다.
  ///
  /// 백그라운드에서 탭한 경우와 종료 상태에서 탭해 들어온 경우가 모두 여기로 모인다.
  @visibleForTesting
  Future<void> navigateByNotificationData(Map<String, dynamic> data) async {
    final target = NotificationTarget.fromData(data);
    if (target.destination == NotificationDestination.none) return;

    final navigator = AppNavigator.navigatorKey.currentState;
    final context = AppNavigator.navigatorKey.currentContext;
    if (navigator == null || context == null) return;

    // 로그아웃 상태면 로그인 화면 위에 데이터가 필요한 화면을 얹지 않는다.
    // waiting, unreachable 은 자동 로그인이 진행 중이거나 잠깐 끊긴 것이라 막지 않는다.
    if (_readProvider<UserProvider>(context)?.isLoggedIn ==
        LoginStatus.logout) {
      return;
    }

    navigator.popUntil((route) => route.isFirst);

    switch (target.destination) {
      case NotificationDestination.none:
      case NotificationDestination.home:
        return;
      case NotificationDestination.reviewDue:
        navigator.push(
          TossPageRoute(builder: (_) => const ReviewDueScreen()),
        );
        return;
      case NotificationDestination.problemDetail:
        final problemId = target.problemId;
        if (problemId == null) return;
        navigator.push(
          TossPageRoute(
            builder: (_) => ProblemDetailScreen(problemId: problemId),
          ),
        );
        return;
      case NotificationDestination.studyRoom:
        final roomId = target.roomId;
        if (roomId == null) return;
        _openStudyRoom(navigator, context, roomId);
        return;
      case NotificationDestination.sharedProblem:
        await _openSharedProblem(navigator, context, target);
        return;
      case NotificationDestination.practiceNote:
        final practiceId = target.practiceId;
        if (practiceId == null) return;
        await _openPracticeNote(context, practiceId);
        return;
    }
  }

  void _openStudyRoom(
    NavigatorState navigator,
    BuildContext context,
    int roomId,
  ) {
    _selectTab(context, _studyRoomTabIndex);
    navigator.push(
      TossPageRoute(builder: (_) => StudyRoomDetailScreen(roomId: roomId)),
    );
  }

  /// 방 화면을 먼저 열고, 공유 문제를 찾으면 그 상세까지 이어서 연다.
  ///
  /// 공유 문제 상세 화면은 id 가 아니라 모델을 통째로 받는다. 방을 먼저 읽어
  /// 두면 목록에서 모델을 찾을 수 있고, 상세가 댓글을 읽을 때 쓰는
  /// `selectedRoom` 도 이 방으로 맞춰진다. 못 찾거나 읽기에 실패하면 방
  /// 화면까지만 열고 끝낸다.
  Future<void> _openSharedProblem(
    NavigatorState navigator,
    BuildContext context,
    NotificationTarget target,
  ) async {
    final roomId = target.roomId;
    if (roomId == null) return;

    _openStudyRoom(navigator, context, roomId);

    final sharedProblemId = target.sharedProblemId;
    if (sharedProblemId == null) return;

    final provider = _readProvider<StudyRoomProvider>(context);
    if (provider == null) return;

    try {
      await provider.fetchRoomDetail(roomId);
      SharedProblemModel? problem;
      for (final shared in provider.sharedProblems) {
        if (shared.sharedProblemId == sharedProblemId) {
          problem = shared;
          break;
        }
      }
      if (problem == null) return;

      final current = AppNavigator.navigatorKey.currentState;
      if (current == null) return;
      final found = problem;
      current.push(
        TossPageRoute(
            builder: (_) => SharedProblemDetailScreen(problem: found)),
      );
    } catch (error) {
      debugPrint('Failed to open shared problem $sharedProblemId: $error');
    }
  }

  /// 복습 노트 상세도 모델을 통째로 받는다. 받아오지 못하면 복습 노트 탭까지만 간다.
  Future<void> _openPracticeNote(BuildContext context, int practiceId) async {
    _selectTab(context, _practiceNoteTabIndex);

    final provider = _readProvider<ProblemPracticeProvider>(context);
    if (provider == null) return;

    try {
      await provider.fetchPracticeNote(practiceId, showErrorSnackBar: false);
      await provider.moveToPractice(practiceId);
      final practice = provider.currentPracticeNote;
      if (practice == null || practice.practiceId != practiceId) return;

      final current = AppNavigator.navigatorKey.currentState;
      if (current == null) return;
      AppAnalytics.logScreenView('PracticeDetailScreen');
      current.push(
        TossPageRoute(builder: (_) => PracticeDetailScreen(practice: practice)),
      );
    } catch (error) {
      debugPrint('Failed to open practice note $practiceId: $error');
    }
  }

  /// 하단 네비게이션을 알림이 가리키는 탭으로 옮긴다. 상세 화면에서 뒤로
  /// 나왔을 때 관련 탭이 보이게 하려는 것이다.
  void _selectTab(BuildContext context, int index) {
    _readProvider<ScreenIndexProvider>(context)?.setSelectedIndex(index);
  }

  /// Provider 를 찾지 못해도 알림 처리 때문에 앱이 죽지는 않게 한다.
  T? _readProvider<T>(BuildContext context) {
    try {
      return Provider.of<T>(context, listen: false);
    } catch (error) {
      debugPrint('Provider<$T> not available for notification: $error');
      return null;
    }
  }

  Future<void> sendTokenToServer() async {
    if (!await _isLoggedIn()) {
      debugPrint('Not logged in - skip FCM token upload');
      return;
    }

    if (!await _ensureApnsTokenReady()) {
      debugPrint('⚠️ APNS token is not ready - skip FCM token upload');
      return;
    }

    final token = await _messaging.getToken();
    if (token == null) {
      debugPrint('⚠️ FCM token is NULL');
      return;
    }

    await _sendTokenValueToServer(token);
  }

  Future<bool> _isLoggedIn() async {
    try {
      final refreshToken = await _tokenProvider.getRefreshToken();
      return refreshToken != null;
    } catch (error) {
      debugPrint('Failed to read refresh token for FCM upload: $error');
      return false;
    }
  }

  /// iOS 는 APNS 토큰이 준비되기 전에 getToken() 을 부르면 예외가 난다 (Sentry FLUTTER-15Z).
  /// 로그인 흐름 안에서 호출되므로 길게 잡지 않고 최대 1.5초만 기다린 뒤 포기한다.
  /// (토큰을 못 보내도 onTokenRefresh 에서 다시 시도된다)
  Future<bool> _ensureApnsTokenReady() async {
    if (!Platform.isIOS) return true;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) return true;
      } catch (error) {
        debugPrint('getAPNSToken failed (attempt $attempt): $error');
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  Future<void> _sendTokenValueToServer(String token) async {
    await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/fcm/token',
      body: {
        "token": token,
      },
    );
    debugPrint('✅ FCM token sent to server');
  }
}

/// 'OnO' FirebaseApp 을 초기화한다.
///
/// `Firebase.apps` 는 네이티브 레지스트리가 아니라 해당 isolate 의 Dart 캐시라서
/// 중복 초기화를 막지 못한다. 메인 isolate 와 백그라운드 메시지 isolate 는 캐시가
/// 분리되어 있지만 Android 의 네이티브 FirebaseApp 레지스트리는 공유하기 때문에,
/// 둘이 함께 초기화를 시도하면 나중 쪽이 'already exists' 로 죽는다 (Sentry FLUTTER-158).
///
/// 완전한 해결책은 아니다. 이미 만들어져 있으면 그것을 쓰도록 해서 실패를 흡수하는
/// 완화책이고, 두 isolate 가 네이티브 호출에 동시에 진입하는 좁은 경합 구간은 남는다.
/// 네이티브에 나가는 호출 자체는 변경 전과 같고 try/catch 만 덧댄 구조다.
Future<void> initializeOnOFirebaseApp() async {
  try {
    await Firebase.initializeApp(
      name: 'OnO',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    try {
      Firebase.app('OnO');
    } catch (_) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    debugPrint('FirebaseApp OnO is already initialized: $error');
  }
}

/// 백그라운드/종료 상태에서 호출
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await initializeOnOFirebaseApp();

    debugPrint('Background message: ${message.notification?.title}');
    // TODO: flutter_local_notifications로 로컬 알림 띄우기
  } catch (error, stackTrace) {
    await AppErrorReporter.report(
      error,
      stackTrace,
      source: 'fcm_background',
      severity: AppErrorSeverity.error,
    );
  }
}
