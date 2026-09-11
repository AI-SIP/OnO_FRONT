// 옷장 화면 위젯 테스트.
//
// 무대(개구리가 서 있는 자리)와 아이템 격자가 한 화면에 붙박이로 같이 있어서
// 세로가 빡빡하다. 작은 폰과 태블릿에서 넘치지 않는지, 무대가 제 자리에
// 그려지는지를 여기서 잠근다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Screen/Cosmetic/CosmeticClosetScreen.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticStage.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  Future<CosmeticProvider> pumpCloset(
    WidgetTester tester, {
    int level = 12,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    disableAnimationsForTest(tester);
    final cosmetic = CosmeticProvider(mockLevel: level);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const CosmeticClosetScreen(),
        cosmeticProvider: cosmetic,
        surfaceSize: surfaceSize,
      );
    });

    return cosmetic;
  }

  group('무대', () {
    testWidgets('개구리가 무대 위에 선다', (tester) async {
      await pumpCloset(tester);

      expect(find.byType(CosmeticStageFrog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CosmeticStageFrog),
          matching: find.byType(FrogCharacter),
        ),
        findsOneWidget,
      );
    });

    testWidgets('무대의 개구리는 격려 말풍선을 띄운다', (tester) async {
      // 마이페이지와 미션의 개구리에서 옮겨 온 기능이다. 꾸미러 온 자리에서만
      // 한마디 한다.
      await pumpCloset(tester);

      final frog = tester.widget<FrogCharacter>(
        find.descendant(
          of: find.byType(CosmeticStageFrog),
          matching: find.byType(FrogCharacter),
        ),
      );
      expect(frog.showEncouragement, isTrue);
    });

    testWidgets('전부 벗기를 누르면 걸친 것이 없어진다', (tester) async {
      final cosmetic = await pumpCloset(tester);
      expect(cosmetic.equipped, isNotEmpty);

      await tester.tap(find.text('전부 벗기'));
      await tester.pumpAndSettle();

      expect(cosmetic.equipped, isEmpty);
    });
  });

  group('크기', () {
    for (final entry in <String, Size>{
      '작은 폰': OnoSurface.smallPhone,
      '폰': OnoSurface.phone,
      '태블릿': OnoSurface.tablet,
    }.entries) {
      testWidgets('${entry.key} 에서 넘치지 않는다', (tester) async {
        await pumpCloset(tester, surfaceSize: entry.value);

        expect(tester.takeException(), isNull);
        expect(find.byType(CosmeticClosetScreen), findsOneWidget);
      });
    }
  });
}
