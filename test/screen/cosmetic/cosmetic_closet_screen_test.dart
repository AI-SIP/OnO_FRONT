// 옷장 화면 위젯 테스트.
//
// 무대(개구리가 서 있는 자리)와 아이템 격자가 한 화면에 붙박이로 같이 있어서
// 세로가 빡빡하다. 작은 폰과 태블릿에서 넘치지 않는지, 무대가 제 자리에
// 그려지는지를 여기서 잠근다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Screen/Cosmetic/CosmeticClosetScreen.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticCollectionMeter.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticItemTile.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticNextUnlockCard.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticSetBanner.dart';
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

  group('수집률', () {
    testWidgets('무대 맨 위에서 몇 개 중 몇 개인지 알려 준다', (tester) async {
      // Lv.12 까지 열리는 것은 Lv.2 부터 Lv.12 까지 열한 가지다. 나머지는
      // 더 높은 레벨이거나 미션 보상이다.
      await pumpCloset(tester, level: 12);

      expect(find.byType(CosmeticCollectionMeter), findsOneWidget);
      expect(find.text('모은 치장'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(find.text(' / 40'), findsOneWidget);
    });

    testWidgets('레벨을 올리면 모은 개수가 는다', (tester) async {
      final cosmetic = await pumpCloset(tester, level: 12);

      cosmetic.setMockLevel(15);
      await tester.pumpAndSettle();

      // 열한 가지에 밤하늘(13)과 왕관(14)과 학사 세트 셋(15)을 더해
      // 열여섯이다. 레벨로 열리는 것은 여기까지고 나머지 스물넷은 미션 보상이다.
      expect(find.text('16'), findsOneWidget);
    });

    testWidgets('수집률은 무대 안, 개구리보다 위에 있다', (tester) async {
      await pumpCloset(tester);

      final meterY = tester.getTopLeft(find.byType(CosmeticCollectionMeter)).dy;
      final frogY = tester.getTopLeft(find.byType(CosmeticStageFrog)).dy;
      expect(meterY, lessThan(frogY));
    });
  });

  group('다음 해금 예고', () {
    Finder inCard(Finder matching) => find.descendant(
          of: find.byType(CosmeticNextUnlockCard),
          matching: matching,
        );

    testWidgets('격자보다 먼저, 다음에 열릴 것 하나를 크게 보여 준다', (tester) async {
      // 첫 자리는 배경이다. Lv.12 에서 봄(3)과 공부방(7)을 가졌고 다음은
      // Lv.13 의 밤하늘이다.
      await pumpCloset(tester, level: 12);

      expect(find.byType(CosmeticNextUnlockCard), findsOneWidget);
      expect(inCard(find.text('다음에 열려요')), findsOneWidget);
      expect(inCard(find.text('밤하늘')), findsOneWidget);
      expect(inCard(find.text('Lv.13')), findsOneWidget);
    });

    testWidgets('자리별 진행도를 같이 얹는다', (tester) async {
      // 탭 여덟 개에 숫자를 하나씩 달면 줄이 시끄러워진다. 고른 자리의 것만
      // 이 카드에서 말한다.
      await pumpCloset(tester, level: 12);

      expect(inCard(find.text('배경 2 / 8')), findsOneWidget);
    });

    testWidgets('예고 카드가 격자보다 위에 있다', (tester) async {
      await pumpCloset(tester, level: 12);

      final cardY = tester.getTopLeft(find.byType(CosmeticNextUnlockCard)).dy;
      final tileY = tester.getTopLeft(find.byType(CosmeticSlotEmptyTile)).dy;
      expect(cardY, lessThan(tileY));
    });

    testWidgets('레벨로 열릴 것이 없으면 미션 보상을 예고한다', (tester) async {
      // Lv.15 의 머리 자리는 레벨로 열리는 다섯 가지를 다 가졌다. 남은 것은
      // 미션 보상 셋이라 그쪽을 말한다.
      await pumpCloset(tester, level: 15);

      await tester.tap(find.text('머리'));
      await tester.pumpAndSettle();

      expect(inCard(find.text('베레모')), findsOneWidget);
      expect(inCard(find.text('미션 보상')), findsOneWidget);
    });

    testWidgets('그 자리를 다 모으면 다 모았다고 말한다', (tester) async {
      final cosmetic = await pumpCloset(tester, level: 15);

      cosmetic.setUnlockAll(true);
      await tester.pumpAndSettle();

      // 카드가 사라지지 않는다. 탭을 옮길 때마다 격자가 위아래로 튀면 안 된다.
      expect(find.byType(CosmeticNextUnlockCard), findsOneWidget);
      expect(inCard(find.text('다 모았어요')), findsOneWidget);
      expect(inCard(find.text('배경 8 / 8')), findsOneWidget);
    });
  });

  group('NEW 표시', () {
    testWidgets('이번 레벨에 열린 것에만 붙는다', (tester) async {
      // Lv.13 에 열리는 것은 배경의 밤하늘 하나다.
      await pumpCloset(tester, level: 13);

      expect(find.text('NEW'), findsOneWidget);

      final badgeX = tester.getCenter(find.text('NEW')).dx;
      final tileX = tester.getCenter(find.text('밤하늘')).dx;
      // 왼쪽 위에 붙는다. 오른쪽 위는 입고 있다는 체크 자리다.
      expect(badgeX, lessThan(tileX));
    });

    testWidgets('이번 레벨에 열린 것이 없는 자리에는 붙지 않는다', (tester) async {
      // Lv.12 에 열리는 것은 머리의 버킷햇이고 배경에는 없다.
      await pumpCloset(tester, level: 12);

      expect(find.text('NEW'), findsNothing);

      await tester.tap(find.text('머리'));
      await tester.pumpAndSettle();

      expect(find.text('NEW'), findsOneWidget);
    });
  });

  group('세트 진행도', () {
    Finder inBanner(Finder matching) => find.descendant(
          of: find.byType(CosmeticSetBanner),
          matching: matching,
        );

    testWidgets('한 벌을 얼마나 모았는지 숫자로 말한다', (tester) async {
      // 학사 세트는 머리·옷·손 셋으로 흩어져 있어서 격자만 봐서는 몇 개를
      // 모았는지 셀 데가 없다.
      await pumpCloset(tester, level: 15);

      await tester.tap(find.text('머리'));
      await tester.pumpAndSettle();

      expect(find.byType(CosmeticSetBanner), findsOneWidget);
      expect(inBanner(find.text('3 / 3')), findsOneWidget);
    });

    testWidgets('못 모은 세트는 개수와 조건을 같이 말한다', (tester) async {
      // Lv.14 에서는 학사 세트 셋이 모두 Lv.15 라 하나도 없다.
      await pumpCloset(tester, level: 14);

      await tester.tap(find.text('머리'));
      await tester.pumpAndSettle();

      expect(inBanner(find.text('0 / 3')), findsOneWidget);
      expect(
        inBanner(find.textContaining('Lv.15 부터')),
        findsOneWidget,
      );
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
