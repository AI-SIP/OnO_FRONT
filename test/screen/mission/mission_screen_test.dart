// MissionScreen 위젯 테스트.
//
// 받기 버튼의 세 상태(진행 중 / 받기 / 받음)가 각각 맞게 그려지는지와,
// 받은 뒤 XP 문구와 레벨업 알림이 뜨는지가 관찰 대상이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Constants/ErrorMessages.dart';
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
  String? periodKey,
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
    periodKey: periodKey,
  );
}

void main() {
  setUpOnoWidgetTest();

  setUpAll(() {
    registerFallbackValue((MissionClaimFailure _) {});
  });

  tearDown(AppToast.dismiss);

  MissionBoardModel boardWithThreeStates({bool secondClaimed = false}) {
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
            claimed: secondClaimed,
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

  group('지난 미션 섹션', () {
    MissionBoardModel boardWithExpired({
      List<MissionModel> expired = const [],
    }) {
      return MissionBoardModel(
        daily: MissionGroupModel(
          periodKey: '2026-09-09',
          missions: [
            buildMission(
              code: 'DAILY_NOTE_WRITE',
              title: '오늘의 오답',
              progressId: 2,
              current: 1,
              target: 1,
              completed: true,
            ),
          ],
        ),
        weekly: const MissionGroupModel(periodKey: '2026-W37', missions: []),
        expired: MissionGroupModel(periodKey: '', missions: expired),
      );
    }

    testWidgets('지난 미션이 없으면 섹션이 아예 없다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithExpired());

      await pumpMissionScreen(tester, missionService: missionService);

      expect(find.text('지난 미션'), findsNothing);
      expect(find.text('오늘의 오답'), findsOneWidget);
    });

    testWidgets('지난 미션이 있으면 일일 탭 맨 위에 섹션으로 붙는다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer(
        (_) async => boardWithExpired(
          expired: [
            buildMission(
              code: 'WEEKLY_REVIEW_30',
              title: '서른 번의 복습',
              progressId: 777,
              current: 30,
              target: 30,
              completed: true,
              periodKey: '2026-W36',
            ),
          ],
        ),
      );

      await pumpMissionScreen(tester, missionService: missionService);

      expect(find.text('지난 미션'), findsOneWidget);
      expect(find.text('서른 번의 복습'), findsOneWidget);
      // 서버 키를 그대로 보여 주지 않는다.
      expect(find.text('2026-W36'), findsNothing);
      expect(find.textContaining('주'), findsWidgets);

      // 지난 미션이 오늘 것보다 위에 있다.
      final expiredY = tester.getTopLeft(find.text('서른 번의 복습')).dy;
      final todayY = tester.getTopLeft(find.text('오늘의 오답')).dy;
      expect(expiredY, lessThan(todayY));
    });

    testWidgets('지난 미션도 새 탭 없이 같은 두 탭 안에 있다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer(
        (_) async => boardWithExpired(
          expired: [
            buildMission(
              code: 'WEEKLY_REVIEW_30',
              title: '서른 번의 복습',
              progressId: 777,
              completed: true,
              periodKey: '2026-W36',
            ),
          ],
        ),
      );

      await pumpMissionScreen(tester, missionService: missionService);

      expect(find.byType(Tab), findsNWidgets(2));
      expect(find.text('일일'), findsOneWidget);
      expect(find.text('주간'), findsOneWidget);
    });

    testWidgets('지난 미션도 받기가 된다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer(
        (_) async => boardWithExpired(
          expired: [
            buildMission(
              code: 'WEEKLY_REVIEW_30',
              title: '서른 번의 복습',
              progressId: 777,
              current: 30,
              target: 30,
              completed: true,
              periodKey: '2026-W36',
            ),
          ],
        ),
      );
      when(() => missionService.claim(
            777,
            onFailure: any(named: 'onFailure'),
          )).thenAnswer(
        (_) async => const MissionClaimResultModel(
          progressId: 777,
          rewardType: MissionRewardType.xp,
          rewardValue: 100,
          totalStudyLevel: 8,
          leveledUp: false,
        ),
      );

      await pumpMissionScreen(
        tester,
        missionService: missionService,
        userProvider: buildUserProvider(),
      );

      // 지난 미션 줄의 받기 버튼을 누른다.
      await tester.tap(find.text('받기').first);
      await tester.pumpAndSettle();

      expect(find.text('+100 XP'), findsWidgets);
      verify(() =>
              missionService.claim(777, onFailure: any(named: 'onFailure')))
          .called(1);
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

    testWidgets('이미 받은 미션(7012)이면 오류를 띄우지 않고 화면만 맞춘다', (tester) async {
      // 서버 기준으로는 이미 받은 상태다. 사용자에게는 실패가 아니다.
      final missionService = MockMissionService();
      var serverClaimed = false;
      when(() => missionService.getMissions()).thenAnswer(
        (_) async => boardWithThreeStates(secondClaimed: serverClaimed),
      );
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((invocation) async {
        serverClaimed = true;
        final onFailure = invocation.namedArguments[#onFailure] as void
            Function(MissionClaimFailure)?;
        onFailure?.call(const MissionClaimFailure(
          kind: MissionClaimFailureKind.rejected,
          errorCode: 7012,
          message: ErrorMessages.missionAlreadyClaimed,
        ));
        return null;
      });

      await pumpMissionScreen(
        tester,
        missionService: missionService,
        userProvider: buildUserProvider(),
      );

      await tester.tap(find.text('받기'));
      await tester.pumpAndSettle();

      expect(find.text(ErrorMessages.missionAlreadyClaimed), findsNothing);
      expect(find.text('받기'), findsNothing);
      expect(find.text('받음'), findsNWidgets(2));
    });

    testWidgets('아직 완료하지 않은 미션(7011)이면 이유를 알린다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((invocation) async {
        final onFailure = invocation.namedArguments[#onFailure] as void
            Function(MissionClaimFailure)?;
        onFailure?.call(const MissionClaimFailure(
          kind: MissionClaimFailureKind.rejected,
          errorCode: 7011,
          message: ErrorMessages.missionNotCompleted,
        ));
        return null;
      });

      await pumpMissionScreen(
        tester,
        missionService: missionService,
        userProvider: buildUserProvider(),
      );

      await tester.tap(find.text('받기'));
      await tester.pumpAndSettle();

      expect(find.text(ErrorMessages.missionNotCompleted), findsOneWidget);
    });

    testWidgets('답을 못 받았어도 서버가 줬으면 받은 것으로 알린다', (tester) async {
      // 응답을 받는 중 연결이 끊긴 경우다. 서버는 이미 XP 를 줬는데 실패라고
      // 알리면 사용자가 두 번 누른다.
      final missionService = MockMissionService();
      var serverClaimed = false;
      when(() => missionService.getMissions()).thenAnswer(
        (_) async => boardWithThreeStates(secondClaimed: serverClaimed),
      );
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((invocation) async {
        serverClaimed = true;
        final onFailure = invocation.namedArguments[#onFailure] as void
            Function(MissionClaimFailure)?;
        onFailure?.call(const MissionClaimFailure(
          kind: MissionClaimFailureKind.unknown,
          message: ErrorMessages.network,
        ));
        return null;
      });

      await pumpMissionScreen(
        tester,
        missionService: missionService,
        userProvider: buildUserProvider(),
      );

      await tester.tap(find.text('받기'));
      await tester.pumpAndSettle();

      expect(find.text('+10 XP'), findsWidgets);
      expect(find.text(ErrorMessages.network), findsNothing);
      expect(find.text('받음'), findsNWidgets(2));
    });

    testWidgets('결과도 확인하지 못하면 중립적인 안내만 남긴다', (tester) async {
      final missionService = MockMissionService();
      var answered = true;
      when(() => missionService.getMissions()).thenAnswer(
        (_) async => answered ? boardWithThreeStates() : null,
      );
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((invocation) async {
        answered = false; // 이제 조회도 답하지 않는다
        final onFailure = invocation.namedArguments[#onFailure] as void
            Function(MissionClaimFailure)?;
        onFailure?.call(const MissionClaimFailure(
          kind: MissionClaimFailureKind.unknown,
          message: ErrorMessages.network,
        ));
        return null;
      });

      await pumpMissionScreen(
        tester,
        missionService: missionService,
        userProvider: buildUserProvider(),
      );

      await tester.tap(find.text('받기'));
      await tester.pumpAndSettle();

      expect(
        find.text('보상을 받았는지 확인하지 못했어요. 잠시 후 다시 확인해 주세요.'),
        findsOneWidget,
      );
      expect(find.text(ErrorMessages.network), findsNothing);
    });

    testWidgets('다시 조회해도 안 받은 상태면 그때는 실패로 알린다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((invocation) async {
        final onFailure = invocation.namedArguments[#onFailure] as void
            Function(MissionClaimFailure)?;
        onFailure?.call(const MissionClaimFailure(
          kind: MissionClaimFailureKind.unknown,
          message: ErrorMessages.network,
        ));
        return null;
      });

      await pumpMissionScreen(
        tester,
        missionService: missionService,
        userProvider: buildUserProvider(),
      );

      await tester.tap(find.text('받기'));
      await tester.pumpAndSettle();

      expect(find.text(ErrorMessages.network), findsOneWidget);
      expect(find.text('받기'), findsOneWidget);
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
