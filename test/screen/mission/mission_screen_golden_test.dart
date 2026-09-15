// 미션 화면 골든 테스트.
//
// 받을 수 있음, 진행 중, 받음 세 상태가 한 화면에 같이 있게 뜬다. 이 화면이
// 지키려는 것이 세 상태의 무게가 다르게 보이는 것이라서다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Mission/MissionGroupModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Provider/MissionProvider.dart';
import 'package:ono/Screen/Mission/MissionScreen.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  MissionModel mission({
    required String code,
    required String title,
    required int progressId,
    int current = 0,
    int target = 3,
    bool completed = false,
    bool claimed = false,
  }) {
    return MissionModel(
      progressId: progressId,
      code: code,
      title: title,
      description: '$title 설명',
      iconKey: 'note_write',
      category: MissionCategory.daily,
      current: current,
      target: target,
      completed: completed,
      claimed: claimed,
      rewardType: MissionRewardType.xp,
      rewardValue: 10,
    );
  }

  screenGoldenTest(
    '미션 화면',
    fileName: 'mission_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: () async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer(
        (_) async => MissionBoardModel(
          daily: MissionGroupModel(
            periodKey: '2026-09-09',
            missions: [
              mission(
                code: 'DAILY_REVIEW_3',
                title: '세 문제만',
                progressId: 1,
                current: 1,
              ),
              mission(
                code: 'DAILY_NOTE_WRITE',
                title: '오늘의 오답',
                progressId: 2,
                current: 1,
                target: 1,
                completed: true,
              ),
              mission(
                code: 'DAILY_ATTEND',
                title: '출석',
                progressId: 3,
                current: 1,
                target: 1,
                completed: true,
                claimed: true,
              ),
            ],
          ),
          weekly: const MissionGroupModel(periodKey: '2026-W37', missions: []),
        ),
      );

      return buildOnoApp(
        const MissionScreen(),
        cosmeticProvider: await loadedCosmeticProvider(),
        missionProvider: MissionProvider(missionService: missionService),
      );
    },
  );
}
