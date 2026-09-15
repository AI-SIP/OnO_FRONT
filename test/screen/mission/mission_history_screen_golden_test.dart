// 보상 기록 화면 골든 테스트.
//
// 날짜 머리글이 `오늘`/`어제` 로 갈려서 시계를 고정한다. 위젯 테스트와 같은 시각이다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Mission/MissionHistoryModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Screen/Mission/MissionHistoryScreen.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  final now = DateTime(2026, 9, 10, 15, 0);

  MissionHistoryItemModel item({
    required int progressId,
    required DateTime claimedAt,
    required String code,
    required String title,
    required int rewardValue,
  }) {
    return MissionHistoryItemModel(
      progressId: progressId,
      code: code,
      title: title,
      iconKey: 'note_write',
      category: MissionCategory.daily,
      periodKey: '2026-09-10',
      rewardType: MissionRewardType.xp,
      rewardValue: rewardValue,
      claimedAt: claimedAt,
    );
  }

  screenGoldenTest(
    '보상 기록 화면',
    fileName: 'mission_history_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: () async {
      final missionService = MockMissionService();
      when(() => missionService.getHistory(cursor: null)).thenAnswer(
        (_) async => MissionHistoryPageModel(
          content: [
            item(
              progressId: 1,
              claimedAt: DateTime(2026, 9, 10, 14, 33),
              code: 'DAILY_NOTE_WRITE',
              title: '오늘의 오답',
              rewardValue: 10,
            ),
            item(
              progressId: 2,
              claimedAt: DateTime(2026, 9, 9, 21, 5),
              code: 'DAILY_REVIEW_3',
              title: '세 문제만',
              rewardValue: 15,
            ),
            item(
              progressId: 3,
              claimedAt: DateTime(2026, 9, 5, 9, 12),
              code: 'DAILY_ATTEND',
              title: '출석',
              rewardValue: 5,
            ),
          ],
          nextCursor: null,
          hasNext: false,
          totalClaimedXp: 1250,
          totalClaimedCount: 37,
        ),
      );

      return buildOnoApp(
        MissionHistoryScreen(missionService: missionService, clock: () => now),
        cosmeticProvider: await loadedCosmeticProvider(),
      );
    },
  );
}
