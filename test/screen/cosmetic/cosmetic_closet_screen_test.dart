// 꾸미기 화면 위젯 테스트.
//
// 무대(개구리가 서 있는 자리)와 아이템 격자가 한 화면에 붙박이로 같이 있어서
// 세로가 빡빡하다. 작은 폰과 태블릿에서 넘치지 않는지, 무대가 제 자리에
// 그려지는지를 여기서 잠근다.
//
// 이 화면은 **시착**이다. 아이템을 눌러도 그 자리에서 확정되지 않고 저장을
// 눌러야 [CosmeticProvider] 로 넘어간다. 하단 탭 아이콘과 프로필 사진이
// 프로바이더를 보고 있어서, 입어 보는 중에 그것들까지 바뀌면 안 된다. 아래
// `시착` 그룹이 그 경계를 잠근다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Cosmetic/CosmeticLoadoutModel.dart';
import 'package:ono/Module/Motion/TossPageRoute.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Screen/Cosmetic/CosmeticClosetScreen.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticCollectionMeter.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticItemTile.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticNextUnlockCard.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticStage.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';

import '../../helpers/helpers.dart';

/// 꾸미기 화면을 `Navigator.push` 로 띄우기 위한 앞 화면.
///
/// 뒤로 가기를 눌렀을 때를 보려면 되돌아갈 자리가 있어야 한다.
class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.push(
            context,
            TossPageRoute(builder: (_) => const CosmeticClosetScreen()),
          ),
          child: const Text('열기'),
        ),
      ),
    );
  }
}

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

  /// 앞 화면을 거쳐 띄운다. 뒤로 가기를 보는 테스트가 쓴다.
  Future<CosmeticProvider> pushCloset(WidgetTester tester) async {
    disableAnimationsForTest(tester);
    final cosmetic = CosmeticProvider(mockLevel: 12);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const _Host(),
        cosmeticProvider: cosmetic,
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
    });

    return cosmetic;
  }

  /// 무대에 선 개구리가 지금 입고 있는 층들.
  List<CosmeticLayerModel> stageLayers(WidgetTester tester) {
    return tester
        .widget<CosmeticStageFrog>(find.byType(CosmeticStageFrog))
        .layers;
  }

  /// 알림이 스스로 닫힐 때까지 태워 보낸다. 안 그러면 타이머가 남는다.
  Future<void> settleToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
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
      await pumpCloset(tester);

      final frog = tester.widget<FrogCharacter>(
        find.descendant(
          of: find.byType(CosmeticStageFrog),
          matching: find.byType(FrogCharacter),
        ),
      );
      expect(frog.showEncouragement, isTrue);
    });
  });

  group('시착', () {
    testWidgets('처음 들어오면 저장할 것이 없어 저장 줄이 안 뜬다', (tester) async {
      await pumpCloset(tester);

      expect(find.text('저장'), findsNothing);
      expect(find.text('되돌리기'), findsNothing);
    });

    testWidgets('아이템을 걸쳐도 프로바이더는 그대로다', (tester) async {
      // 여기서 프로바이더가 바뀌면 하단 탭 아이콘과 프로필 사진이 아직 정하지도
      // 않은 차림으로 같이 바뀐다.
      final cosmetic = await pumpCloset(tester);
      final before = Map<String, String>.from(cosmetic.equipped);

      await tester.tap(find.text('봄'));
      await tester.pumpAndSettle();

      expect(cosmetic.equipped, before);
    });

    testWidgets('걸쳐 본 것이 무대의 개구리에는 바로 보인다', (tester) async {
      // 바로 안 보이면 써 보는 의미가 없다.
      await pumpCloset(tester);
      final before = stageLayers(tester);

      await tester.tap(find.text('봄'));
      await tester.pumpAndSettle();

      expect(stageLayers(tester), isNot(before));
    });

    testWidgets('걸쳐 보면 저장 줄이 올라온다', (tester) async {
      await pumpCloset(tester);

      await tester.tap(find.text('봄'));
      await tester.pumpAndSettle();

      expect(find.text('저장'), findsOneWidget);
      expect(find.text('되돌리기'), findsOneWidget);
    });

    testWidgets('저장을 눌러야 프로바이더에 반영된다', (tester) async {
      final cosmetic = await pumpCloset(tester);

      await tester.tap(find.text('봄'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      final slot = cosmetic.slots.first.slot;
      expect(cosmetic.equippedItemKeyOf(slot), isNotNull);
      expect(cosmetic.itemOf(cosmetic.equippedItemKeyOf(slot))?.nameKo, '봄');

      // 저장하고 나면 저장 줄이 다시 사라진다.
      expect(find.text('저장'), findsNothing);

      await settleToast(tester);
    });

    testWidgets('되돌리기를 누르면 원래 차림으로 돌아간다', (tester) async {
      final cosmetic = await pumpCloset(tester);
      final before = Map<String, String>.from(cosmetic.equipped);

      await tester.tap(find.text('봄'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();

      expect(find.text('저장'), findsNothing);
      expect(cosmetic.equipped, before);
    });

    testWidgets('전부 벗기도 시착이라 저장해야 진짜 벗겨진다', (tester) async {
      final cosmetic = await pumpCloset(tester);
      expect(cosmetic.equipped, isNotEmpty);

      await tester.tap(find.text('전부 벗기'));
      await tester.pumpAndSettle();

      // 아직 프로바이더는 그대로다. 개구리만 벗었다.
      expect(cosmetic.equipped, isNotEmpty);
      expect(find.text('저장'), findsOneWidget);

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(cosmetic.equipped, isEmpty);

      await settleToast(tester);
    });

    testWidgets('못 가진 것을 눌러도 걸쳐지지 않고 이유만 알려 준다', (tester) async {
      // Lv.12 의 배경 자리에서 밤하늘은 Lv.13 부터다.
      await pumpCloset(tester, level: 12);

      // 밤하늘은 예고 카드에도 적혀 있다. 격자의 칸 쪽을 누른다.
      await tester.tap(find.descendant(
        of: find.byType(CosmeticItemTile),
        matching: find.text('밤하늘'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Lv.13 부터 쓸 수 있어요.'), findsOneWidget);
      // 못 가진 것을 눌렀다고 저장할 것이 생기면 안 된다.
      expect(find.text('저장'), findsNothing);

      await settleToast(tester);
    });
  });

  group('저장하지 않고 나가기', () {
    testWidgets('바뀐 것이 없으면 그냥 나간다', (tester) async {
      await pushCloset(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(CosmeticClosetScreen), findsNothing);
    });

    testWidgets('바뀐 것이 있으면 물어본다', (tester) async {
      await pushCloset(tester);

      await tester.tap(find.text('봄'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('저장하지 않고 나갈까요?'), findsOneWidget);
      // 아직 화면은 그대로다.
      expect(find.byType(CosmeticClosetScreen), findsOneWidget);

      await tester.tap(find.text('계속 꾸미기'));
      await tester.pumpAndSettle();

      expect(find.byType(CosmeticClosetScreen), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
    });

    testWidgets('나가기를 고르면 입어 본 것이 사라진다', (tester) async {
      final cosmetic = await pushCloset(tester);
      final before = Map<String, String>.from(cosmetic.equipped);

      await tester.tap(find.text('봄'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();

      expect(find.byType(CosmeticClosetScreen), findsNothing);
      expect(cosmetic.equipped, before);
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
      expect(find.text(' / 55'), findsOneWidget);
    });

    testWidgets('레벨을 올리면 모은 개수가 는다', (tester) async {
      final cosmetic = await pumpCloset(tester, level: 12);

      cosmetic.setMockLevel(15);
      await tester.pumpAndSettle();

      // 열한 가지에 밤하늘(13)과 왕관(14)과 학사 세트 셋(15)을 더해
      // 열여섯이다. 레벨로 열리는 것은 여기까지고 나머지는 미션 보상이다.
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

      expect(inCard(find.text('배경 2 / 9')), findsOneWidget);
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

    testWidgets('그 자리를 다 모으면 잘했다는 말 없이 진행도만 남는다', (tester) async {
      final cosmetic = await pumpCloset(tester, level: 15);

      cosmetic.setUnlockAll(true);
      await tester.pumpAndSettle();

      // 카드가 사라지지 않는다. 탭을 옮길 때마다 격자가 위아래로 튀면 안 된다.
      expect(find.byType(CosmeticNextUnlockCard), findsOneWidget);
      expect(inCard(find.text('배경 9 / 9')), findsOneWidget);
      // 축하 문구는 두지 않는다. 자리마다 뜨면 금세 잔소리가 된다.
      expect(find.textContaining('다 모았'), findsNothing);
      expect(find.textContaining('전부 가졌'), findsNothing);
      expect(inCard(find.text('다음에 열려요')), findsNothing);
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
