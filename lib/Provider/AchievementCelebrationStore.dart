import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 아직 사용자에게 알리지 못한 훈장 key 를 기기에 적어 두는 자리다.
///
/// **서버는 새로 받은 훈장을 그 응답 한 번에만 실어 준다.** 다음에 다시 물으면
/// 그 훈장은 그냥 `earned: true` 일 뿐이라 새 것이었다는 사실이 어디에도 남지
/// 않는다. 앱이 그 한 번을 놓치면 — 응답이 도착한 순간 앱이 죽거나, 사용자가
/// 알림을 보기 전에 앱을 내렸거나 — 축하는 영영 사라진다. 서른 날을 하루도 안
/// 빼먹고 받은 개근 훈장이 그렇게 사라지면 받은 줄도 모른다.
///
/// 그래서 응답을 받은 **그 자리에서** 기기에 적는다. 사용자가 실제로 보고 난
/// 뒤에야 지운다. 메모리에만 들고 있으면 앱이 한 번 내려가는 것으로 없어진다.
///
/// **계정으로 나누지 않는다.** 대신 로그아웃이 지운다([AchievementProvider.clear]).
/// 같은 기기에서 계정을 바꾸려면 반드시 로그아웃을 지나므로 앞 사람의 축하가
/// 다음 사람에게 뜰 일이 없고, key 를 사람마다 나누면 유저 아이디를 아직 모르는
/// 시점(앱 시작 직후)에 읽을 것이 없어진다.
///
/// 읽기도 쓰기도 **실패를 삼킨다.** 저장소가 안 열려서 축하 한 번을 못 하는
/// 것은 아쉬운 일이지만, 그 때문에 훈장 화면이 안 뜨는 것은 더 나쁘다.
class AchievementCelebrationStore {
  /// 저장 키. 값의 모양이 바뀌면 뒤의 숫자를 올린다.
  static const String storageKey = 'achievement_pending_celebration_v1';

  const AchievementCelebrationStore();

  /// 아직 못 알린 key 들. 없거나 못 읽으면 빈 집합이다.
  Future<Set<String>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(storageKey);
      if (stored == null) return <String>{};
      return stored.where((key) => key.isNotEmpty).toSet();
    } catch (error) {
      debugPrint('[AchievementCelebrationStore] 읽기 실패: $error');
      return <String>{};
    }
  }

  /// 통째로 덮어쓴다. 비어 있으면 키 자체를 지운다.
  Future<void> write(Set<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (keys.isEmpty) {
        await prefs.remove(storageKey);
        return;
      }
      await prefs.setStringList(storageKey, keys.toList());
    } catch (error) {
      debugPrint('[AchievementCelebrationStore] 쓰기 실패: $error');
    }
  }
}
