// 캐릭터 탭 위젯 테스트.
//
// 이 화면이 지켜야 하는 약속은 셋이다. 개구리가 화면의 주인공 자리에 크게
// 서 있을 것, 개구리를 누르면 옷장으로 갈 것, 미션 카드가 미션 화면과 같은
// 것을 쓸 것. 무대가 붙박이라 세로가 빡빡하므로 작은 폰과 태블릿에서 넘치지
// 않는지도 같이 잠근다.
//
// 이 화면에는 끝나지 않는 연출이 있다(받을 수 있는 카드의 펄스).
// `disableAnimationsForTest` 로 꺼 두지 않으면 `pumpAndSettle` 이 끝나지 않는다.
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

  MissionBoardModel _board() {
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
  _FakeUserProvider _userProvider({UserInfoModel? info}) {
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
    MissionBoardModel? board,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    disableAnimationsForTest(tester);
    final missionService = MockMissionService();
    when(() => missionService.getMissions())
        .thenAnswer((_) async => board ?? _board());
    final missionProvider = MissionProvider(missionService: missionService);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const CharacterScreen(),
        missionProvider: missionProvider,
        userProvider: _userProvider(),
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

    testWidgets('개구리를 누르면 옷장으로 간다', (tester) async {
      await pumpCharacter(tester);

      await tester.tap(find.byType(FrogCharacter).first);
      await tester.pumpAndSettle();

      expect(find.byType(CosmeticClosetScreen), findsOneWidget);
    });

    testWidgets('여기 개구리는 격려 말풍선을 띄우지 않는다', (tester) async {
      // 누름 하나가 한 가지 일만 해야 한다. 말풍선은 옷장 무대에서만 뜬다.
      await pumpCharacter(tester);

      final frog = tester.widget<FrogCharacter>(
        find.descendant(
          of: find.byType(CosmeticStageFrog),
          matching: find.byType(FrogCharacter),
        ),
      );
      expect(frog.showEncouragement, isFalse);
    });

    testWidgets('꾸미기 버튼도 옷장으로 간다', (tester) async {
      await pumpCharacter(tester);

      await tester.tap(find.text('꾸미기'));
      await tester.pumpAndSettle();

      expect(find.byType(CosmeticClosetScreen), findsOneWidget);
    });

    testWidgets('레벨과 다음 레벨까지의 경험치가 개구리와 함께 보인다', (tester) async {
      await pumpCharacter(tester);

      expect(find.text('Lv.7'), findsOneWidget);
      expect(find.text('24 / 60 XP'), findsOneWidget);
    });

    testWidgets('레벨은 개구리보다 위, 경험치 바는 개구리보다 아래다', (tester) async {
      // 숫자가 개구리 위아래를 감싸야 개구리가 주인공으로 남는다. 숫자를 한쪽에
      // 몰아 두면 그 덩어리가 화면의 주인공이 된다.
      await pumpCharacter(tester);

      final levelY = tester.getTopLeft(find.text('Lv.7')).dy;
      final frogY = tester.getTopLeft(find.byType(CosmeticStageFrog)).dy;
      final expY = tester.getTopLeft(find.text('다음 레벨까지')).dy;

      expect(levelY, lessThan(frogY));
      expect(frogY, lessThan(expY));
    });
  });

  group('오늘의 미션', () {
    testWidgets('미션 화면과 같은 카드를 쓴다', (tester) async {
      await pumpCharacter(tester);

      expect(find.byType(MissionCard), findsNWidgets(2));
      expect(find.text('세 문제만'), findsOneWidget);
      expect(find.text('오늘의 오답'), findsOneWidget);
      // 받을 수 있는 것에만 버튼이 붙는 것도 카드 쪽 규칙 그대로다.
      expect(find.text('받기'), findsOneWidget);
    });

    testWidgets('받을 수 있는 것이 진행 중인 것보다 위에 온다', (tester) async {
      await pumpCharacter(tester);

      final claimable = tester.getTopLeft(find.text('오늘의 오답')).dy;
      final inProgress = tester.getTopLeft(find.text('세 문제만')).dy;
      expect(claimable, lessThan(inProgress));
    });

    testWidgets('오늘 몇 개를 했는지 머리말에 적는다', (tester) async {
      await pumpCharacter(tester);

      expect(find.text('오늘의 미션'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('전체 보기를 누르면 미션 화면으로 간다', (tester) async {
      // 주간과 지난 미션은 여기 쌓지 않는다. 더 볼 사람만 넘어간다.
      await pumpCharacter(tester);

      await tester.tap(find.text('전체 보기'));
      await tester.pumpAndSettle();

      expect(find.byType(MissionScreen), findsOneWidget);
    });

    testWidgets('미션이 없으면 조용한 안내만 남는다', (tester) async {
      // 백엔드에 아직 이 API 가 없어 빈 응답이 오는 동안에도 오류를 띄우지
      // 않는다.
      await pumpCharacter(
        tester,
        board: const MissionBoardModel(
          daily: MissionGroupModel(periodKey: '2026-09-11', missions: []),
          weekly: MissionGroupModel(periodKey: '2026-W37', missions: []),
        ),
      );

      expect(find.text('아직 미션이 없어요'), findsOneWidget);
      expect(find.byType(MissionCard), findsNothing);
      // 미션이 없어도 개구리는 그대로 서 있다.
      expect(find.byType(CosmeticStageFrog), findsOneWidget);
    });
  });

  group('활동별 성장', () {
    testWidgets('무엇으로 레벨이 올랐는지가 미션 아래에 붙는다', (tester) async {
      // 마이페이지 레벨 카드에 있던 네 줄이다. 레벨이 이 탭으로 온 이상
      // 그 경험치가 어디서 오는지도 같은 화면에 있어야 한다.
      await pumpCharacter(tester);

      Finder inPanel(String text) => find.descendant(
            of: find.byType(AbilityStatPanel),
            matching: find.text(text),
          );

      expect(find.byType(AbilityStatPanel), findsOneWidget);
      expect(inPanel('출석'), findsOneWidget);
      expect(inPanel('오답노트'), findsOneWidget);
      expect(inPanel('문제 복습'), findsOneWidget);
      expect(inPanel('복습 세트'), findsOneWidget);

      final missionY = tester.getTopLeft(find.byType(MissionCard).first).dy;
      final growthY = tester.getTopLeft(find.byType(AbilityStatPanel)).dy;
      expect(missionY, lessThan(growthY));
    });
  });

  group('크기', () {
    for (final entry in <String, Size>{
      '작은 폰': OnoSurface.smallPhone,
      '폰': OnoSurface.phone,
      '태블릿': OnoSurface.tablet,
    }.entries) {
      testWidgets('${entry.key} 에서 넘치지 않는다', (tester) async {
        await pumpCharacter(tester, surfaceSize: entry.value);

        expect(tester.takeException(), isNull);
        expect(find.byType(CharacterScreen), findsOneWidget);
        // 무대가 붙박이라도 미션 카드가 첫 화면에서 사라지면 안 된다.
        expect(find.byType(MissionCard), findsWidgets);
      });
    }
  });
}
