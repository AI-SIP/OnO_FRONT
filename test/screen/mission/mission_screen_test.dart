// MissionScreen 위젯 테스트.
//
// 세 상태(받을 수 있음 / 진행 중 / 받음)의 무게가 다르게 그려지는지, 받은 뒤
// 연출과 레벨업 화면이 뜨는지가 관찰 대상이다.
//
// 이 화면에는 끝나지 않는 연출이 있다(받을 수 있는 카드의 펄스, 개구리의
// 들썩임). `disableAnimationsForTest` 로 접근성 설정을 흉내 내서 끄지 않으면
// `pumpAndSettle` 이 끝나지 않는다. 연출을 끈 상태에서도 화면의 구조와 동작은
// 그대로여야 한다는 것을 같이 확인하는 셈이다.
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
import 'package:ono/Module/Design/AppColors.dart';
import 'package:ono/Module/Motion/AnimatedGauge.dart';
import 'package:ono/Module/Motion/AppearTransition.dart';
import 'package:ono/Model/Mission/MissionHistoryModel.dart';
import 'package:ono/Screen/Cosmetic/CosmeticClosetScreen.dart';
import 'package:ono/Screen/Mission/MissionCard.dart';
import 'package:ono/Screen/Mission/MissionHistoryScreen.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/Mission/MissionIcon.dart';
import 'package:ono/Screen/Mission/MissionPalette.dart';
import 'package:ono/Screen/Mission/MissionSegments.dart';
import 'package:ono/Screen/Mission/MissionHeroCard.dart';
import 'package:ono/Screen/Mission/MissionRewardCelebration.dart';
import 'package:ono/Screen/Mission/MissionRewardChip.dart';
import 'package:ono/Screen/Mission/MissionLevelUp.dart';
import 'package:ono/Screen/Mission/MissionScreen.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';

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

