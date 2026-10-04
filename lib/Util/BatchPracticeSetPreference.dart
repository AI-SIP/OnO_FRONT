import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 여러 장 등록에서 복습 세트를 같이 만들지 기기에 기억해 둔다.
///
/// 전에는 늘 켜진 채로 시작해서, 끄는 걸 잊으면 올릴 때마다 같은 이름의
/// 세트가 쌓였다. 마지막으로 고른 값을 다음에도 쓴다. 처음에는 켜져 있다.
class BatchPracticeSetPreference {
  static const String _key = 'batch_register_create_practice_set';

  static Future<bool> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? true;
    } catch (e) {
      debugPrint('[BatchPracticeSetPreference] 읽기 실패: $e');
      return true;
    }
  }

  static Future<void> save(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled);
    } catch (e) {
      debugPrint('[BatchPracticeSetPreference] 저장 실패: $e');
    }
  }
}
