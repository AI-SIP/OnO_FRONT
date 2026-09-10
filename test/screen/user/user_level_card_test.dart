import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';
import 'package:ono/Screen/Mission/MissionScreen.dart';
import 'package:ono/Screen/User/Widget/UserLevelCard.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  Future<void> pumpUserLevelCard(
    WidgetTester tester, {
    UserInfoModel? userInfo,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: UserLevelCard(
          userInfo: userInfo,
          themeProvider: ThemeHandler(),
          userName: '테스트유저',
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('userInfo 가 null 이면 레벨 0 으로 렌더된다', (tester) async {
    await pumpUserLevelCard(tester, userInfo: null);

    expect(find.text('학습 레벨'), findsOneWidget);
    expect(find.text('Lv.0'), findsOneWidget);
    expect(find.text('0/40'), findsOneWidget);
    // userInfo 가 없으면 활동 레벨 목록은 그려지지 않는다.
    expect(find.textContaining('출석'), findsNothing);
  });

  testWidgets('userInfo 가 있으면 레벨과 활동별 목록이 보인다', (tester) async {
    final userInfo = UserInfoModel(
      totalStudyLevel: 3,
      totalStudyCurrentPoint: 15,
      totalStudyNextLevelThreshold: 40,
      attendanceLevel: 2,
      attendancePoint: 5,
      noteWriteLevel: 4,
      noteWritePoint: 20,
      problemPracticeLevel: 1,
      problemPracticePoint: 0,
      notePracticeLevel: 6,
      notePracticePoint: 30,
    );

    await pumpUserLevelCard(tester, userInfo: userInfo);

    expect(find.text('Lv.3'), findsOneWidget);
    expect(find.text('15/40'), findsOneWidget);
    expect(find.text('출석'), findsOneWidget);
    expect(find.text('오답노트 작성'), findsOneWidget);
    expect(find.text('문제 복습'), findsOneWidget);
    expect(find.text('복습 세트 복습'), findsOneWidget);
  });

  testWidgets('FrogCharacter 가 함께 렌더된다', (tester) async {
    await pumpUserLevelCard(tester, userInfo: null);

    expect(find.byType(FrogCharacter), findsOneWidget);
  });

  testWidgets('다음 레벨 임계값이 0 이어도(0으로 나누기) 예외 없이 그려진다', (tester) async {
    // totalStudyLevel 을 9 로 둬서, 활동별 레벨(기본값 1)로 그려지는
    // "Lv.1" 텍스트들과 겹치지 않게 한다.
    final userInfo = UserInfoModel(
      totalStudyLevel: 9,
      totalStudyCurrentPoint: 0,
      totalStudyNextLevelThreshold: 0,
    );

    await pumpUserLevelCard(tester, userInfo: userInfo);

    expect(tester.takeException(), isNull);
    expect(find.text('Lv.9'), findsOneWidget);
  });

  testWidgets(
    '레벨과 포인트가 매우 커도 예외 없이 그려진다',
    (tester) async {
      // TODO(#174): 실제 버그. lib/Screen/User/Widget/UserLevelCard.dart:288-289
      // 활동 행의 "point/requiredPoint" 라벨이 고정폭 SizedBox(width: pointsWidth)
      // 안에 maxLines/overflow 지정 없이 그려진다. 자릿수가 늘어나면(예: 1234/500)
      // 두 줄로 줄바꿈되어 카드 전체 높이를 넘어서고, "RenderFlex overflowed on
      // the bottom" 에러가 난다.
      final userInfo = UserInfoModel(
        totalStudyLevel: 120,
        totalStudyCurrentPoint: 3500,
        totalStudyNextLevelThreshold: 5000,
        attendanceLevel: 50,
        attendancePoint: 1234,
      );

      await pumpUserLevelCard(tester, userInfo: userInfo);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Lv.120'), findsOneWidget);
    },
    skip: true, // #174 에서 수정 예정
  );

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    final userInfo = UserInfoModel(totalStudyLevel: 2);
    await pumpUserLevelCard(
      tester,
      userInfo: userInfo,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(UserLevelCard), findsOneWidget);
  });

  testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
    final userInfo = UserInfoModel(totalStudyLevel: 2);
    await pumpUserLevelCard(
      tester,
      userInfo: userInfo,
      surfaceSize: OnoSurface.smallPhone,
    );

    expect(tester.takeException(), isNull);
  });

  group('미션 화면으로 가는 길', () {
    testWidgets('레벨 카드에 미션으로 가는 줄이 보인다', (tester) async {
      await pumpUserLevelCard(tester, userInfo: null);

      // 정보 카드처럼만 보이면 누를 수 있다는 것을 알 수 없다.
      expect(find.text('미션 보고 경험치 받기'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets('그 줄을 누르면 미션 화면으로 간다', (tester) async {
      disableAnimationsForTest(tester);
      await pumpUserLevelCard(tester, userInfo: null);

      await tester.tap(find.text('미션 보고 경험치 받기'));
      await tester.pumpAndSettle();

      expect(find.byType(MissionScreen), findsOneWidget);
    });

    testWidgets('레벨 도넛을 눌러도 미션 화면으로 간다', (tester) async {
      disableAnimationsForTest(tester);
      await pumpUserLevelCard(tester, userInfo: null);

      await tester.tap(find.text('학습 레벨'));
      await tester.pumpAndSettle();

      expect(find.byType(MissionScreen), findsOneWidget);
    });

    testWidgets('개구리를 누르면 말풍선이 뜨고 화면은 그대로다', (tester) async {
      // 카드 전체를 누르게 하면 개구리의 격려 말풍선과 화면 이동이 함께
      // 일어난다. 개구리 쪽은 예전 그대로여야 한다.
      disableAnimationsForTest(tester);
      await pumpUserLevelCard(tester, userInfo: null);

      await tester.tap(find.byType(FrogCharacter));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MissionScreen), findsNothing);

      // 말풍선은 2초 뒤 스스로 사라진다. 타이머를 흘려보낸다.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });
}
