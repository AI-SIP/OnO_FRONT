// 앱이 그릴 수 없는 치장을 걷어 내는지 잠근다.
//
// 아이템의 `imageUrl` 이 앱 번들 경로라서, 서버에 아이템이 하나 늘면 그 그림을
// 담은 버전을 깔기 전까지 앱은 그것을 못 그린다. 그대로 두면 옷장에 이름만
// 있고 그림이 없는 빈 칸이 생기고, 걸어 봐도 개구리가 그대로다. 사용자는 제
// 앱이 고장 난 것으로 읽는다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticLoadoutModel.dart';
import 'package:ono/Module/Cosmetic/CosmeticAssetGuard.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  tearDown(() => CosmeticAssetGuard.setBundledAssetsForTest(null));

  CosmeticLoadoutModel catalogOf(List<Map<String, Object?>> items) {
    return CosmeticLoadoutModel.fromJsonOrNull({
      'baseImageUrl': 'assets/Cosmetic/BASE.png',
      'baseLayerOrder': 300,
      'slots': [
        {'slot': 'HEAD', 'layerOrder': 700, 'nameKo': '머리'},
      ],
      'items': items,
      'equipped': {'HEAD': items.first['itemKey']},
    })!;
  }

  Map<String, Object?> item(String key, String imageUrl) => {
        'itemKey': key,
        'slot': 'HEAD',
        'nameKo': key,
        'imageUrl': imageUrl,
        'requiredLevel': 1,
        'owned': true,
      };

  test('그림이 앱에 있는 것만 남긴다', () async {
    CosmeticAssetGuard.setBundledAssetsForTest({'assets/Cosmetic/있는것.png'});
    final catalog = catalogOf([
      item('있는것', 'assets/Cosmetic/있는것.png'),
      item('없는것', 'assets/Cosmetic/없는것.png'),
    ]);

    final pruned = await CosmeticAssetGuard.pruneUndrawable(catalog);

    expect([for (final entry in pruned.items) entry.itemKey], ['있는것']);
  });

  test('빠진 것이 걸려 있었으면 차림에서도 뺀다', () async {
    // 남겨 두면 옷장 격자의 체크 표시가 목록에 없는 칸을 가리킨다.
    CosmeticAssetGuard.setBundledAssetsForTest(const <String>{});
    final catalog = catalogOf([item('없는것', 'assets/Cosmetic/없는것.png')]);
    expect(catalog.equipped['HEAD'], '없는것');

    final pruned = await CosmeticAssetGuard.pruneUndrawable(catalog);

    expect(pruned.items, isEmpty);
    expect(pruned.equipped, isEmpty);
  });

  test('네트워크 그림은 건드리지 않는다', () async {
    // 앱 밖에 있어서 여기서는 있는지 없는지 알 수 없다. S3 로 옮겨도 그대로 둔다.
    CosmeticAssetGuard.setBundledAssetsForTest(const <String>{});
    final catalog = catalogOf([item('원격', 'https://cdn.ono/hat.png')]);

    final pruned = await CosmeticAssetGuard.pruneUndrawable(catalog);

    expect([for (final entry in pruned.items) entry.itemKey], ['원격']);
  });

  test('그림 자리가 비어 있으면 뺀다', () async {
    // 무엇을 걸어도 개구리가 그대로다. 이것도 못 그리는 것으로 본다.
    CosmeticAssetGuard.setBundledAssetsForTest(const <String>{});
    final catalog = catalogOf([item('빈것', '')]);

    final pruned = await CosmeticAssetGuard.pruneUndrawable(catalog);

    expect(pruned.items, isEmpty);
  });

  test('계약 픽스처의 치장은 하나도 안 빠진다', () async {
    // **여기서는 진짜 번들 목록을 읽는다.** 해금표에 아이템을 한 줄 늘려 놓고
    // 그림을 `assets/Cosmetic/` 에 안 넣으면 이 테스트가 잡는다. 그러지 않으면
    // 앱에서는 조용히 사라지고 아무도 모른다.
    final catalog = CosmeticMockData.loadout;

    final pruned = await CosmeticAssetGuard.pruneUndrawable(catalog);

    expect(
      [for (final entry in pruned.items) entry.itemKey],
      [for (final entry in catalog.items) entry.itemKey],
    );
  });

  test('전부 그릴 수 있으면 카탈로그를 그대로 돌려준다', () async {
    CosmeticAssetGuard.setBundledAssetsForTest({'assets/Cosmetic/있는것.png'});
    final catalog = catalogOf([item('있는것', 'assets/Cosmetic/있는것.png')]);

    expect(
      await CosmeticAssetGuard.pruneUndrawable(catalog),
      same(catalog),
    );
  });
}
