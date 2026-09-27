// 옷장 탭(캐릭터 화면) 골든 테스트.
//
// 개구리와 능력치 넷, 훈장 줄, 버튼 둘이 스크롤 없이 한 화면에 들어오는 것이
// 이 화면의 약속이라, 그 배치를 이미지로 잠근다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
import 'package:ono/Model/Mission/MissionGroupModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Module/Debug/DebugLevels.dart';
import 'package:ono/Provider/MissionProvider.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/Character/CharacterScreen.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '캐릭터 화면',
    fileName: 'character_screen',
    // 스크롤 없이 한 화면에 들어오는 것이 약속이라 작은 폰과 큰 글씨도 본다.
    buildApp: () async {
      final served = UserInfoModel(
        userId: 1,
        name: '테스터',
        totalStudyLevel: 7,
        totalStudyCurrentPoint: 24,
        totalStudyNextLevelThreshold: 60,
        attendanceLevel: 3,
        attendancePoint: 8,
        noteWriteLevel: 5,
        noteWritePoint: 12,
        problemPracticeLevel: 2,
        problemPracticePoint: 4,
        notePracticeLevel: 1,
        notePracticePoint: 6,
      );
      final userProvider = _FakeUserProvider();
      when(() => userProvider.isLoggedIn).thenReturn(LoginStatus.login);
      when(() => userProvider.userInfoModel)
          .thenAnswer((_) => DebugLevels.applyTo(served));
      when(() => userProvider.addListener(any())).thenReturn(null);
      when(() => userProvider.removeListener(any())).thenReturn(null);
      when(() => userProvider.dispose()).thenReturn(null);
      when(() => userProvider.fetchUserInfo(
            showErrorSnackBar: any(named: 'showErrorSnackBar'),
          )).thenAnswer((_) async {});

      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer(
        (_) async => MissionBoardModel(
          daily: MissionGroupModel(
            periodKey: '2026-09-11',
            missions: [
              MissionModel(
                progressId: 2,
                code: 'DAILY_NOTE_WRITE',
                title: '오늘의 오답',
                description: '오늘의 오답 설명',
                iconKey: 'note_write',
                category: MissionCategory.daily,
                current: 1,
                target: 1,
                completed: true,
                claimed: false,
                rewardType: MissionRewardType.xp,
                rewardValue: 10,
              ),
            ],
          ),
          weekly: const MissionGroupModel(periodKey: '2026-W37', missions: []),
        ),
      );

      return buildOnoApp(
        const CharacterScreen(),
        cosmeticProvider: await loadedCosmeticProvider(
          levels: CosmeticAbilityLevels.uniform(12),
        ),
        userProvider: userProvider,
        missionProvider: MissionProvider(missionService: missionService),
      );
    },
  );
}
