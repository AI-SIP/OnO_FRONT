import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Screen/ProblemSolve/ProblemSolveRegisterTemplate.dart';

import '../../helpers/helpers.dart';

/// 복습 기록 화면이 결과와 소요 시간을 미리 채우지 않는지 본다.
///
/// 전에는 정답과 10분이 미리 골라져 있어서, 손대지 않고 저장하면 그대로
/// 기록되고 추천 복습에서 빠지는 정답 수에 들어갔다.
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

  Future<ProblemSolveRegisterTemplateState> pumpTemplate(
    WidgetTester tester, {
    int? initialTimeSpentSeconds,
  }) async {
    final key = GlobalKey<ProblemSolveRegisterTemplateState>();
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: ProblemSolveRegisterTemplate(
          key: key,
          problemId: 1,
          initialTimeSpentSeconds: initialTimeSpentSeconds,
        ),
      ),
      problemsProvider: problemsProvider,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));
    return key.currentState!;
  }

  testWidgets('결과를 고르지 않은 채로 열고, 저장하려 하면 골라 달라고 안내한다', (tester) async {
    final state = await pumpTemplate(tester);

    expect(state.getReviewData()['answerStatus'], isNull);
    expect(find.text('이번 복습 결과를 골라 주세요'), findsNothing);

    expect(state.requireAnswerStatus(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('이번 복습 결과를 골라 주세요'), findsOneWidget);

    await tester.tap(find.text('오답'));
    await tester.pump();

    expect(find.text('이번 복습 결과를 골라 주세요'), findsNothing);
    expect(state.requireAnswerStatus(), isTrue);
    expect(state.getReviewData()['answerStatus'], AnswerStatus.WRONG);
  });

  testWidgets('소요 시간은 비어 있는 채로 열고 시간 없이 저장한다', (tester) async {
    final state = await pumpTemplate(tester);

    expect(find.text('직접 입력'), findsOneWidget);
    expect(state.getReviewData()['timeSpentSeconds'], isNull);
  });

  testWidgets('앱에서 풀기로 잰 시간은 그대로 채워 둔다', (tester) async {
    final state = await pumpTemplate(tester, initialTimeSpentSeconds: 95);

    expect(state.getReviewData()['timeSpentSeconds'], 95);
  });

  testWidgets('다시 쓰기로 비우면 결과와 시간도 다시 비운다', (tester) async {
    final state = await pumpTemplate(tester);
    await tester.tap(find.text('정답'));
    await tester.pump();

    state.resetAll();
    await tester.pump();

    expect(state.getReviewData()['answerStatus'], isNull);
    expect(state.getReviewData()['timeSpentSeconds'], isNull);
  });
}
