import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class ScreenIndexProvider extends ChangeNotifier {
  int _screenIndex = 0;

  int get screenIndex => _screenIndex;

  void setSelectedIndex(int index) {
    _screenIndex = index;
    notifyListeners();  // 상태 변화 알림

    switch (index) {
      case 0:
        _sendScreenView('DirectoryScreen');
        break;
      case 1:
        _sendScreenView('ProblemRegisterScreen');
        break;
      case 2:
        _sendScreenView('SettingScreen');
        break;
    }
  }

  // FirebaseAnalytics에 스크린 뷰를 기록하는 함수
  Future<void> _sendScreenView(String screenName) async {
    FirebaseAnalytics.instance.logScreenView(
      screenName: screenName,
    );
  }
}