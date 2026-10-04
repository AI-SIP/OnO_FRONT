import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';

import '../../helpers/helpers.dart';
import 'problem_detail_fixtures.dart';

/// 공책에서 연 오답노트는 아래의 이전, 다음으로 같은 공책의 다른 문제로 넘긴다.
void main() {
  setUpOnoWidgetTest();

  late MockProblemsProvider problemsProvider;

  setUp(() {
    problemsProvider = MockProblemsProvider();
    final problems = {
      for (final id in [11, 12, 13])
        id: buildProblem(problemId: id, reference: '문제 $id'),
    };
    when(() => problemsProvider.problems).thenReturn(problems.values.toList());
    for (final entry in problems.entries) {
      when(() => problemsProvider.getProblem(entry.key))
          .thenAnswer((_) async => entry.value);
    }
  });

  testWidgets('가운데 문제에서는 몇 번째인지와 이전, 다음이 보이고 다음으로 넘어간다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const ProblemDetailScreen(problemId: 12, folderQueue: [11, 12, 13]),
        problemsProvider: problemsProvider,
      );

      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('이전'), findsOneWidget);

      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    });

    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('공책 순서를 받지 않으면 이전, 다음을 그리지 않는다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const ProblemDetailScreen(problemId: 12),
        problemsProvider: problemsProvider,
      );
    });

    expect(find.text('이전'), findsNothing);
    expect(find.text('다음'), findsNothing);
  });
}
