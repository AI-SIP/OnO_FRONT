import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Screen/ProblemSolve/ProblemSolveRegisterTemplate.dart';

import '../../helpers/helpers.dart';

/// 복습 기록 작성 화면이 실제로 스크롤되는지 본다.
///
/// 이 화면은 위에서부터 결과·소요 시간·풀이 이미지·개선점·기분·메모가 차례로
/// 있어서 한 화면에 다 들어가지 않는다. 스크롤이 막히면 아래쪽 항목을 아예
/// 쓸 수 없다.
void main() {
  setUpOnoWidgetTest();

  late MockProblemService problemService;
  late ProblemsProvider problemsProvider;

  setUp(() {
    problemService = MockProblemService();
    when(() => problemService.getProblem(any())).thenAnswer(
      (_) async => ProblemModel(problemId: 1),
    );
    problemsProvider = ProblemsProvider(problemService: problemService);
  });

  Future<ScrollableState> pumpTemplate(WidgetTester tester) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Column(
          children: [
            Expanded(
              child: ProblemSolveRegisterTemplate(problemId: 1),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      problemsProvider: problemsProvider,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));
    return tester.state<ScrollableState>(find.byType(Scrollable).first);
  }

  testWidgets('위로 끌면 화면이 스크롤된다', (tester) async {
    final scrollable = await pumpTemplate(tester);
    expect(scrollable.position.pixels, 0);

    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -300));
    await tester.pump();

    expect(
      scrollable.position.pixels,
      greaterThan(0),
      reason: '스크롤이 막히면 개선점·기분·메모 항목을 아예 쓸 수 없다',
    );
  });

  testWidgets('아래쪽 기분 선택 항목까지 스크롤해서 닿을 수 있다', (tester) async {
    await pumpTemplate(tester);

    await tester.scrollUntilVisible(
      find.text('이번 복습 어땠나요?'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await tester.pump();

    expect(find.text('이번 복습 어땠나요?'), findsOneWidget);
  });

  testWidgets('좁은 폰에서 소요 시간 조절 칩이 가로로 넘치지 않는다', (tester) async {
    // -1분 +1분 -10초 +10초 넷을 Spacer 뒤에 한 줄로 두면 320dp 폭에서
    // 오른쪽으로 넘쳤다. 넘치면 아랫줄로 내려가야 한다.
    await pumpOnoWidget(
      tester,
      Scaffold(body: ProblemSolveRegisterTemplate(problemId: 1)),
      problemsProvider: problemsProvider,
      surfaceSize: OnoSurface.smallPhone,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('-10초'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('글자를 키워도 소요 시간 줄이 넘치지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: Scaffold(body: ProblemSolveRegisterTemplate(problemId: 1)),
        ),
      ),
      problemsProvider: problemsProvider,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });
}
