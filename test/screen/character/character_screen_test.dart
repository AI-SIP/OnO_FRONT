// 옷장 탭(캐릭터 화면) 위젯 테스트.
//
// 이 화면이 지켜야 하는 약속은 넷이다. 개구리가 주인공 자리에 크게 설 것,
// 능력치가 **스크롤 없이** 전부 보일 것, 미션과 꾸미기는 버튼으로 갈 것,
// 개구리를 누르면 격려 한마디를 할 것.
//
// 스크롤이 없다는 것이 이 화면의 핵심 제약이다. 작은 폰과 글자를 키운
// 기기에서도 개구리 · 능력치 넷 · 총 레벨 · 버튼 둘이 한 화면에 들어와야
// 한다. 아래 `한 화면` 그룹이 그것을 잠근다.
//
// 이 화면에는 끝나지 않는 연출이 있다. `disableAnimationsForTest` 로 꺼
// 두지 않으면 `pumpAndSettle` 이 끝나지 않는다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/Mission/MissionGroupModel.dart';
import 'package:ono/Model/Mission/MissionModel.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Provider/CosmeticProvider.dart';
import 'package:ono/Provider/MissionProvider.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/Character/CharacterScreen.dart';
import 'package:ono/Screen/Character/Widget/AbilityStatPanel.dart';
import 'package:ono/Screen/Cosmetic/CosmeticClosetScreen.dart';
import 'package:ono/Screen/Cosmetic/Widget/CosmeticStage.dart';
import 'package:ono/Screen/Mission/MissionCard.dart';
import 'package:ono/Screen/Mission/MissionScreen.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

