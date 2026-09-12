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
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Model/Cosmetic/CosmeticLoadoutModel.dart';
import 'package:ono/Module/Motion/TossPageRoute.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Screen/Cosmetic/CosmeticClosetScreen.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticCollectionMeter.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticDebugLevelPanel.dart';
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

  /// 다섯 레벨을 한 값으로 놓은 사람. 별말 없으면 전부 Lv.12 다.
  ///
  /// 해금이 능력치별로 갈렸지만 이 화면 테스트가 보려는 것은 대부분 레이아웃과
  /// 시착 흐름이라, 기준 하나를 정해 두고 필요한 테스트만 능력치를 흩는다.
  Future<CosmeticProvider> pumpCloset(
    WidgetTester tester, {
    CosmeticAbilityLevels? levels,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    disableAnimationsForTest(tester);
    final cosmetic = CosmeticProvider(
      mockLevels: levels ?? CosmeticAbilityLevels.uniform(12),
    );

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
    final cosmetic = CosmeticProvider(
      mockLevels: CosmeticAbilityLevels.uniform(12),
    );

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

  group('무대 배경', () {
    // 액자는 하나만 둔다. 배경 파츠를 개구리 사각형에 그대로 두면 둥근 사각형
    // 안에 둥근 사각형이 또 생겨서, 옷장 탭에서 걷어낸 액자가 여기 남는다.
    testWidgets('배경은 개구리 사각형이 아니라 무대 카드에 깔린다', (tester) async {
      final cosmetic = await pumpCloset(tester);

      final backdrop = cosmetic.backdropOf(cosmetic.equipped);
      expect(backdrop, isNotNull, reason: '기본 차림에 배경이 걸려 있어야 한다');
      expect(find.byType(CosmeticStageGround), findsOneWidget);

      final stack = tester.widget<FrogLayerStack>(
        find.descendant(
          of: find.byType(CosmeticStageFrog),
          matching: find.byType(FrogLayerStack),
        ),
      );
      expect(
        stack.layers.any((layer) => layer.itemKey == backdrop!.itemKey),
        isFalse,
      );
    });

    testWidgets('배경을 벗어도 무대가 비지 않는다', (tester) async {
      final cosmetic = await pumpCloset(tester);

      cosmetic.unequipAll();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CosmeticStageGround), findsOneWidget);
      expect(find.byType(CosmeticStageFrog), findsOneWidget);
    });
  });

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

    testWidgets('못 가진 것을 눌러도 걸쳐지지 않고 무엇을 올려야 하는지 알려 준다', (tester) async {
      // 출석 Lv.3 이면 배경 자리의 봄(2)은 열려 있고 여름(4)은 잠겨 있다.
      await pumpCloset(tester, levels: CosmeticAbilityLevels(attendance: 3));

      // 여름은 예고 카드에도 적혀 있다. 격자의 칸 쪽을 누른다.
      await tester.tap(find.descendant(
        of: find.byType(CosmeticItemTile),
        matching: find.text('여름'),
      ));
      await tester.pumpAndSettle();

      // 능력치 이름이 없으면 무엇의 4 인지 알 수 없다.
      expect(find.text('출석 Lv.4 부터 쓸 수 있어요.'), findsOneWidget);
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
      // 다섯이 다 Lv.12 면 능력치별로 9 + 8 + 8 + 8 개, 총 학습으로 7 개가
      // 열려 마흔이고, 프로필 테두리 넷(봄·여름·가을·나뭇잎)이 더해져
      // 마흔넷이다.
      await pumpCloset(tester);

      expect(find.byType(CosmeticCollectionMeter), findsOneWidget);
      expect(find.text('모은 치장'), findsOneWidget);
      expect(find.text('44'), findsOneWidget);
      expect(find.text(' / 63'), findsOneWidget);
    });

    testWidgets('레벨을 올리면 모은 개수가 는다', (tester) async {
      final cosmetic = await pumpCloset(tester);

      cosmetic.setMockLevels(CosmeticAbilityLevels.max);
      await tester.pumpAndSettle();

      // 다섯을 끝까지 올리면 예순셋이 전부 열린다. 레벨로 안 열리는 것은
      // 이제 하나도 없다.
      expect(find.text('63'), findsOneWidget);
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
      // 첫 자리는 배경이다. 전부 Lv.12 면 배경 아홉 중 일곱을 가졌고 남은 것은
      // 밤하늘(출석 14)과 우주(출석 15)다. 가까운 쪽은 밤하늘이다.
      await pumpCloset(tester);

      expect(find.byType(CosmeticNextUnlockCard), findsOneWidget);
      expect(inCard(find.text('다음에 열려요')), findsOneWidget);
      expect(inCard(find.text('밤하늘')), findsOneWidget);
      // 무엇을 얼마나 올려야 하는지. 능력치 이름이 붙어야 읽힌다.
      expect(inCard(find.text('출석 Lv.14')), findsOneWidget);
    });

    testWidgets('지금 내가 그 능력치에서 몇 레벨인지 같이 적는다', (tester) async {
      // 필요 레벨만 적으면 코앞인지 한참 남았는지 알 수 없다.
      await pumpCloset(tester);

      expect(inCard(find.text('지금 출석 Lv.12 · 2 레벨 남았어요')), findsOneWidget);
    });

    testWidgets('한 칸 남았으면 한 칸 남았다고 말한다', (tester) async {
      await pumpCloset(
        tester,
        levels: CosmeticAbilityLevels(attendance: 13),
      );

      expect(inCard(find.text('지금 출석 Lv.13 · 한 레벨만 더!')), findsOneWidget);
    });

    testWidgets('남은 레벨이 가장 적은 것을 고른다', (tester) async {
      // 배경 자리에는 출석으로 열리는 여덟과 오답노트로 열리는 공부방(12)이
      // 섞여 있다. 출석을 Lv.15 로 끝까지 올려 두면 출석 쪽은 남은 것이 없고,
      // 필요 레벨이 더 높은 공부방 쪽이 유일하게 남은 하나가 된다.
      await pumpCloset(
        tester,
        levels: CosmeticAbilityLevels(attendance: 15, noteWrite: 11),
      );

      expect(inCard(find.text('공부방')), findsOneWidget);
      expect(inCard(find.text('오답노트 Lv.12')), findsOneWidget);
    });

    testWidgets('자리별 진행도를 같이 얹는다', (tester) async {
      // 탭 여덟 개에 숫자를 하나씩 달면 줄이 시끄러워진다. 고른 자리의 것만
      // 이 카드에서 말한다.
      await pumpCloset(tester);

      expect(inCard(find.text('배경 7 / 9')), findsOneWidget);
    });

    testWidgets('예고 카드가 격자보다 위에 있다', (tester) async {
      await pumpCloset(tester);

      final cardY = tester.getTopLeft(find.byType(CosmeticNextUnlockCard)).dy;
      final tileY = tester.getTopLeft(find.byType(CosmeticSlotEmptyTile)).dy;
      expect(cardY, lessThan(tileY));
    });

    testWidgets('그 자리를 다 모으면 마지막으로 열린 것을 대신 세운다', (tester) async {
      // 빈 채로 높이만 남겨 두면 카드가 고장 난 것처럼 보인다. 그렇다고
      // 축하 문구를 띄우면 자리마다 다 모을 때마다 잔소리가 된다. 다음 대신
      // 마지막을 말한다.
      final cosmetic = await pumpCloset(tester);

      cosmetic.setUnlockAll(true);
      await tester.pumpAndSettle();

      // 카드가 사라지지 않는다. 탭을 옮길 때마다 격자가 위아래로 튀면 안 된다.
      expect(find.byType(CosmeticNextUnlockCard), findsOneWidget);
      expect(inCard(find.text('배경 9 / 9')), findsOneWidget);
      expect(inCard(find.text('마지막으로 열린 것')), findsOneWidget);
      expect(inCard(find.text('이 자리는 더 열릴 것이 없어요')), findsOneWidget);
      expect(inCard(find.text('다음에 열려요')), findsNothing);

      // 축하 문구는 두지 않는다.
      expect(find.textContaining('다 모았'), findsNothing);
      expect(find.textContaining('전부 가졌'), findsNothing);
    });
  });

  group('NEW 표시', () {
    testWidgets('제 능력치에서 막 열린 것에만 붙는다', (tester) async {
      // 출석만 Lv.2 로 올리면 그 레벨에 열리는 것은 배경의 봄 하나다.
      await pumpCloset(tester, levels: CosmeticAbilityLevels(attendance: 2));

      expect(find.text('NEW'), findsOneWidget);

      final badgeX = tester.getCenter(find.text('NEW')).dx;
      final tileX = tester
          .getCenter(
            find.descendant(
              of: find.byType(CosmeticItemTile),
              matching: find.text('봄'),
            ),
          )
          .dx;
      // 왼쪽 위에 붙는다. 오른쪽 위는 입고 있다는 체크 자리다.
      expect(badgeX, lessThan(tileX));
    });

    testWidgets('다른 능력치로 열리는 자리에는 붙지 않는다', (tester) async {
      // 출석을 올렸으니 머리 자리(문제 복습·총 학습)에는 새로 열린 것이 없다.
      await pumpCloset(tester, levels: CosmeticAbilityLevels(attendance: 2));

      expect(find.text('NEW'), findsOneWidget);

      await tester.tap(find.text('머리'));
      await tester.pumpAndSettle();

      expect(find.text('NEW'), findsNothing);
    });
  });

  group('디버그 레벨 패널', () {
    testWidgets('접혀 있고 다섯 레벨이 한 줄에 적혀 있다', (tester) async {
      // 슬라이더 다섯을 펴 두면 개구리보다 조절기가 큰 화면이 된다.
      await pumpCloset(
        tester,
        levels: CosmeticAbilityLevels(
          attendance: 9,
          noteWrite: 5,
          problemPractice: 12,
          notePractice: 3,
          totalStudy: 11,
        ),
      );

      expect(find.byType(CosmeticDebugLevelPanel), findsOneWidget);
      expect(find.text('디버그 레벨'), findsOneWidget);
      // 접힌 줄에도 다섯이 적혀 있어서 펴지 않아도 어디에 서 있는지 읽힌다.
      for (final level in ['9', '5', '12', '3', '11']) {
        expect(find.text(level), findsWidgets, reason: level);
      }
      // 접혀 있으니 슬라이더는 아직 없다.
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('펴면 능력치 다섯을 따로 옮길 수 있다', (tester) async {
      await pumpCloset(tester);

      await tester.tap(find.text('디버그 레벨'));
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNWidgets(5));
      // 총 학습은 넷과 따로 조절한다. 넷에 묶어 두면 총 학습 Lv.16 짜리를
      // 보려고 넷을 다 끝까지 올려야 해서 능력치별 잠금이 하나도 안 남는다.
      expect(find.text('총 학습'), findsOneWidget);
    });

    testWidgets('전부 최대를 누르면 예순셋이 다 열린다', (tester) async {
      final cosmetic = await pumpCloset(tester);

      await tester.tap(find.text('디버그 레벨'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('전부 최대'));
      await tester.pumpAndSettle();

      expect(cosmetic.levels, CosmeticAbilityLevels.max);
      expect(cosmetic.levelsTouched, isTrue);
      expect(find.text('63'), findsOneWidget);
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
