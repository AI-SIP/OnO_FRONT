import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 오답노트를 등록할 때 AI 분석을 돌릴지 기기에 기억해 둔다.
///
/// 등록 화면의 토글에서 마지막으로 고른 값을 그대로 다음 등록에 쓴다.
/// 처음에는 꺼져 있다. 분석은 필요한 사람만 켜서 쓴다.
class AiAnalysisPreference {
  static const String _key = 'ai_analysis_on_register';

  static Future<bool> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (e) {
      debugPrint('[AiAnalysisPreference] 읽기 실패: $e');
      return false;
    }
  }

  static Future<void> save(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled);
    } catch (e) {
      debugPrint('[AiAnalysisPreference] 저장 실패: $e');
    }
  }
}
