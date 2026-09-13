// 훈장 화면 위젯 테스트.
//
// 이 화면이 하는 말은 셋이다. 무엇을 받았는지, 못 받은 것은 얼마나 남았는지,
// 이번에 새로 받은 것이 있는지. 셋을 여기서 잠근다.
//
// 특히 **진행도가 없는 둘**(불사조·첫 걸음)이 진행도 있는 것과 같은 틀에
// 들어가 빈 눈금을 남기지 않는지를 본다. 서버가 `current` 와 `target` 을 둘 다
// null 로 주는 훈장이라, 눈금을 세우면 늘 텅 비어 있게 되고 그건 "아직 하나도
// 못 했다"로 읽힌다. 불사조는 한 번만 해내면 되는 훈장이라 사실과 다른 말이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Achievement/AchievementBoardModel.dart';
import 'package:ono/Module/Motion/AnimatedGauge.dart';
import 'package:ono/Provider/AchievementProvider.dart';
import 'package:ono/Screen/Achievement/AchievementScreen.dart';
import 'package:ono/Screen/Achievement/Widget/AchievementCard.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  /// 축하거리가 없는 훈장판. 기본값이다.
  ///
  /// 픽스처에는 `newlyEarned` 가 실려 있는데, 축하를 안 보는 테스트까지 매번
  /// 알림을 띄우면 [AppToast] 가 같은 문구를 연달아 막는 규칙에 걸려 정작
  /// 축하를 보는 테스트에서 알림이 안 뜬다. 축하는 그 그룹에서만 켠다.
  AchievementBoardModel boardWithoutNews() {
    final payload = AchievementMockData.payload();
    payload['newlyEarned'] = <String>[];
    return AchievementBoardModel.fromJsonOrNull(payload)!;
  }

  /// 훈장 화면을 띄운다. 프로바이더는 아직 비어 있고, 화면이 들어오면서
  /// 스스로 조회한다. 실제 흐름과 같다.
  Future<AchievementProvider> pumpAchievements(
    WidgetTester tester, {
    FakeAchievementService? service,
    FakeAchievementCelebrationStore? store,
    Size surfaceSize = OnoSurface.phone,
    double textScale = 1.0,
  }) async {
    disableAnimationsForTest(tester);
    final provider = AchievementProvider(
      service: service ?? FakeAchievementService(board: boardWithoutNews()),
      store: store ?? FakeAchievementCelebrationStore(),
    );

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const AchievementScreen(),
        ),
        achievementProvider: provider,
        surfaceSize: surfaceSize,
      );
    });

    return provider;
  }

  /// 알림이 스스로 닫힐 때까지 태워 보낸다. 안 그러면 타이머가 남는다.
  Future<void> settleToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  Finder cardOf(String key) => find.byWidgetPredicate(
        (widget) => widget is AchievementCard && widget.achievement.key == key,
        description: '$key 카드',
      );

  Finder gaugeIn(Finder card) => find.descendant(
        of: card,
        matching: find.byType(AnimatedLinearGauge),
      );

  /// 한 훈장만 못 받은 것으로 바꾼 훈장판.
  ///
  /// 픽스처에서는 불사조와 첫 걸음이 둘 다 이미 받은 것이라, **못 받았고
  /// 진행도도 없는** 칸을 보려면 하나를 되돌려야 한다.
  AchievementBoardModel boardWithLocked(String key) {
    final payload = AchievementMockData.payload();
    final rows = payload['achievements']! as List<dynamic>;
    for (final row in rows) {
      final item = row as Map<String, dynamic>;
      if (item['key'] != key) continue;
      item['earned'] = false;
      item['earnedAt'] = null;
    }
    payload['newlyEarned'] = <String>[];
    return AchievementBoardModel.fromJsonOrNull(payload)!;
  }

  group('목록', () {
    testWidgets('훈장표의 순서 그대로 그린다', (tester) async {
      await pumpAchievements(tester);
      await settleToast(tester);

      // 목록이 길어 화면 밖의 줄은 아직 안 만들어진다. 앞쪽 순서만 본다.
      final drawn = tester
          .widgetList<AchievementCard>(find.byType(AchievementCard))
          .map((card) => card.achievement.key)
          .toList();

      expect(drawn, isNotEmpty);
      expect(drawn, AchievementMockData.keys.take(drawn.length));
    });

    testWidgets('이름과 설명은 훈장표의 말 그대로다', (tester) async {
      await pumpAchievements(tester);
      await settleToast(tester);

      expect(find.text('첫 걸음'), findsOneWidget);
      expect(find.text('오답노트를 처음 적었어요'), findsOneWidget);
      expect(find.text('기록광'), findsOneWidget);
      expect(find.text('오답노트를 백 개나 모았어요'), findsOneWidget);
    });

    testWidgets('몇 개 중 몇 개를 모았는지 맨 위에 있다', (tester) async {
      await pumpAchievements(tester);
      await settleToast(tester);

      expect(find.text('모은 훈장'), findsOneWidget);
      expect(find.text(' / 12'), findsOneWidget);
    });

    testWidgets('받은 것과 못 받은 것이 한 화면에 섞여 있다', (tester) async {
      await pumpAchievements(tester);
      await settleToast(tester);

      // 받은 것은 제 색, 못 받은 것은 흑백이다. 감추지는 않는다.
      expect(cardOf('first_step'), findsOneWidget);
      expect(cardOf('archivist'), findsOneWidget);
      expect(
        tester.widget<AchievementCard>(cardOf('first_step')).achievement.earned,
        isTrue,
      );
      expect(
        tester.widget<AchievementCard>(cardOf('archivist')).achievement.earned,
        isFalse,
      );
    });
  });

  group('진행도', () {
    testWidgets('못 받은 것에 얼마나 왔는지 숫자와 눈금이 함께 있다', (tester) async {
      await pumpAchievements(tester);
      await settleToast(tester);

      // 87 / 100 이 있으면 이미 코앞이라는 것이 보인다.
      expect(find.text('87 / 100'), findsOneWidget);
      expect(gaugeIn(cardOf('archivist')), findsOneWidget);
    });

    testWidgets('받은 것에는 눈금 대신 받은 날이 적힌다', (tester) async {
      // 열두 줄이 전부 눈금이면 정작 코앞에 온 하나가 그 속에 묻힌다.
      await pumpAchievements(tester);
      await settleToast(tester);

      expect(gaugeIn(cardOf('first_step')), findsNothing);
      expect(find.text('2026년 3월 2일에 받았어요'), findsOneWidget);
    });

    testWidgets('진행도가 없는 훈장은 받은 뒤에도 눈금을 안 만든다', (tester) async {
      await pumpAchievements(tester);
      await settleToast(tester);

      expect(gaugeIn(cardOf('phoenix')), findsNothing);
    });

    testWidgets('진행도 없이 못 받은 훈장은 빈 눈금 대신 한 줄로 말한다', (tester) async {
      // 이 화면에서 가장 헷갈리기 쉬운 칸이다. 0 아니면 1인 훈장에 눈금을
      // 세우면 늘 텅 비어 있고, 그건 "아직 하나도 못 했다"로 읽힌다.
      await pumpAchievements(
        tester,
        service: FakeAchievementService(board: boardWithLocked('phoenix')),
      );
      await settleToast(tester);

      expect(gaugeIn(cardOf('phoenix')), findsNothing);
      expect(find.text('한 번만 해내면 받아요'), findsOneWidget);
    });
  });

  group('새로 받은 훈장', () {
    testWidgets('알림을 띄우고 그 줄에 NEW 를 단다', (tester) async {
      await pumpAchievements(tester, service: FakeAchievementService());

      expect(find.text('개근 훈장을 받았어요!'), findsOneWidget);
      await settleToast(tester);

      final card = tester.widget<AchievementCard>(cardOf('perfect_month'));
      expect(card.isNew, isTrue);
      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('여럿이면 개수를 센다', (tester) async {
      final payload = AchievementMockData.payload();
      payload['newlyEarned'] = ['perfect_month', 'phoenix'];

      await pumpAchievements(
        tester,
        service: FakeAchievementService(
          board: AchievementBoardModel.fromJsonOrNull(payload)!,
        ),
      );

      expect(find.text('새 훈장 2개를 받았어요!'), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('알린 축하는 프로바이더에서 비워진다', (tester) async {
      // 한 번 알렸으면 다음에 들어올 때 또 축하하지 않는다.
      final store = FakeAchievementCelebrationStore();
      final provider = await pumpAchievements(
        tester,
        service: FakeAchievementService(),
        store: store,
      );
      await settleToast(tester);

      expect(provider.hasNews, isFalse);
      expect(store.stored, isEmpty);
    });

    testWidgets('앱을 다시 켜도 못 알린 축하는 살아남는다', (tester) async {
      // 저장소에만 남아 있고 이번 조회의 newlyEarned 에는 없는 경우다.
      final store = FakeAchievementCelebrationStore({'organizer'});

      await pumpAchievements(tester, store: store);

      expect(find.text('정리의 신 훈장을 받았어요!'), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('새로 받은 것이 없으면 알리지 않는다', (tester) async {
      await pumpAchievements(tester);
      await settleToast(tester);

      expect(find.text('NEW'), findsNothing);
    });
  });

  group('못 불러왔을 때', () {
    testWidgets('오류로 몰아붙이지 않고 다시 시도를 준다', (tester) async {
      // 이 API 가 아직 배포되기 전에도 이 화면은 열린다.
      await pumpAchievements(
        tester,
        service: FakeAchievementService(failLoad: true),
      );

      expect(find.text('훈장을 불러오지 못했어요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.byType(AchievementCard), findsNothing);
    });

    testWidgets('다시 시도를 누르면 한 번 더 묻는다', (tester) async {
      final service = FakeAchievementService(failLoad: true);
      await pumpAchievements(tester, service: service);

      service.failLoad = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(find.byType(AchievementCard), findsWidgets);
      await settleToast(tester);
    });

    testWidgets('못 불러왔으면 축하도 꺼내 쓰지 않는다', (tester) async {
      // 꺼내면 프로바이더가 비워져서, 이름도 그림도 못 보여 준 채 축하
      // 기회만 날아간다.
      final store = FakeAchievementCelebrationStore({'organizer'});
      final provider = await pumpAchievements(
        tester,
        service: FakeAchievementService(failLoad: true),
        store: store,
      );

      expect(provider.hasNews, isTrue);
      expect(store.stored, {'organizer'});
    });
  });

  group('크기', () {
    for (final surface in <String, Size>{
      '작은 폰': OnoSurface.smallPhone,
      '폰': OnoSurface.phone,
      '태블릿': OnoSurface.tablet,
    }.entries) {
      for (final scale in <String, double>{
        '보통 글자': 1.0,
        '글자 1.6배': 1.6,
      }.entries) {
        testWidgets('${surface.key} · ${scale.value} 에서 넘치지 않는다',
            (tester) async {
          await pumpAchievements(
            tester,
            surfaceSize: surface.value,
            textScale: scale.value,
          );
          await settleToast(tester);

          expect(tester.takeException(), isNull);
          expect(find.byType(AchievementCard), findsWidgets);
        });
      }
    }
  });
}
