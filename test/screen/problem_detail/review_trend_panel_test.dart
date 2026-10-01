import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Model/Problem/ImprovementType.dart';
import 'package:ono/Model/Problem/ProblemSolveModel.dart';
import 'package:ono/Model/Problem/ProblemSolveTrend.dart';
import 'package:ono/Screen/ProblemDetail/Widget/ReviewTrendPanel.dart';

import '../../helpers/helpers.dart';

const _c = AnswerStatus.CORRECT;
const _w = AnswerStatus.WRONG;
const _p = AnswerStatus.PARTIAL;

/// 9월 1일부터 사흘 간격으로 기록을 만든다. [seconds] 를 안 넘기면 줄어드는 시간을 넣는다.
List<ProblemSolveModel> buildSolves(List<AnswerStatus> statuses,
    {List<int?>? seconds}) {
  return [
    for (var i = 0; i < statuses.length; i++)
      ProblemSolveModel(
        problemSolveId: i + 1,
        problemId: 1,
        userId: 1,
        practicedAt: DateTime(2026, 9, 1).add(Duration(days: i * 3, hours: 20)),
        answerStatus: statuses[i],
        improvements:
            i == 0 ? const [] : const [ImprovementType.NO_REPEAT_MISTAKE],
        timeSpentSeconds: seconds != null ? seconds[i] : 900 - i * 40,
        reflection: '$i회차 메모',
        migratedFromLegacy: false,
        imageUrls: const [],
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      ),
  ];
}

Future<void> _pumpPanel(
  WidgetTester tester,
  List<ProblemSolveModel> solves, {
  bool isWide = false,
  void Function(int)? onRoundTap,
}) async {
  await pumpOnoWidget(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 30),
        child: ReviewTrendPanel(
          trend: ProblemSolveTrend.from(solves, now: DateTime(2026, 10, 1)),
          accentColor: Colors.pink.shade200,
          isWide: isWide,
          onRoundTap: onRoundTap ?? (_) {},
        ),
      ),
    ),
    surfaceSize: isWide ? const Size(1194, 834) : OnoSurface.phone,
  );
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('기록이 하나면 요약과 안내만 보이고 접기 버튼이 없다', (tester) async {
    await _pumpPanel(tester, buildSolves([_w]));

    expect(find.text('1번 복습했어요'), findsOneWidget);
    expect(find.text('한 번 더 복습하면 흐름을 보여 드릴게요'), findsOneWidget);
    expect(find.text('풀이 시간'), findsNothing);
  });

  testWidgets('기록이 여러 개면 복습 흐름과 풀이 시간 카드를 그린다', (tester) async {
    await _pumpPanel(tester, buildSolves([_w, _p, _c, _c, _c]));

    expect(find.text('5번 중 3번 맞혔어요'), findsOneWidget);
    // 동그라미가 폭에 들어가면 화살표가 없다.
    expect(find.bySemanticsLabel('이전 회차 보기'), findsNothing);
    // 회차마다 몇 분 걸렸는지 막대 위에 적는다. (900초에서 40초씩 준다)
    expect(find.text('15분'), findsOneWidget);
    expect(find.text('12분 20초'), findsOneWidget);
    expect(find.text('3연속 정답'), findsOneWidget);
    expect(find.text('복습 흐름'), findsOneWidget);
    expect(find.text('풀이 시간'), findsOneWidget);
    // 개선된 점 카드는 두지 않는다.
    expect(find.text('개선된 점'), findsNothing);
    // 기록이 10개가 안 되면 처음과 최근 비교는 없다.
    expect(find.text('처음 5번'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시간은 줄이지 않고 한 줄로 적는다 (초만, 분만, 분과 초)', (tester) async {
    await _pumpPanel(
      tester,
      buildSolves([_w, _c, _c], seconds: [45, 150, 180]),
    );

    expect(find.text('45초'), findsOneWidget);
    expect(find.text('2분 30초'), findsOneWidget);
    expect(find.text('3분'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('풀이 시간이 모두 같으면 풀이 시간 블록을 숨긴다', (tester) async {
    await _pumpPanel(
      tester,
      buildSolves([_w, _c, _c], seconds: [600, 600, 600]),
    );

    expect(find.text('풀이 시간'), findsNothing);
    expect(find.text('복습 흐름'), findsOneWidget);
  });

  testWidgets('기록이 14개면 복습 흐름을 넘겨 보고 풀이 시간은 최근 10번만 그린다', (tester) async {
    await _pumpPanel(
      tester,
      buildSolves([_w, _w, _p, _w, _p, _c, _p, _c, _c, _w, _c, _c, _c, _c]),
    );

    expect(find.text('처음 5번'), findsOneWidget);
    expect(find.text('4연속 정답'), findsOneWidget);
    // 풀이 시간 막대는 5회부터 14회까지 열 개다.
    expect(find.text('최근 10회'), findsOneWidget);
    expect(find.text('5회'), findsOneWidget);
    expect(find.text('4회'), findsNothing);
    // 처음 열면 최근 회차(10/10)가 보이고 1회차(9/1)는 넘겨야 보인다.
    expect(find.text('10/10').hitTestable(), findsOneWidget);
    expect(find.text('9/1').hitTestable(), findsNothing);
    // 넘칠 때는 더 넘길 수 있는 왼쪽에만 화살표가 있다.
    expect(find.bySemanticsLabel('이전 회차 보기'), findsOneWidget);
    expect(find.bySemanticsLabel('최근 회차 보기'), findsNothing);

    await tester.tap(find.bySemanticsLabel('이전 회차 보기'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('최근 회차 보기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('동그라미를 누르면 그 회차 번호를 넘긴다', (tester) async {
    int? tapped;
    await _pumpPanel(
      tester,
      buildSolves([_w, _p, _c]),
      onRoundTap: (round) => tapped = round,
    );

    await tester.tap(find.bySemanticsLabel(RegExp(r'^2회차 부분 정답')));
    await tester.pump();

    expect(tapped, 2);
  });

  testWidgets('태블릿 폭에서도 넘침 없이 그린다', (tester) async {
    await _pumpPanel(
      tester,
      buildSolves([_w, _w, _p, _w, _p, _c, _p, _c, _c, _w, _c, _c, _c, _c]),
      isWide: true,
    );

    expect(find.text('복습 흐름'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