MissionModel _mission({
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

  MissionBoardModel board() {
    return MissionBoardModel(
      daily: MissionGroupModel(
        periodKey: '2026-09-11',
        missions: [
          _mission(
            code: 'DAILY_REVIEW_3',
            title: '세 문제만',
            progressId: 1,
            current: 1,
          ),
          _mission(
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
    );
  }

  /// 화면이 읽는 것은 `userInfoModel` 하나뿐이다. 진짜 Provider 는
  /// `fetchUserInfo` 를 거쳐야 값이 차서, 여기서는 값을 바로 들고 있는
  /// 가짜를 쓴다.
  _FakeUserProvider userProvider({UserInfoModel? info}) {
    final provider = _FakeUserProvider();
    when(() => provider.isLoggedIn).thenReturn(LoginStatus.login);
    when(() => provider.userInfoModel).thenReturn(
      info ??
          UserInfoModel(
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
          ),
    );
    when(() => provider.addListener(any())).thenReturn(null);
    when(() => provider.removeListener(any())).thenReturn(null);
    when(() => provider.dispose()).thenReturn(null);
    when(() => provider.fetchUserInfo(
          showErrorSnackBar: any(named: 'showErrorSnackBar'),
        )).thenAnswer((_) async {});
    return provider;
  }

  Future<MissionProvider> pumpCharacter(
    WidgetTester tester, {
    MissionBoardModel? missionBoard,
    UserInfoModel? info,
    Size surfaceSize = OnoSurface.phone,
    double textScale = 1.0,
  }) async {
    disableAnimationsForTest(tester);
    final missionService = MockMissionService();
    when(() => missionService.getMissions())
        .thenAnswer((_) async => missionBoard ?? board());
    final missionProvider = MissionProvider(missionService: missionService);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: const CharacterScreen(),
          ),
        ),
        missionProvider: missionProvider,
        userProvider: userProvider(info: info),
        cosmeticProvider: CosmeticProvider(mockLevel: 12),
        surfaceSize: surfaceSize,
      );
    });

    return missionProvider;
  }

  group('무대', () {
    testWidgets('개구리가 무대 위에 크게 선다', (tester) async {
      await pumpCharacter(tester);

      expect(find.byType(CosmeticStageFrog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CosmeticStageFrog),
          matching: find.byType(FrogCharacter),
        ),
        findsOneWidget,
      );
    });

    testWidgets('개구리를 누르면 격려 말풍선이 뜬다', (tester) async {
      // 꾸미러 가는 문은 이제 버튼이 따로 맡는다. 개구리를 누르는 것은
      // 한마디 듣는 일로 되돌렸다.
      await pumpCharacter(tester);

      final frog = tester.widget<FrogCharacter>(
        find.descendant(
          of: find.byType(CosmeticStageFrog),
          matching: find.byType(FrogCharacter),
        ),
      );
      expect(frog.showEncouragement, isTrue);
    });

    testWidgets('개구리를 눌러도 꾸미기 화면으로 가지 않는다', (tester) async {
      await pumpCharacter(tester);

      await tester.tap(find.byType(FrogCharacter).first);
      // 말풍선은 2초 뒤에 스스로 사라진다. 그 타이머를 여기서 태워 보낸다.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(CosmeticClosetScreen), findsNothing);
      expect(find.byType(CharacterScreen), findsOneWidget);
    });

    testWidgets('총 학습 레벨과 다음 레벨까지의 경험치가 개구리와 함께 보인다', (tester) async {
      await pumpCharacter(tester);

      expect(find.text('Lv.7'), findsOneWidget);
      expect(find.text('24 / 60 XP'), findsOneWidget);
    });

    testWidgets('레벨은 개구리보다 위, 경험치 바는 개구리보다 아래다', (tester) async {
      // 숫자가 개구리 위아래를 감싸야 개구리가 주인공으로 남는다.
      await pumpCharacter(tester);

      final levelY = tester.getTopLeft(find.text('Lv.7')).dy;
      final frogY = tester.getTopLeft(find.byType(CosmeticStageFrog)).dy;
      final expY = tester.getTopLeft(find.text('다음 레벨까지')).dy;

      expect(levelY, lessThan(frogY));
      expect(frogY, lessThan(expY));
    });
  });

  group('스탯창', () {
    testWidgets('능력치 넷의 레벨과 남은 경험치가 한 번에 보인다', (tester) async {
      await pumpCharacter(tester);

      expect(find.byType(AbilityStatPanel), findsOneWidget);

      // 이름 넷. MissionPalette 가 쓰는 이름 그대로다.
      expect(find.text('출석'), findsOneWidget);
      expect(find.text('오답노트'), findsOneWidget);
      expect(find.text('문제 복습'), findsOneWidget);
      expect(find.text('복습 세트'), findsOneWidget);

      // 레벨 넷. 총 학습 레벨(Lv.7)과 겹치지 않는 값으로 잡아 두었다.
      expect(find.text('Lv.3'), findsOneWidget);
      expect(find.text('Lv.5'), findsOneWidget);
      expect(find.text('Lv.2'), findsOneWidget);
      expect(find.text('Lv.1'), findsOneWidget);

      // 다음 레벨까지 남은 경험치. 필요량은 10 + (레벨 - 1) * 10 이다.
      expect(find.text('8 / 30'), findsOneWidget);
      expect(find.text('12 / 50'), findsOneWidget);
      expect(find.text('4 / 20'), findsOneWidget);
      expect(find.text('6 / 10'), findsOneWidget);
    });

    testWidgets('능력치는 경험치 바 아래, 버튼 위에 온다', (tester) async {
      await pumpCharacter(tester);

      final expY = tester.getTopLeft(find.text('다음 레벨까지')).dy;
      final statY = tester.getTopLeft(find.byType(AbilityStatPanel)).dy;
      final buttonY = tester.getTopLeft(find.text('꾸미기')).dy;

      expect(expY, lessThan(statY));
      expect(statY, lessThan(buttonY));
    });

    testWidgets('사용자 정보가 아직 없어도 스탯창 자리는 그대로 있다', (tester) async {
      // 값이 늦게 와서 카드가 나타났다 사라지면 아래 버튼이 들썩인다.
      await pumpCharacter(
        tester,
        info: UserInfoModel(userId: 1, name: '테스터'),
      );

      expect(find.byType(AbilityStatPanel), findsOneWidget);
      expect(find.text('출석'), findsOneWidget);
    });
  });

  group('버튼', () {
    testWidgets('미션 버튼을 누르면 미션 화면으로 간다', (tester) async {
      await pumpCharacter(tester);

      await tester.tap(find.text('미션'));
      await tester.pumpAndSettle();

      expect(find.byType(MissionScreen), findsOneWidget);
    });

    testWidgets('꾸미기 버튼을 누르면 꾸미기 화면으로 간다', (tester) async {
      await pumpCharacter(tester);

      await tester.tap(find.text('꾸미기'));
      await tester.pumpAndSettle();

      expect(find.byType(CosmeticClosetScreen), findsOneWidget);
    });

    testWidgets('오늘 미션을 몇 개 했는지 버튼에 붙는다', (tester) async {
      // 목록을 걷어 냈어도 오늘 할 일이 남았는지는 알 수 있어야 한다.
      await pumpCharacter(tester);

      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('미션 목록은 이 탭에 없다', (tester) async {
      await pumpCharacter(tester);

      expect(find.byType(MissionCard), findsNothing);
      expect(find.text('세 문제만'), findsNothing);
    });

    testWidgets('미션이 없으면 버튼에 숫자가 안 붙는다', (tester) async {
      await pumpCharacter(
        tester,
        missionBoard: const MissionBoardModel(
          daily: MissionGroupModel(periodKey: '2026-09-11', missions: []),
          weekly: MissionGroupModel(periodKey: '2026-W37', missions: []),
        ),
      );

      expect(find.text('미션'), findsOneWidget);
      expect(find.text('0 / 0'), findsNothing);
      // 미션이 없어도 개구리와 능력치는 그대로 있다.
      expect(find.byType(CosmeticStageFrog), findsOneWidget);
      expect(find.byType(AbilityStatPanel), findsOneWidget);
    });
  });

  group('한 화면', () {
    // 이 화면의 존재 이유다. 경험치를 보려고 스크롤을 내리는 일이 없어야 한다.
    for (final surface in <String, Size>{
      '작은 폰': OnoSurface.smallPhone,
      '폰': OnoSurface.phone,
      '태블릿': OnoSurface.tablet,
    }.entries) {
      for (final scale in <String, double>{
        '보통 글자': 1.0,
        '글자 1.6배': 1.6,
      }.entries) {
        testWidgets('${surface.key} · ${scale.value} 에서 스크롤 없이 다 보인다',
            (tester) async {
          await pumpCharacter(
            tester,
            surfaceSize: surface.value,
            textScale: scale.value,
          );

          expect(tester.takeException(), isNull);

          // 스크롤 되는 것이 아예 없어야 한다. 하나라도 있으면 그 안에 숨은
          // 것이 생긴다.
          expect(find.byType(Scrollable), findsNothing);

          final screenHeight =
              tester.getSize(find.byType(CharacterScreen)).height;

          // 개구리 · 능력치 · 버튼이 모두 화면 안에 통째로 들어와 있다.
          for (final finder in <Finder>[
            find.byType(CosmeticStageFrog),
            find.byType(AbilityStatPanel),
            find.text('미션'),
            find.text('꾸미기'),
          ]) {
            final rect = tester.getRect(finder);
            expect(rect.top, greaterThanOrEqualTo(0.0),
                reason: '$finder 가 화면 위로 잘렸다');
            expect(rect.bottom, lessThanOrEqualTo(screenHeight),
                reason: '$finder 가 화면 아래로 잘렸다');
          }

          // 능력치 넷의 레벨과 남은 경험치가 전부 그려져 있다.
          expect(find.text('Lv.3'), findsOneWidget);
          expect(find.text('8 / 30'), findsOneWidget);
          expect(find.text('6 / 10'), findsOneWidget);
        });
      }
    }
  });
}
