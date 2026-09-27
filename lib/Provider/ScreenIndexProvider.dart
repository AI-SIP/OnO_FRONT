import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class ScreenIndexProvider extends ChangeNotifier {
  int _screenIndex = 0;

  int get screenIndex => _screenIndex;

  void setSelectedIndex(int index) {
    _screenIndex = index;
    notifyListeners(); // 상태 변화 알림

    // main.dart 의 widgetOptions 순서와 같아야 한다. 하단 탭을 하나 늘리거나
    // 자리를 바꾸면 여기도 같이 고친다.
    switch (index) {
      case 0:
        _sendScreenView('DirectoryScreen');
        break;
      case 1:
        _sendScreenView('ProblemPracticeScreen');
        break;
      case 2:
        _sendScreenView('CharacterScreen');
        break;
      case 3:
        _sendScreenView('StudyRoomScreen');
        break;
      case 4:
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
