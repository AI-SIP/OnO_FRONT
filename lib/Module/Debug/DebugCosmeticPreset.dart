import 'package:flutter/foundation.dart';

import '../../Model/Cosmetic/CosmeticAbilityLevels.dart';
import '../../Model/Cosmetic/CosmeticItemModel.dart';
import '../../Model/Cosmetic/CosmeticLoadoutModel.dart';

/// **디버그 전용.** "이 레벨의 사람은 무엇을 입고 있나"를 앱이 혼자 계산해 보는
/// 자리다.
///
/// 이 규칙의 **주인은 서버**다. 옷장을 한 번도 안 연 사람에게 무엇을 입혀
/// 줄지는 `CosmeticController` 의 `defaultPreset()` 이 정하고, 앱은 조회 응답의
/// `equipped` 를 그대로 그린다. 규칙이 바뀌었을 때 앱을 새로 내보내지 않고도
/// 따라갈 수 있어야 해서 서버 쪽을 남겼다.
///
/// 그런데도 앱에 한 벌이 남아 있는 이유는 하나뿐이다. **조합 검수 화면**
/// (`CosmeticCombinationPreviewScreen`)이 "Lv.1 부터 Lv.20 까지 개구리가 어떻게
/// 달라지나"를 한 축으로 훑는데, 그 스무 벌은 이 사람의 차림이 아니라서 서버에
/// 물을 것이 없다. 겹침이 이상한 짝을 눈으로 찾으려고 여는 화면이고
/// [kDebugMode] 에서만 열린다.
///
/// 그래서 [presetOf] 는 **릴리즈에서 언제나 빈 맵**이다. 지우지 않고 여기 둔
/// 것은, 이 규칙이 릴리즈 경로에 섞여 들면 서버가 준 차림과 앱이 지어낸 차림이
/// 화면마다 갈리기 때문이다. 여기 있는 한 그럴 일이 없다.
abstract final class DebugCosmeticPreset {
  /// 그 레벨들에서 자리마다 하나씩 걸쳐 본 차림. **릴리즈에서는 빈 맵이다.**
  ///
  /// 자리마다 **열려 있는 것 중 가장 늦게 열리는 것**을 고른다. 늦게 열릴수록
  /// 그 사람이 여기까지 왔다는 표시라서, 레벨이 높은 사람이 맨 개구리로
  /// 보이지 않는다. 서버의 `defaultPreset()` 과 같은 규칙이다.
  ///
  /// 개구리에 겹치지 않는 자리(`composited == false`, 프로필 테두리)는
  /// 건너뛴다. 프로필은 스터디룸에서 남들과 나란히 보이는데 서버가 남의 치장을
  /// 안 내려주니, 자동으로 걸면 나만 테두리가 있게 된다.
  static Map<String, String> presetOf(
    CosmeticLoadoutModel catalog,
    CosmeticAbilityLevels levels,
  ) {
    if (!kDebugMode) return const {};

    final picked = <String, CosmeticItemModel>{};

    for (final item in catalog.items) {
      if (!item.isUnlockedAt(levels)) continue;
      if (!(catalog.slotOf(item.slot)?.composited ?? true)) continue;

      final current = picked[item.slot];
      if (current == null || item.requiredLevel > current.requiredLevel) {
        picked[item.slot] = item;
      }
    }

    return Map<String, String>.unmodifiable({
      for (final entry in picked.entries) entry.key: entry.value.itemKey,
    });
  }
}
