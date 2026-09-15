// 훈장 화면 골든 테스트.
//
// 위젯 테스트(achievement_screen_test.dart)는 무엇이 몇 개 그려지는지와 넘치지
// 않는지를 본다. 여기서는 그렇게 그려진 화면이 **어떻게 생겼는지**를 이미지로
// 잠근다. 패딩이나 색이 바뀌면 위젯 테스트는 통과해도 여기서 깨진다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:ono/Model/Achievement/AchievementBoardModel.dart';
import 'package:ono/Provider/AchievementProvider.dart';
import 'package:ono/Screen/Achievement/AchievementScreen.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '훈장 화면',
    fileName: 'achievement_screen',
    buildApp: () async {
      // 축하 알림은 끈다. 알림이 떠 있으면 스스로 닫히는 타이머가 남고, 뜨는
      // 중간 프레임이 찍혀서 이미지가 흔들린다.
      final payload = AchievementMockData.payload();
      payload['newlyEarned'] = <String>[];

      return buildOnoApp(
        const AchievementScreen(),
        cosmeticProvider: await loadedCosmeticProvider(),
        achievementProvider: AchievementProvider(
          service: FakeAchievementService(
            board: AchievementBoardModel.fromJsonOrNull(payload)!,
          ),
          store: FakeAchievementCelebrationStore(),
        ),
      );
    },
  );
}
