import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/User/Widget/CompactActivityLevels.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  Future<void> pumpCompactActivityLevels(
    WidgetTester tester, {
    UserInfoModel? userInfo,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: CompactActivityLevels(
          userInfo: userInfo,
          themeProvider: ThemeHandler(),
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('userInfo 가 null 이면 아무것도 그리지 않는다', (tester) async {
    await pumpCompactActivityLevels(tester, userInfo: null);

    expect(find.text('활동 레벨'), findsNothing);
    expect(find.byType(CompactActivityLevels), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('userInfo 가 있으면 활동 레벨 4개가 모두 보인다', (tester) async {
    final userInfo = UserInfoModel(
      attendanceLevel: 2,
      attendancePoint: 5,
      noteWriteLevel: 4,
      noteWritePoint: 20,
      problemPracticeLevel: 1,
      problemPracticePoint: 0,
      notePracticeLevel: 6,
      notePracticePoint: 30,
    );

    await pumpCompactActivityLevels(tester, userInfo: userInfo);

    expect(find.text('활동 레벨'), findsOneWidget);
    expect(find.text('출석'), findsOneWidget);
    expect(find.text('오답노트 작성'), findsOneWidget);
    expect(find.text('문제 복습'), findsOneWidget);
    expect(find.text('복습 세트 복습'), findsOneWidget);
    expect(find.text('Lv.2'), findsOneWidget);
    // requiredPoint = 10 + (level - 1) * 10 = 10 + (2-1)*10 = 20
    expect(find.text('5/20'), findsOneWidget);
  });

  testWidgets('레벨과 포인트가 매우 커도 예외 없이 그려진다', (tester) async {
    final userInfo = UserInfoModel(
      attendanceLevel: 9999,
      attendancePoint: 999999,
      noteWriteLevel: 9999,
      noteWritePoint: 999999,
      problemPracticeLevel: 9999,
      problemPracticePoint: 999999,
      notePracticeLevel: 9999,
      notePracticePoint: 999999,
    );

    await pumpCompactActivityLevels(tester, userInfo: userInfo);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Lv.9999'), findsWidgets);
  });

  testWidgets('레벨이 0(음수 방향)이어도 예외 없이 그려진다', (tester) async {
    final userInfo = UserInfoModel(
      attendanceLevel: 0,
      attendancePoint: 0,
    );

    await pumpCompactActivityLevels(tester, userInfo: userInfo);

    expect(tester.takeException(), isNull);
    expect(find.text('Lv.0'), findsOneWidget);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    final userInfo = UserInfoModel(attendanceLevel: 2);
    await pumpCompactActivityLevels(
      tester,
      userInfo: userInfo,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
    final userInfo = UserInfoModel(attendanceLevel: 2);
    await pumpCompactActivityLevels(
      tester,
      userInfo: userInfo,
      surfaceSize: OnoSurface.smallPhone,
    );

    expect(tester.takeException(), isNull);
  });
}
