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
import 'package:ono/Model/Cosmetic/CosmeticAbilityLevels.dart';
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
    CosmeticProvider? cosmetic,
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
        cosmeticProvider: cosmetic ??
            CosmeticProvider(mockLevels: CosmeticAbilityLevels.uniform(12)),
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

      expect(find.text('총 학습'), findsOneWidget);
      expect(find.text('Lv.7'), findsOneWidget);
      expect(find.text('24 / 60'), findsOneWidget);
    });

    testWidgets('진행도 수치에 꼬리표를 따로 붙이지 않는다', (tester) async {
      // 총 학습만 `24 / 60 XP` 이고 능력치 넷은 `8 / 30` 이면 같은 뜻의 숫자
      // 둘이 다른 종류로 읽힌다. 다섯 다 `현재 / 필요` 한 가지 모양만 쓴다.
      await pumpCharacter(tester);

      expect(find.text('24 / 60 XP'), findsNothing);
    });

    testWidgets('이름표 · 레벨 · 진행도가 개구리 위 한 줄에 같이 앉는다', (tester) async {
      // 예전에는 레벨이 개구리 머리 위, 경험치 바가 발치에 있어서 둘을 같이
      // 보려면 눈이 화면 위아래를 왔다 갔다 해야 했다. 한 가지를 말하는 값
      // 둘이라 나란히 둔다.
      await pumpCharacter(tester);

      final labelY = tester.getTopLeft(find.text('총 학습')).dy;
      final levelY = tester.getTopLeft(find.text('Lv.7')).dy;
      final meterY = tester.getTopLeft(find.text('24 / 60')).dy;
      final frogY = tester.getTopLeft(find.byType(CosmeticStageFrog)).dy;

      for (final y in [labelY, levelY, meterY]) {
        expect(y, lessThan(frogY));
      }
      // 셋이 같은 줄이다. 위아래로 갈라져 있으면 안 된다.
      expect((labelY - levelY).abs(), lessThan(24));
      expect((levelY - meterY).abs(), lessThan(24));
    });

    testWidgets('이름표는 레벨 앞, 진행도는 뒤에 온다', (tester) async {
      // 성장 영역 다섯 덩어리가 모두 `이름표 → 값 → 진행도` 순서다. 하나만
      // 순서가 다르면 그것이 제일 먼저 눈에 띈다. 가로로 누운 총 학습 줄에서
      // 그 순서는 왼쪽에서 오른쪽이다.
      await pumpCharacter(tester);

      final labelX = tester.getTopLeft(find.text('총 학습')).dx;
      final levelX = tester.getTopLeft(find.text('Lv.7')).dx;
      final meterX = tester.getTopLeft(find.text('24 / 60')).dx;

      expect(labelX, lessThan(levelX));
      expect(levelX, lessThan(meterX));
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

    testWidgets('눈금판도 이름표가 레벨 위, 진행도가 아래다', (tester) async {
      // 무대의 총 학습 줄과 같은 순서다. 자리가 세로로 길어서 왼쪽·오른쪽이
      // 위·아래가 됐을 뿐이다. 다섯 중 하나만 이름표가 값 아래에 붙어 있으면
      // 그것이 제일 먼저 눈에 띈다.
      await pumpCharacter(tester);

      final labelY = tester.getTopLeft(find.text('출석')).dy;
      final levelY = tester.getTopLeft(find.text('Lv.3')).dy;
      final meterY = tester.getTopLeft(find.text('8 / 30')).dy;

      expect(labelY, lessThan(levelY));
      expect(levelY, lessThan(meterY));
    });

    testWidgets('능력치 넷의 이름표가 같은 크기로 앉는다', (tester) async {
      // 칸마다 따로 줄이면 `출석` 은 그대로인데 `문제 복습` 만 작아진다.
      // 넷이 같은 틀이어야 한다는 규칙이 거기서 깨진다. 글자가 잘리기 쉬운
      // 작은 폰에 글자를 키운 경우로 본다.
      await pumpCharacter(
        tester,
        surfaceSize: OnoSurface.smallPhone,
        textScale: 1.6,
      );

      // getRect 는 FittedBox 가 건 확대·축소까지 반영한 화면 위 크기다.
      final heights = <double>{
        for (final name in ['출석', '오답노트', '문제 복습', '복습 세트'])
          double.parse(
              tester.getRect(find.text(name)).height.toStringAsFixed(1)),
      };
      expect(heights, hasLength(1), reason: '넷의 글자 높이가 갈렸다: $heights');
    });

    testWidgets('능력치는 무대 아래, 버튼 위에 온다', (tester) async {
      await pumpCharacter(tester);

      final frogY = tester.getTopLeft(find.byType(CosmeticStageFrog)).dy;
      final statY = tester.getTopLeft(find.byType(AbilityStatPanel)).dy;
      final buttonY = tester.getTopLeft(find.text('꾸미기')).dy;

      expect(frogY, lessThan(statY));
      expect(statY, lessThan(buttonY));
    });

    testWidgets('능력치 아이콘은 마이페이지가 쓰던 그 아이콘이다', (tester) async {
      // 한때 미션 카드의 이모지를 빌려 썼는데, 이모지는 크게 그려야 읽히고
      // 이 자리는 15px 라서 뭉갰다. 넷 다 예전 레벨 카드의 아이콘으로 돌린다.
      await pumpCharacter(tester);

      for (final icon in [
        Icons.waving_hand_rounded,
        Icons.edit_note,
        Icons.chrome_reader_mode_outlined,
        Icons.history,
      ]) {
        expect(
          find.descendant(
            of: find.byType(AbilityStatPanel),
            matching: find.byIcon(icon),
          ),
          findsOneWidget,
          reason: '$icon',
        );
      }
    });

    testWidgets('능력치를 누르면 올리는 법이 뜬다', (tester) async {
      // 눈금판은 지금 어디에 서 있는지만 말해 준다. 무엇을 해야 저 고리가
      // 차는지는 여기서 알려 준다.
      await pumpCharacter(tester);

      await tester.tap(find.byIcon(Icons.waving_hand_rounded));
      await tester.pumpAndSettle();

      expect(find.text('출석 올리는 법'), findsOneWidget);
      expect(find.text('하루에 한 번 앱을 열면'), findsOneWidget);
      expect(find.text('+15점'), findsOneWidget);
      expect(find.text('하루 한 번까지'), findsOneWidget);
    });

    testWidgets('능력치마다 다른 규칙을 말한다', (tester) async {
      await pumpCharacter(tester);

      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      expect(find.text('오답노트 올리는 법'), findsOneWidget);
      // 서버의 MissionType 과 MissionLogService 가 정한 값이다.
      expect(find.text('+10점'), findsOneWidget);
      expect(find.text('하루 세 개까지'), findsOneWidget);
    });

    testWidgets('꾸미기 화면에서 더미 레벨을 옮기면 눈금판도 따라간다', (tester) async {
      // 두 화면이 같은 능력치를 다른 레벨로 말하면 어느 쪽이 진짜인지 알 수 없다.
      final cosmetic =
          CosmeticProvider(mockLevels: CosmeticAbilityLevels.uniform(12));
      cosmetic.setMockLevel(CosmeticAbility.attendance, 9);

      await pumpCharacter(tester, cosmetic: cosmetic);

      // 서버가 준 출석은 Lv.3 이지만 더미를 만진 뒤로는 더미를 따른다.
      expect(find.text('Lv.9'), findsOneWidget);
      expect(find.text('Lv.3'), findsNothing);
    });

    testWidgets('더미 레벨을 한 번도 안 옮겼으면 서버가 준 레벨을 그린다', (tester) async {
      await pumpCharacter(tester);

      expect(find.text('Lv.3'), findsOneWidget);
      expect(find.text('Lv.12'), findsNothing);
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
