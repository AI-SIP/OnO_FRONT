import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemDetail/Widget/RepeatSectionV2.dart';

import '../../helpers/helpers.dart';
import 'problem_detail_fixtures.dart';

/// RepeatSectionV2 는 상태(_RepeatSectionV2State) 안에서
/// `ProblemSolveService()` 를 직접 만든다 (생성자 주입 불가). 그래서 위젯
/// 테스트에서는 mock 으로 성공 응답을 흘려보낼 방법이 없다.
///
/// 게다가 flutter_test 환경(TestWidgetsFlutterBinding)은 dart:io
/// HttpClient 로 나가는 모든 요청을 즉시 가짜 400 응답으로 가로챈다. 그
/// 결과 "로딩 중" 프레임은 거의 관찰할 수 없을 만큼 짧고(단정하면 flaky),
/// 항상 곧바로 에러 상태로 귀결된다.
///
/// 즉 이 위젯은 "에러" 상태만 이 테스트로 안정적으로 볼 수 있고, "복습
/// 기록이 있을 때" 정상 목록·태블릿 마스터-디테일·펼치기/삭제 같은
/// 상호작용은 현재 구조로는 위젯 테스트로 검증할 수 없다. (README 요구사항
/// 중 "복습 기록이 있을 때" 케이스를 못 채우는 이유. 최종 보고에 함께
/// 남긴다.)
void main() {
  setUpOnoWidgetTest();

  testWidgets('네트워크 요청이 실패하면 에러 문구를 보여준다', (tester) async {
    final problem = buildProblem();

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: RepeatSectionV2(
          problem: problem,
          iconColor: Colors.pink,
          isWide: false,
        ),
      ),
      settle: false,
    );

    for (var i = 0;
        i < 50 && find.text('복습 기록을 불러올 수 없습니다.').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('복습 기록을 불러올 수 없습니다.'), findsOneWidget);
  });

  testWidgets('buildRepeatSectionV2 헬퍼로 띄워도 예외 없이 그려진다', (tester) async {
    final problem = buildProblem();

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: buildRepeatSectionV2(context, problem, Colors.pink, false),
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    final problem = buildProblem();

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: RepeatSectionV2(
          problem: problem,
          iconColor: Colors.pink,
          isWide: true,
        ),
      ),
      surfaceSize: OnoSurface.tablet,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets('refreshSignal 이 바뀌어도 예외 없이 다시 요청한다', (tester) async {
    final problem = buildProblem();

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: RepeatSectionV2(
          problem: problem,
          iconColor: Colors.pink,
          isWide: false,
          refreshSignal: 0,
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: RepeatSectionV2(
          problem: problem,
          iconColor: Colors.pink,
          isWide: false,
          refreshSignal: 1,
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });
}
