import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ono/Config/AppConfig.dart';

import '../Config/firebase_options.dart';
import '../Service/Api/HttpService.dart';
import 'AppErrorReporter.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final HttpService httpService = HttpService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  bool _tokenRefreshListenerConfigured = false;

  /// 앱 실행 시 한 번만 호출
  Future<void> init() async {
    // iOS 시뮬레이터라면 초기화 스킵
    if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      if (!iosInfo.isPhysicalDevice) {
        log('iOS Simulator detected – skipping FCM init');
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

  void _configureMessageHandlers() {
    // 포그라운드 메시지
    FirebaseMessaging.onMessage.listen((msg) {
      log('Foreground message: ${msg.notification?.title}');
      // TODO: 스낵바나 다이얼로그로 표시
    });

    // 백그라운드/종료 상태에서 알림 탭 클릭
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      log('Notification clicked, data: ${msg.data}');
      // TODO: Navigator.pushNamed(...) 등으로 화면 이동
    });

    if (!_tokenRefreshListenerConfigured) {
      _tokenRefreshListenerConfigured = true;
      _messaging.onTokenRefresh.listen((token) async {
        try {
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

  Future<void> sendTokenToServer() async {
    final token = await _messaging.getToken();
    if (token == null) {
      log('⚠️ FCM token is NULL');
      return;
    }

    await _sendTokenValueToServer(token);
  }

  Future<void> _sendTokenValueToServer(String token) async {
    await httpService.sendRequest(
      method: 'POST',
      url: '${AppConfig.baseUrl}/api/fcm/token',
      body: {
        "token": token,
      },
    );
    log('✅ FCM token sent to server');
  }
}

/// 백그라운드/종료 상태에서 호출
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        name: 'OnO',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    log('Background message: ${message.notification?.title}');
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
