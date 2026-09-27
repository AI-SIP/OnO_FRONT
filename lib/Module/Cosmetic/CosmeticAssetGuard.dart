import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../Model/Cosmetic/CosmeticLoadoutModel.dart';

/// 이 앱이 그릴 수 없는 치장을 카탈로그에서 걷어 낸다.
///
/// 아이템의 `imageUrl` 이 `assets/Cosmetic/hat_beanie.png` 처럼 **앱 번들 경로**
/// 다. 그림이 서버가 아니라 설치된 앱 안에 있다는 뜻이라, 서버에 아이템이
/// 하나 늘면 그 그림을 담은 버전을 깔기 전까지 앱은 그것을 그릴 수 없다.
///
/// 그대로 두면 옷장에 **빈 칸**이 생긴다. 이름과 해금 조건은 적혀 있는데
/// 그림 자리만 비어 있어서, 사용자는 제 앱이 고장 난 것으로 읽는다. 걸어 보면
/// 개구리도 그대로다. 그래서 못 그릴 것은 애초에 목록에서 뺀다. 앱을 올리면
/// 그림과 함께 다시 나타난다.
///
/// 지키는 것 둘이다.
///
/// 1. **네트워크 그림은 건드리지 않는다.** `http` 로 시작하는 것은 앱 밖에
///    있어서 여기서 있는지 없는지 알 수 없다. 나중에 S3 로 옮겨도 이 파일은
///    그대로 둔다.
/// 2. **목록을 못 읽으면 아무것도 빼지 않는다.** 매니페스트를 읽지 못한
///    것이지 그림이 없다는 뜻이 아니다. 그때 전부 빼 버리면 멀쩡한 옷장이
///    통째로 비는데, 빈 칸 몇 개보다 그쪽이 훨씬 나쁘다.
abstract final class CosmeticAssetGuard {
  /// 앱에 실제로 들어 있는 에셋 경로들. 한 번 읽어 두고 계속 쓴다.
  static Set<String>? _bundled;

  /// 읽어 봤는데 실패했는지. 실패한 뒤에는 매번 다시 읽지 않는다.
  static bool _unavailable = false;

  /// 그릴 수 없는 아이템을 뺀 카탈로그.
  ///
  /// 걸려 있던 것이 빠지면 `equipped` 에서도 함께 뺀다. 남겨 두면 옷장 격자의
  /// 체크 표시가 목록에 없는 칸을 가리킨다.
  static Future<CosmeticLoadoutModel> pruneUndrawable(
    CosmeticLoadoutModel catalog,
  ) async {
    final bundled = await _loadBundledAssets();
    if (bundled == null) return catalog;

    final kept = [
      for (final item in catalog.items)
        if (_isDrawable(item.imageUrl, bundled)) item,
    ];
    if (kept.length == catalog.items.length) return catalog;

    final keptKeys = {for (final item in kept) item.itemKey};
    final droppedKeys = [
      for (final item in catalog.items)
        if (!keptKeys.contains(item.itemKey)) item.itemKey,
    ];
    debugPrint('[CosmeticAssetGuard] 그림이 없어 뺀 아이템: $droppedKeys');

    return CosmeticLoadoutModel(
      baseImageUrl: catalog.baseImageUrl,
      slots: catalog.slots,
      items: kept,
      equipped: {
        for (final entry in catalog.equipped.entries)
          if (keptKeys.contains(entry.value)) entry.key: entry.value,
      },
      baseLayerOrder: catalog.baseLayerOrder,
    );
  }

  /// 이 그림을 그릴 수 있는지.
  static bool _isDrawable(String imageUrl, Set<String> bundled) {
    // 그림 자리가 아예 비어 있으면 무엇을 걸어도 개구리가 그대로다. 이것도
    // 못 그리는 것으로 본다.
    if (imageUrl.isEmpty) return false;
    if (imageUrl.startsWith('http')) return true;
    return bundled.contains(imageUrl);
  }

  /// 앱에 들어 있는 에셋 목록. 읽지 못하면 null 이다.
  static Future<Set<String>?> _loadBundledAssets() async {
    if (_bundled != null) return _bundled;
    if (_unavailable) return null;

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return _bundled = manifest.listAssets().toSet();
    } catch (error) {
      // 테스트처럼 번들이 없는 자리에서도 돈다. 그때는 거르지 않는다.
      debugPrint('[CosmeticAssetGuard] 에셋 목록을 읽지 못했다: $error');
      _unavailable = true;
      return null;
    }
  }

  /// 앱에 들어 있는 에셋 목록을 대신 정해 준다. 테스트 전용이다.
  ///
  /// 테스트에는 번들이 없어서 [_loadBundledAssets] 가 늘 실패한다. 그러면
  /// "못 읽으면 아무것도 빼지 않는다" 쪽만 확인할 수 있고, 정작 **빼는** 쪽을
  /// 잠글 수가 없다. null 을 주면 원래대로 돌아간다.
  @visibleForTesting
  static void setBundledAssetsForTest(Set<String>? assets) {
    _bundled = assets;
    _unavailable = false;
  }
}
