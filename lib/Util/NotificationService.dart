import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ono/Config/AppConfig.dart';

import '../Service/Api/HttpService.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final HttpService httpService = HttpService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

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

    // 앱 종료/백그라운드에서도 메시지를 처리
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  Future<void> sendTokenToServer() async {
    final token = await _messaging.getToken();
    if (token == null) {
      log('⚠️ FCM token is NULL');
      return;
    }

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
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  log('Background message: ${message.notification?.title}');
  // TODO: flutter_local_notifications로 로컬 알림 띄우기
}
