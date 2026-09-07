import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreenWidget.dart';

import '../../helpers/helpers.dart';
import 'problem_detail_fixtures.dart';

/// ProblemDetailScreenWidget 은 지금 어떤 화면에서도 참조되지 않는 죽은
/// 코드다 (ProblemDetailTemplate 가 대체). 그래도 "전부" 요구사항에 맞춰
/// builder 메서드들을 검증한다.
void main() {
  setUpOnoWidgetTest();

  late ThemeHandler theme;
  late ProblemDetailScreenWidget screenWidget;

  setUp(() {
    theme = ThemeHandler();
    screenWidget = ProblemDetailScreenWidget();
  });

  testWidgets('buildBackground 는 예외 없이 격자 배경을 그린다', (tester) async {
    await pumpOnoWidget(
      tester,
      Scaffold(body: screenWidget.buildBackground(theme)),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('buildCommonDetailView 는 날짜와 이미지 섹션을 보여준다', (tester) async {
    final problem = buildProblem(solvedAt: DateTime(2026, 5, 1));

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: screenWidget.buildCommonDetailView(context, problem, theme),
          ),
        ),
      );
    });

    expect(find.text('2026년 5월 1일'), findsOneWidget);
    expect(find.text('문제 이미지가 없습니다.'), findsOneWidget);
  });

  testWidgets('buildExpansionTile 은 펼치면 정답 관련 섹션을 보여준다', (tester) async {
    final problem = buildProblem(memo: '메모 내용');
    final controller = ExpansionTileController();

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: screenWidget.buildExpansionTile(
              context,
              problem,
              theme,
              controller,
              true, // 이미 펼쳐진 상태로 시작
              (_) {},
            ),
          ),
        ),
      );
    });

    expect(find.text('정답 확인'), findsOneWidget);
    expect(find.text('메모 내용'), findsOneWidget);
  });

  testWidgets('buildExpansionTile 은 접힌 상태에서는 정답 내용을 숨긴다', (tester) async {
    final problem = buildProblem(memo: '메모 내용');
    final controller = ExpansionTileController();

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: screenWidget.buildExpansionTile(
              context,
              problem,
              theme,
              controller,
              false,
              (_) {},
            ),
          ),
        ),
      );
    });

    expect(find.text('정답 확인'), findsOneWidget);
    expect(find.text('메모 내용'), findsNothing);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    final problem = buildProblem();

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: screenWidget.buildCommonDetailView(context, problem, theme),
          ),
        ),
        surfaceSize: OnoSurface.tablet,
      );
    });

    expect(tester.takeException(), isNull);
  });
}
