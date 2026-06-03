import 'package:shared_preferences/shared_preferences.dart';

import 'TutorialStep.dart';

class TutorialStorage {
  static String _completedKey(int userId) =>
      'tutorial_completed_user_${userId}_v$currentTutorialVersion';

  Future<bool> isCompleted(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey(userId)) ?? false;
  }

  Future<void> markCompleted(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey(userId), true);
  }
}
