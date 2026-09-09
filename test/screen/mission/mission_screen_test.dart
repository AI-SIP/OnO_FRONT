// MissionScreen 위젯 테스트.
//
// 받기 버튼의 세 상태(진행 중 / 받기 / 받음)가 각각 맞게 그려지는지와,
// 받은 뒤 XP 문구와 레벨업 알림이 뜨는지가 관찰 대상이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Mission/MissionClaimResultModel.dart';
import 'package:ono/Model/Mission/MissionGroupModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Module/Design/AppToast.dart';
import 'package:ono/Provider/MissionProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/Mission/MissionScreen.dart';

import '../../helpers/helpers.dart';

MissionModel buildMission({
  required String code,
  required String title,
  int? progressId,
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

void main() {
  setUpOnoWidgetTest();

  setUpAll(() {
    registerFallbackValue((String _) {});
  });

  tearDown(AppToast.dismiss);

  MissionBoardModel boardWithThreeStates() {
    return MissionBoardModel(
      daily: MissionGroupModel(
        periodKey: '2026-09-09',
        missions: [
          buildMission(
            code: 'DAILY_REVIEW_3',
            title: '세 문제만',
            progressId: 1,
            current: 1,
          ),
          buildMission(
            code: 'DAILY_NOTE_WRITE',
            title: '오늘의 오답',
            progressId: 2,
            current: 1,
            target: 1,
            completed: true,
          ),
          buildMission(
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
    );
  }

  /// 화면이 읽는 Provider 를 물려 MissionScreen 을 띄운다.
  Future<MissionProvider> pumpMissionScreen(
    WidgetTester tester, {
    required MockMissionService missionService,
    UserProvider? userProvider,
  }) async {
    final missionProvider = MissionProvider(missionService: missionService);

    await pumpOnoWidget(
      tester,
      const MissionScreen(),
      missionProvider: missionProvider,
      userProvider: userProvider,
    );

    return missionProvider;
  }

  UserProvider buildUserProvider() {
    final userService = MockUserService();
    // 보상 뒤 사용자 정보 갱신은 화면이 예외를 삼킨다. 여기서는 네트워크를
    // 타지 않게만 막아 둔다.
    when(() => userService.fetchUserInfo(
          showErrorSnackBar: any(named: 'showErrorSnackBar'),
        )).thenThrow(Exception('테스트에서는 사용자 정보를 읽지 않는다'));

    final problems = ProblemsProvider();
    final folders = FoldersProvider(problemsProvider: problems);
    final practice = ProblemPracticeProvider(problemsProvider: problems);
    return UserProvider(problems, folders, practice, userService: userService);
  }

  group('받기 버튼 세 상태', () {
    testWidgets('진행 중 / 받기 / 받음 이 각각 그려진다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());

      await pumpMissionScreen(tester, missionService: missionService);

      expect(find.text('세 문제만'), findsOneWidget);
      expect(find.text('진행 중'), findsOneWidget);
      expect(find.text('받기'), findsOneWidget);
      expect(find.text('받음'), findsOneWidget);
    });

    testWidgets('완료하고 안 받은 것만 눌린다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());

      await pumpMissionScreen(tester, missionService: missionService);

      ElevatedButton buttonOf(String label) => tester.widget<ElevatedButton>(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(ElevatedButton),
            ),
          );

      expect(buttonOf('받기').onPressed, isNotNull);
      expect(buttonOf('진행 중').onPressed, isNull);
      expect(buttonOf('받음').onPressed, isNull);
    });

    testWidgets('progressId 가 없으면 완료여도 누를 수 없다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer(
        (_) async => MissionBoardModel(
          daily: MissionGroupModel(
            periodKey: '2026-09-09',
            missions: [
              buildMission(
                code: 'DAILY_MOOD',
                title: '오늘 기분',
                current: 1,
                target: 1,
                completed: true,
              ),
            ],
          ),
          weekly: const MissionGroupModel(periodKey: '2026-W37', missions: []),
        ),
      );

      await pumpMissionScreen(tester, missionService: missionService);

      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('받기'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('조회 실패', () {
    testWidgets('404 가 떨어져도 오류 없이 조용한 안내만 남는다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer((_) async => null);

      await pumpMissionScreen(tester, missionService: missionService);

      expect(find.text('아직 볼 수 있는 미션이 없어요.'), findsWidgets);
      expect(find.text('받기'), findsNothing);
    });
  });

  group('보상 받기', () {
    testWidgets('받으면 XP 문구가 뜨고 버튼이 받음으로 바뀐다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer(
        (_) async => const MissionClaimResultModel(
          progressId: 2,
          rewardType: MissionRewardType.xp,
          rewardValue: 10,
          totalStudyLevel: 7,
          leveledUp: false,
        ),
      );

      await pumpMissionScreen(
        tester,
        missionService: missionService,
        userProvider: buildUserProvider(),
      );

      await tester.tap(find.text('받기'));
      await tester.pumpAndSettle();

      expect(find.text('+10 XP'), findsWidgets);
      expect(find.text('받기'), findsNothing);
      expect(find.text('받음'), findsNWidgets(2));
      verify(() => missionService.claim(2, onFailure: any(named: 'onFailure')))
          .called(1);
    });

    testWidgets('leveledUp 이면 레벨업 알림을 띄운다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer(
        (_) async => const MissionClaimResultModel(
          progressId: 2,
          rewardType: MissionRewardType.xp,
          rewardValue: 10,
          totalStudyLevel: 7,
          leveledUp: true,
        ),
      );

      await pumpMissionScreen(
        tester,
        missionService: missionService,
        userProvider: buildUserProvider(),
      );

      await tester.tap(find.text('받기'));
      await tester.pumpAndSettle();

      expect(find.text('레벨이 올랐어요!'), findsOneWidget);
      expect(find.text('이제 Lv.7 이에요.'), findsOneWidget);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('레벨이 올랐어요!'), findsNothing);
    });

    testWidgets('받는 동안에는 버튼이 잠긴다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return const MissionClaimResultModel(
          progressId: 2,
          rewardType: MissionRewardType.xp,
          rewardValue: 10,
          totalStudyLevel: 7,
          leveledUp: false,
        );
      });

      await pumpMissionScreen(
        tester,
        missionService: missionService,
        userProvider: buildUserProvider(),
      );

      await tester.tap(find.text('받기'));
      await tester.pump();

      // 응답이 오기 전에는 '받기' 글씨가 사라지고 눌러도 요청이 더 나가지 않는다.
      expect(find.text('받기'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      verify(() => missionService.claim(2, onFailure: any(named: 'onFailure')))
          .called(1);
    });
  });
}
