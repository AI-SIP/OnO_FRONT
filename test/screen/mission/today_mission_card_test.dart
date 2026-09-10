// 홈 상단 미션 배너 테스트.
//
// 미션 조회에 실패했거나 미션이 없으면 배너가 통째로 사라져야 한다. 백엔드에
// 아직 미션 API 가 없는 동안 홈에 빈 카드나 오류가 남지 않아야 한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Mission/MissionGroupModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Provider/MissionProvider.dart';
import 'package:ono/Screen/Mission/MissionScreen.dart';
import 'package:ono/Screen/Mission/TodayMissionCard.dart';

import '../../helpers/helpers.dart';

MissionModel buildMission({
  required String code,
  int? progressId,
  bool completed = false,
  bool claimed = false,
  String? periodKey,
}) {
  return MissionModel(
    progressId: progressId,
    code: code,
    title: code,
    description: '$code 설명',
    iconKey: 'note_write',
    category: MissionCategory.daily,
    current: completed ? 1 : 0,
    target: 1,
    completed: completed,
    claimed: claimed,
    rewardType: MissionRewardType.xp,
    rewardValue: 10,
    periodKey: periodKey,
  );
}

void main() {
  setUpOnoWidgetTest();

  Future<MissionProvider> pumpCard(
    WidgetTester tester,
    MissionBoardModel? board, {
    Size surfaceSize = OnoSurface.phone,
  }) async {
    disableAnimationsForTest(tester);
    final missionService = MockMissionService();
    when(() => missionService.getMissions()).thenAnswer((_) async => board);
    final provider = MissionProvider(missionService: missionService);
    await provider.fetchMissions();

    await pumpOnoWidget(
      tester,
      const Scaffold(body: TodayMissionCard()),
      missionProvider: provider,
      surfaceSize: surfaceSize,
    );

    return provider;
  }

  MissionBoardModel buildBoard() {
    return MissionBoardModel(
      daily: MissionGroupModel(
        periodKey: '2026-09-09',
        missions: [
          buildMission(code: 'DAILY_ATTEND', progressId: 1, completed: true),
          buildMission(code: 'DAILY_NOTE_WRITE', progressId: 2),
          buildMission(code: 'DAILY_MOOD', progressId: 3),
        ],
      ),
      weekly: const MissionGroupModel(periodKey: '2026-W37', missions: []),
    );
  }

  testWidgets('미션이 있으면 진행도를 보여 준다', (tester) async {
    await pumpCard(tester, buildBoard());

    expect(find.text('오늘의 미션'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('받기 1'), findsOneWidget);
  });

  testWidgets('조회에 실패하면 배너를 통째로 숨긴다', (tester) async {
    await pumpCard(tester, null);

    expect(find.text('오늘의 미션'), findsNothing);
  });

  testWidgets('미션이 하나도 없으면 배너를 숨긴다', (tester) async {
    await pumpCard(
      tester,
      const MissionBoardModel(
        daily: MissionGroupModel(periodKey: '2026-09-09', missions: []),
        weekly: MissionGroupModel(periodKey: '2026-W37', missions: []),
      ),
    );

    expect(find.text('오늘의 미션'), findsNothing);
  });

  testWidgets('받을 것이 없으면 개수 배지를 띄우지 않는다', (tester) async {
    await pumpCard(
      tester,
      MissionBoardModel(
        daily: MissionGroupModel(
          periodKey: '2026-09-09',
          missions: [
            buildMission(
              code: 'DAILY_ATTEND',
              progressId: 1,
              completed: true,
              claimed: true,
            ),
          ],
        ),
        weekly: const MissionGroupModel(periodKey: '2026-W37', missions: []),
      ),
    );

    expect(find.text('오늘의 미션'), findsOneWidget);
    expect(find.textContaining('받기'), findsNothing);
  });

  testWidgets('주간에만 받을 것이 있으면 배지를 띄우지 않는다', (tester) async {
    // 진행도는 일일만 세는데 배지가 주간까지 세면 "0/1" 옆에 "받기 2" 가
    // 붙는다. 배너가 "오늘의 미션"이니 둘 다 일일 기준이어야 한다.
    await pumpCard(
      tester,
      MissionBoardModel(
        daily: MissionGroupModel(
          periodKey: '2026-09-09',
          missions: [buildMission(code: 'DAILY_NOTE_WRITE', progressId: 1)],
        ),
        weekly: MissionGroupModel(
          periodKey: '2026-W37',
          missions: [
            buildMission(
              code: 'WEEKLY_NOTE_10',
              progressId: 9001,
              completed: true,
            ),
            buildMission(
              code: 'WEEKLY_SET_3',
              progressId: 9002,
              completed: true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('오늘의 미션'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);
    expect(find.textContaining('받기'), findsNothing);
  });

  testWidgets('지난 미션은 진행도에 안 들어가고 배지에는 들어간다', (tester) async {
    // 기간을 넘긴 미수령 보상이 배지에 안 잡히면 사용자가 있는 줄도 모른다.
    // 그렇다고 "오늘의 미션" 진행도에 섞으면 오늘 하지도 않은 것이 채워진다.
    await pumpCard(
      tester,
      MissionBoardModel(
        daily: MissionGroupModel(
          periodKey: '2026-09-09',
          missions: [buildMission(code: 'DAILY_NOTE_WRITE', progressId: 1)],
        ),
        weekly: const MissionGroupModel(periodKey: '2026-W37', missions: []),
        expired: MissionGroupModel(
          periodKey: '',
          missions: [
            buildMission(
              code: 'WEEKLY_REVIEW_30',
              progressId: 777,
              completed: true,
              periodKey: '2026-W36',
            ),
          ],
        ),
      ),
    );

    expect(find.text('0/1'), findsOneWidget);
    expect(find.text('받기 1'), findsOneWidget);
  });

  testWidgets('지난 미션만 남아도 배너를 숨기지 않는다', (tester) async {
    await pumpCard(
      tester,
      MissionBoardModel(
        daily: const MissionGroupModel(periodKey: '2026-09-09', missions: []),
        weekly: const MissionGroupModel(periodKey: '2026-W37', missions: []),
        expired: MissionGroupModel(
          periodKey: '',
          missions: [
            buildMission(
              code: 'WEEKLY_REVIEW_30',
              progressId: 777,
              completed: true,
              periodKey: '2026-W36',
            ),
          ],
        ),
      ),
    );

    expect(find.text('오늘의 미션'), findsOneWidget);
    expect(find.text('받기 1'), findsOneWidget);
  });

  testWidgets('태블릿 폭에서도 넘치지 않는다', (tester) async {
    await pumpCard(tester, buildBoard(), surfaceSize: OnoSurface.tablet);

    expect(tester.takeException(), isNull);
    expect(find.text('오늘의 미션'), findsOneWidget);
  });

  testWidgets('글자를 크게 키워도 넘치지 않는다', (tester) async {
    disableAnimationsForTest(tester);
    final missionService = MockMissionService();
    when(() => missionService.getMissions())
        .thenAnswer((_) async => buildBoard());
    final provider = MissionProvider(missionService: missionService);
    await provider.fetchMissions();

    await pumpOnoWidget(
      tester,
      // 통째로 갈아 끼우면 연출을 끈 설정까지 지워진다. 지금은 안 깨지지만
      // 이 카드에 끝나지 않는 연출이 하나만 붙어도 pumpAndSettle 이 멈춘다.
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: const Scaffold(body: TodayMissionCard()),
        ),
      ),
      missionProvider: provider,
      surfaceSize: OnoSurface.smallPhone,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('탭하면 미션 화면으로 간다', (tester) async {
    await pumpCard(tester, buildBoard());

    await tester.tap(find.text('오늘의 미션'));
    await tester.pumpAndSettle();

    expect(find.byType(MissionScreen), findsOneWidget);
  });
}
