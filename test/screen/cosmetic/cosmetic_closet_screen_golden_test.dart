// 옷장(꾸미기) 화면 골든 테스트.
//
// 위젯 테스트(cosmetic_closet_screen_test.dart)는 넘치지 않는지와 시착 흐름을
// 본다. 여기서는 무대와 아이템 격자가 **어떻게 생겼는지**를 이미지로 잠근다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Screen/Cosmetic/CosmeticClosetScreen.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '옷장 화면',
    fileName: 'cosmetic_closet_screen',
    buildApp: () async => buildOnoApp(
      const CosmeticClosetScreen(),
      // 위젯 테스트와 같은 기준. 다섯 능력치가 전부 Lv.12 다.
      cosmeticProvider: await loadedCosmeticProvider(
        levels: CosmeticAbilityLevels.uniform(12),
      ),
    ),
  );
}
