import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ono/Config/AppConfig.dart';

import '../Config/firebase_options.dart';
import '../Screen/ReviewDue/ReviewDueScreen.dart';
import '../Service/Api/HttpService.dart';
import 'AppErrorReporter.dart';
import 'AppNavigator.dart';

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

  String? _pendingNotificationType;

  void _configureMessageHandlers() {
    // 포그라운드 메시지
    FirebaseMessaging.onMessage.listen((msg) {
      log('Foreground message: ${msg.notification?.title}');
    });

    // 백그라운드 상태에서 알림 탭
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      log('Notification tapped (background), data: ${msg.data}');
      _handleNotificationNavigation(msg.data);
    });

    // 종료 상태에서 알림 탭으로 앱 실행 — 홈 화면 전환 후 처리하도록 저장
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) {
        log('Notification tapped (terminated), data: ${msg.data}');
        _pendingNotificationType = msg.data['type'] as String?;
      }
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

  /// SplashScreen이 홈 화면으로 전환한 뒤 호출 — 저장된 알림 처리
  void processPendingNotification() {
    final type = _pendingNotificationType;
    if (type == null) return;
    _pendingNotificationType = null;
    _navigateByType(type);
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    _navigateByType(type);
  }

  void _navigateByType(String? type) {
    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator == null) return;

    if (type == 'review_due') {
      navigator.popUntil((route) => route.isFirst);
      navigator.push(
        MaterialPageRoute(builder: (_) => const ReviewDueScreen()),
      );
    } else if (type == 'reengagement' || type == 'reengagement_monthly') {
      navigator.popUntil((route) => route.isFirst);
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