/// 보상 카드가 스스로 닫히고 코인이 도착할 때까지 흘려 보낸다.
///
/// 받기를 누르면 레벨업 여부와 상관없이 보상 카드가 먼저 뜬다. 그 카드는
/// 1.1초 뒤 스스로 닫히므로 시간을 넘겨 줘야 다음 상태가 된다.
Future<void> settleReward(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

/// 히어로의 "오늘 받은 XP" 카운터가 지금 보여 주는 글자.
String _heroXpText(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byType(MissionHeroCard),
    // 코인 그림 안에도 'XP' 글자가 있어서 합계 쪽(+가 붙은 것)만 고른다.
    matching: find.textContaining('+'),
  );
  return (tester.widgetList<Text>(finder).first).data ?? '';
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
    disableAnimationsForTest(tester);
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

  group('세 상태의 무게', () {
    testWidgets('받을 수 있는 것에만 버튼이 있다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());

      await pumpMissionScreen(tester, missionService: missionService);

      // 받을 수 있는 미션 하나에만 버튼이 붙는다.
      expect(find.text('받기'), findsOneWidget);
      // 진행 중에는 버튼을 두지 않는다. 지금 할 수 있는 것이 없는데 버튼이
      // 있으면 눌러 보게 되고, 눌리지 않으면 고장으로 읽힌다.
      expect(find.text('진행 중'), findsNothing);
      expect(find.text('세 문제만'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      // 받은 것은 도장만 남는다.
      expect(find.text('받음'), findsOneWidget);
    });

    testWidgets('받을 수 있는 것이 맨 위, 받은 것이 맨 아래다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());

      await pumpMissionScreen(tester, missionService: missionService);

      final claimable = tester.getTopLeft(find.text('오늘의 오답')).dy;
      final inProgress = tester.getTopLeft(find.text('세 문제만')).dy;
      // 능력치 라벨도 '출석' 이라 제목 쪽(먼저 그려지는 것)만 본다.
      final claimed = tester.getTopLeft(find.text('출석').first).dy;

      expect(claimable, lessThan(inProgress));
      expect(inProgress, lessThan(claimed));
    });

    testWidgets('progressId 가 없으면 완료여도 받기 버튼이 없다', (tester) async {
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

      expect(find.text('오늘 기분'), findsOneWidget);
      expect(find.text('받기'), findsNothing);
    });

    testWidgets('일일과 주간을 세그먼트로 고른다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer(
        (_) async => MissionBoardModel(
          daily: MissionGroupModel(
            periodKey: '2026-09-09',
            missions: [
              buildMission(
                code: 'DAILY_NOTE_WRITE',
                title: '오늘의 오답',
                progressId: 1,
              ),
            ],
          ),
          weekly: MissionGroupModel(
            periodKey: '2026-W37',
            missions: [
              buildMission(
                code: 'WEEKLY_NOTE_10',
                title: '열 권의 노트',
                progressId: 9,
              ),
            ],
          ),
        ),
      );

      await pumpMissionScreen(tester, missionService: missionService);

      expect(find.text('일일'), findsOneWidget);
      expect(find.text('주간'), findsOneWidget);

      await tester.tap(find.text('주간'));
      await tester.pumpAndSettle();

      // 한 번에 한 탭만 그린다. 주간으로 옮기면 주간 것만 트리에 있다.
      expect(find.text('열 권의 노트'), findsOneWidget);
    });
  });

  group('탭 전환', () {
    MissionBoardModel twoTabBoard() {
      return MissionBoardModel(
        daily: MissionGroupModel(
          periodKey: '2026-09-09',
          missions: [
            buildMission(
              code: 'DAILY_NOTE_WRITE',
              title: '오늘의 오답',
              progressId: 1,
              current: 1,
              target: 3,
            ),
          ],
        ),
        weekly: MissionGroupModel(
          periodKey: '2026-W37',
          missions: [
            buildMission(
              code: 'WEEKLY_NOTE_10',
              title: '열 권의 노트',
              progressId: 9,
              current: 2,
              target: 10,
            ),
          ],
        ),
      );
    }

    Future<MissionProvider> pumpTwoTabs(WidgetTester tester) {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => twoTabBoard());
      return pumpMissionScreen(tester, missionService: missionService);
    }

    testWidgets('한 번에 한 탭의 내용만 트리에 있다', (tester) async {
      // 두 탭을 함께 들고 있으면(IndexedStack) 전환할 때 숨은 쪽까지 같이
      // 흐려져서 양쪽이 깜빡이는 것처럼 보였다.
      await pumpTwoTabs(tester);

      expect(find.text('오늘의 오답'), findsOneWidget);
      expect(find.text('열 권의 노트'), findsNothing);

      await tester.tap(find.text('주간'));
      await tester.pumpAndSettle();

      expect(find.text('열 권의 노트'), findsOneWidget);
      expect(find.text('오늘의 오답'), findsNothing);
    });

    testWidgets('전환하는 자리 뒤에 불투명한 배경이 깔려 있다', (tester) async {
      // 뒤가 비어 있으면 바뀌는 사이에 검정 캔버스가 그대로 비친다.
      await pumpTwoTabs(tester);

      final background = tester.widgetList<ColoredBox>(
        find.ancestor(
          of: find.byType(MissionCard).first,
          matching: find.byType(ColoredBox),
        ),
      );

      expect(
        background.any((box) => box.color == AppColors.background),
        isTrue,
        reason: '전환 영역 뒤가 비어 있으면 검정이 보인다',
      );
    });

    testWidgets('전환 도중에도 목록이 계속 그려진다', (tester) async {
      await pumpTwoTabs(tester);

      await tester.tap(find.text('주간'));
      // 전환이 끝나기 전 프레임. 둘 중 하나는 반드시 화면에 있어야 한다.
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.byType(MissionCard), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('탭을 바꿔도 선택된 세그먼트가 흰 알약과 테마색을 유지한다', (tester) async {
      // 두 번 놓친 자리다. 칸 두 개가 각자 흰 배경을 켜고 끄면 그 사이에
      // 양쪽이 회색으로 보인다. 흰 알약은 하나뿐이고 좌우로 미끄러져야 한다.
      await pumpTwoTabs(tester);

      Color labelColor(String text) {
        return tester.widget<Text>(find.text(text)).style!.color!;
      }

      final theme = ThemeHandler().primaryColor;
      expect(labelColor('일일'), theme);
      expect(find.byKey(MissionSegments.pillKey), findsOneWidget);

      await tester.tap(find.text('주간'));

      // 전환 도중에도 알약은 사라지지 않는다.
      for (final step in [1, 60, 120, 200]) {
        await tester.pump(Duration(milliseconds: step));
        expect(
          find.byKey(MissionSegments.pillKey),
          findsOneWidget,
          reason: '$step ms 에 선택된 알약이 사라졌다',
        );
      }

      await tester.pumpAndSettle();
      expect(labelColor('주간'), theme);
    });

    testWidgets('탭을 바꿔도 세그먼트가 새로 만들어지지 않는다', (tester) async {
      // 다시 만들어지면 등장 연출과 알약 위치가 처음부터 시작해 깜빡인다.
      await pumpTwoTabs(tester);

      final before = tester.element(find.byType(MissionSegments));

      await tester.tap(find.text('주간'));
      await tester.pumpAndSettle();

      expect(identical(before, tester.element(find.byType(MissionSegments))),
          isTrue);
    });

    testWidgets('세그먼트는 등장 연출로 감싸지 않는다', (tester) async {
      await pumpTwoTabs(tester);

      expect(
        find.ancestor(
          of: find.byType(MissionSegments),
          matching: find.byType(AppearTransition),
        ),
        findsNothing,
        reason: '감싸면 그 안쪽이 다시 만들어질 때 알약이 잠깐 사라진다',
      );
    });

    testWidgets('등장 연출은 처음 한 번만 돈다', (tester) async {
      // 탭을 옮길 때마다 줄이 하나씩 다시 올라오면 그건 연출이 아니라
      // 깜빡임이다.
      await pumpTwoTabs(tester);

      // 목록 줄을 감싼 것만 본다. 히어로와 세그먼트는 탭을 옮겨도 다시
      // 만들어지지 않으므로 다시 재생될 일이 없다.
      List<AppearTransition> listAppearances() {
        return tester
            .widgetList<AppearTransition>(
              find.ancestor(
                of: find.byType(MissionCard),
                matching: find.byType(AppearTransition),
              ),
            )
            .toList();
      }

      expect(
        listAppearances().every((widget) => widget.enabled),
        isTrue,
        reason: '처음 들어올 때는 하나씩 올라와야 한다',
      );

      await tester.tap(find.text('주간'));
      await tester.pumpAndSettle();

      final afterSwitch = listAppearances();
      expect(afterSwitch, isNotEmpty);
      expect(
        afterSwitch.every((widget) => !widget.enabled),
        isTrue,
        reason: '탭을 옮긴 뒤에는 등장 연출이 다시 돌면 안 된다',
      );
    });
  });

  group('카드의 무게가 색으로 갈린다', () {
    /// 카드 바탕을 칠한 Container 의 색.
    Color cardColor(WidgetTester tester, String title) {
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text(title),
              matching: find.byType(Container),
            )
            .last,
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    testWidgets('받을 수 있는 카드만 테마색을 옅게 깔고 떠오른다', (tester) async {
      // 받을 수 있는 것이 흰 카드면 목록에서 눈에 띄지 않는다. 예전에는 금색을
      // 썼는데 앱 어디에도 없는 색이라 겉돌았다.
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());

      await pumpMissionScreen(tester, missionService: missionService);

      expect(
        cardColor(tester, '오늘의 오답'),
        MissionPalette.claimableSurface(ThemeHandler().primaryColor),
      );
      expect(cardColor(tester, '세 문제만'), Colors.white);
      expect(cardColor(tester, '출석'), Colors.white);
    });

    testWidgets('아이콘 색이 오르는 능력치를 따른다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());

      await pumpMissionScreen(tester, missionService: missionService);

      final icons = tester.widgetList<MissionIcon>(find.byType(MissionIcon));
      final colors = icons.map((icon) => icon.color.toARGB32()).toSet();

      expect(
        colors.length,
        greaterThan(1),
        reason: '전부 같은 색이면 목록이 밋밋하고 색이 뜻을 잃는다',
      );

      // 색이 뜻하는 능력치를 말로도 알린다.
      expect(find.text('오답노트'), findsWidgets);
      expect(find.text('문제 복습'), findsWidgets);
    });
  });

  group('지난 미션', () {
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

    MissionModel expiredMission() => buildMission(
          code: 'WEEKLY_REVIEW_30',
          title: '서른 번의 복습',
          progressId: 777,
          current: 30,
          target: 30,
          completed: true,
          periodKey: '2026-W36',
        );

    testWidgets('지난 미션이 없으면 배너가 없다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithExpired());

      await pumpMissionScreen(tester, missionService: missionService);

      expect(find.textContaining('받지 않은 보상'), findsNothing);
      expect(find.text('오늘의 오답'), findsOneWidget);
    });

    testWidgets('지난 미션이 있으면 접힌 배너 한 줄로 알린다', (tester) async {
      // 목록에 펼쳐 놓으면 같은 제목이 한 탭에 두 번 나오고, 지난주 주간
      // 미션이 일일 탭에 앉는다. 한 줄로 접어 탭 밖으로 꺼낸다.
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer(
          (_) async => boardWithExpired(expired: [expiredMission()]));

      await pumpMissionScreen(tester, missionService: missionService);

      expect(find.text('받지 않은 보상 1개'), findsOneWidget);
      // 접혀 있으니 목록에는 없다.
      expect(find.text('서른 번의 복습'), findsNothing);
    });

    testWidgets('배너를 누르면 시트에서 지난 미션을 보여 준다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer(
          (_) async => boardWithExpired(expired: [expiredMission()]));

      await pumpMissionScreen(tester, missionService: missionService);

      await tester.tap(find.text('받지 않은 보상 1개'));
      await tester.pumpAndSettle();

      expect(find.text('지난 미션'), findsOneWidget);
      expect(find.text('서른 번의 복습'), findsOneWidget);
      // 서버 키를 그대로 보여 주지 않는다.
      expect(find.text('2026-W36'), findsNothing);
      expect(find.text('지난주'), findsOneWidget);
    });

    testWidgets('시트에서 지난 미션을 받을 수 있다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer(
          (_) async => boardWithExpired(expired: [expiredMission()]));
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

      await tester.tap(find.text('받지 않은 보상 1개'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('받기').last);
      await tester.pumpAndSettle();

      verify(() =>
              missionService.claim(777, onFailure: any(named: 'onFailure')))
          .called(1);
    });
  });

  group('히어로', () {
    testWidgets('개구리를 누르면 옷장으로 간다', (tester) async {
      // 마이페이지와 같은 약속이다. 이 앱에서 개구리를 누르면 늘 꾸미러 가는
      // 문이 열린다.
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());

      await pumpMissionScreen(tester, missionService: missionService);

      await tester.tap(
        find.descendant(
          of: find.byType(MissionHeroCard),
          matching: find.byType(FrogCharacter),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CosmeticClosetScreen), findsOneWidget);
    });

    testWidgets('종합 레벨과 경험치 바는 두지 않는다', (tester) async {
      // 미션 화면에 레벨 게이지까지 두니 복잡해졌다. 레벨은 마이페이지에서 본다.
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());

      await pumpMissionScreen(tester, missionService: missionService);

      final hero = find.byType(MissionHeroCard);
      expect(hero, findsOneWidget);
      expect(
        find.descendant(of: hero, matching: find.textContaining('Lv.')),
        findsNothing,
      );
      // 오늘 진행도와 오늘 받은 XP 는 그대로 있다.
      expect(find.text('받을 보상이 있어요'), findsOneWidget);
      expect(_heroXpText(tester), '+10 XP');
    });

    testWidgets('링 게이지와 오른쪽 글상자가 확실히 떨어져 있다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());

      await pumpMissionScreen(tester, missionService: missionService);

      final ring = find.descendant(
        of: find.byType(MissionHeroCard),
        matching: find.byType(AnimatedCircularGauge),
      );
      final headline = find.descendant(
        of: find.byType(MissionHeroCard),
        matching: find.text('받을 보상이 있어요'),
      );

      final gap =
          tester.getTopLeft(headline).dx - tester.getBottomRight(ring).dx;
      expect(
        gap,
        greaterThanOrEqualTo(28),
        reason: '좁으면 링과 글상자가 한 덩어리로 읽힌다',
      );
    });

    // 검증에서 320dp 는 기본 배율에서도, 390dp 는 배율 1.15 부터 넘쳤다.
    // 가장 흔한 폭에서 글자 한 칸만 키워도 노란 줄무늬가 보이던 자리다.
    for (final size in [OnoSurface.smallPhone, OnoSurface.phone]) {
      for (final scale in [1.0, 1.15, 1.3, 1.6, 2.0]) {
        testWidgets(
          '${size.width.toInt()}dp 글자 ${scale}배에서 넘치지 않는다',
          (tester) async {
            final missionService = MockMissionService();
            when(() => missionService.getMissions())
                .thenAnswer((_) async => boardWithThreeStates());

            disableAnimationsForTest(tester);
            await pumpOnoWidget(
              tester,
              Builder(
                builder: (context) => MediaQuery(
                  // 통째로 갈아 끼우면 연출을 끈 설정까지 지워진다.
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: const MissionScreen(),
                ),
              ),
              missionProvider: MissionProvider(missionService: missionService),
              surfaceSize: size,
            );

            expect(
              tester.takeException(),
              isNull,
              reason: '${size.width.toInt()}dp × $scale 에서 넘쳤다',
            );
            // "안 넘쳤다"와 "그릴 게 없었다"는 다르다. 실제로 떠 있는지 본다.
            expect(find.byType(MissionHeroCard), findsOneWidget);
            expect(find.byType(MissionSegments), findsOneWidget);
            expect(find.byType(MissionCard), findsWidgets);
            expect(find.text('받기'), findsOneWidget);
          },
        );
      }
    }

    testWidgets('좁은 화면에서 글자를 키워도 넘치지 않는다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());

      disableAnimationsForTest(tester);
      final missionProvider = MissionProvider(missionService: missionService);
      await pumpOnoWidget(
        tester,
        // 통째로 갈아 끼우면 연출을 끈 설정까지 지워져서 펄스가 다시 돈다.
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: const MissionScreen(),
          ),
        ),
        missionProvider: missionProvider,
        surfaceSize: OnoSurface.smallPhone,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(MissionHeroCard), findsOneWidget);
      expect(find.byType(MissionCard), findsWidgets);
    });
  });

  group('받은 보상 기록', () {
    testWidgets('오늘 XP 칩을 누르면 기록 화면으로 간다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());
      when(() => missionService.getHistory(cursor: any(named: 'cursor')))
          .thenAnswer((_) async => MissionHistoryPageModel.empty);

      await pumpMissionScreen(tester, missionService: missionService);

      await tester.tap(find.text('+10 XP').first);
      await tester.pumpAndSettle();

      expect(find.byType(MissionHistoryScreen), findsOneWidget);
      expect(find.text('지금까지 받은 보상'), findsOneWidget);
    });
  });

  group('조회 실패', () {
    testWidgets('404 가 떨어져도 오류 없이 조용한 안내만 남는다', (tester) async {
      final missionService = MockMissionService();
      when(() => missionService.getMissions()).thenAnswer((_) async => null);

      await pumpMissionScreen(tester, missionService: missionService);

      expect(find.text('아직 미션이 없어요'), findsWidgets);
      expect(find.text('받기'), findsNothing);
    });
  });

  group('보상 받기', () {
    testWidgets('받으면 카드가 받음으로 바뀌고 오늘 XP 가 올라간다', (tester) async {
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

      // 받기 전에는 오늘 받은 것이 하나(출석 10 XP)뿐이다.
      expect(_heroXpText(tester), '+10 XP');

      await tester.tap(find.text('받기'));
      await tester.pumpAndSettle();

      // 레벨업이 없어도 보상 카드는 반드시 뜬다. 카드가 조용히 받음으로
      // 바뀌기만 하면 그건 보상이 아니라 알림이다.
      expect(find.byKey(missionRewardCelebrationKey), findsOneWidget);
      expect(find.text('오늘의 오답'), findsWidgets);

      await settleReward(tester);

      // 알림을 띄우지 않는다. 카드가 받음으로 바뀌고 카운터가 오르는 것으로
      // 끝난다. 예전에는 여기서 내려오던 토스트가 일일/주간 탭을 덮었다.
      expect(find.byKey(missionRewardCelebrationKey), findsNothing);
      expect(find.text('받기'), findsNothing);
      expect(find.text('받음'), findsNWidgets(2));
      expect(_heroXpText(tester), '+20 XP');
      verify(() => missionService.claim(2, onFailure: any(named: 'onFailure')))
          .called(1);
    });

    testWidgets('leveledUp 이면 화면 전체를 쓰는 레벨업 연출이 뜬다', (tester) async {
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
      await settleReward(tester);

      // 제목을 따로 두지 않는다. Lv.6 → Lv.7 이 그 말을 이미 한다.
      expect(find.text('Lv.6'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text(missionLevelPhraseOf(7)), findsOneWidget);

      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle();
      expect(find.text(missionLevelPhraseOf(7)), findsNothing);
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
      await settleReward(tester);

      // 실패라고 알리지 않는다. 다시 조회해서 받은 것을 확인했다.
      expect(find.text(ErrorMessages.network), findsNothing);
      expect(find.text('받음'), findsNWidgets(2));
      expect(_heroXpText(tester), '+20 XP');
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
        find.text('보상을 받았는지 확인하지 못했어요'),
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

    testWidgets('보상 카드가 떠 있을 때 뒤로가기를 눌러도 미션 화면은 남는다', (tester) async {
      // 자동 닫기 타이머가 살아남아 pop 을 한 번 더 부르면 그 두 번째 pop 이
      // 미션 화면을 닫아 홈으로 튕긴다. 실제로 재현됐던 자리다.
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
      await tester.pump();

      // 자동 닫기(1.1초) 직전까지 흘린 뒤 밖에서 닫는다(시스템 뒤로가기).
      // 닫히는 애니메이션이 도는 동안에도 위젯은 아직 살아 있어서, 그 사이에
      // 타이머가 터지면 pop 이 한 번 더 나간다. 그 두 번째 pop 이 미션 화면을
      // 닫는다.
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byKey(missionRewardCelebrationKey), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.byKey(missionRewardCelebrationKey), findsNothing);

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(
        find.byType(MissionScreen),
        findsOneWidget,
        reason: '보상 카드만 닫혀야 한다. 미션 화면까지 닫히면 홈으로 튕긴다',
      );
    });

    testWidgets('바깥을 눌러 닫아도 미션 화면은 남는다', (tester) async {
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

      // 카드 밖(맨 위)을 누른다.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(find.byType(MissionScreen), findsOneWidget);
    });

    testWidgets('실패하면 코인을 날리지 않고 카드가 흔들린다', (tester) async {
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

      // 보상 카드는 뜨지 않는다. 받은 것이 없으니 축하할 것도 없다.
      expect(find.byKey(missionRewardCelebrationKey), findsNothing);

      final shaken = tester
          .widgetList<MissionCard>(find.byType(MissionCard))
          .where((card) => card.mission.progressId == 2);
      expect(shaken.single.shakeTick, greaterThan(0));
    });

    testWidgets('연출을 켠 채로 받으면 코인이 날아가고 그 뒤에 숫자가 오른다', (tester) async {
      // 다른 화면 테스트는 전부 동작 줄이기를 켜 두어서 코인 비행과 정산
      // 경로가 한 번도 돌지 않았다. 여기서만 연출을 켜고 그 길을 태운다.
      // 끝나지 않는 펄스가 있어서 pumpAndSettle 을 쓰지 않고 직접 흘려보낸다.
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

      await pumpOnoWidget(
        tester,
        const MissionScreen(),
        missionProvider: MissionProvider(missionService: missionService),
        userProvider: buildUserProvider(),
        settle: false,
      );
      // 숫자가 0 에서 올라오는 연출이 끝날 때까지 기다린다.
      await tester.pump(const Duration(milliseconds: 900));

      // 받기 전에는 출석 10 XP 뿐이다.
      expect(_heroXpText(tester), '+10 XP');

      await tester.tap(find.text('받기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 보상 카드가 떠 있는 동안에는 아직 숫자가 오르지 않는다. 코인이
      // 공중에 있는데 숫자가 먼저 오르면 코인이 무엇을 옮기는지 사라진다.
      expect(find.byKey(missionRewardCelebrationKey), findsOneWidget);
      expect(_heroXpText(tester), '+10 XP');

      // 카드가 스스로 닫히고 코인이 날아간다.
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byType(MissionRewardToken),
        findsWidgets,
        reason: '코인이 화면에 떠서 날아가야 한다',
      );
      expect(
        _heroXpText(tester),
        '+10 XP',
        reason: '코인이 닿기 전에는 숫자가 오르지 않는다',
      );

      // 코인이 닿으면 그때 숫자가 오른다. 롤업이 끝날 때까지 흘려보낸다.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 300));

      expect(_heroXpText(tester), '+20 XP');
      expect(find.text('받기'), findsNothing);
    });

    testWidgets('연달아 두 번 눌러도 요청은 한 번만 나간다', (tester) async {
      // 보상이 두 번 나가면 되돌릴 방법이 없다. 화면 쪽 가드와 프로바이더 쪽
      // 가드가 겹쳐 막는다.
      final missionService = MockMissionService();
      when(() => missionService.getMissions())
          .thenAnswer((_) async => boardWithThreeStates());
      when(() => missionService.claim(
            any(),
            onFailure: any(named: 'onFailure'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
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

      // 버튼은 누른 뒤 글자가 사라지므로 자리를 잡아 두고 그 자리를 두 번 누른다.
      final spot = tester.getCenter(find.text('받기'));
      await tester.tapAt(spot);
      await tester.pump();
      await tester.tapAt(spot);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(spot);
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => missionService.claim(2, onFailure: any(named: 'onFailure')))
          .called(1);

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
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
