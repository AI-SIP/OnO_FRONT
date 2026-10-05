import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';

import '../../helpers/helpers.dart';
import 'problem_detail_fixtures.dart';

/// 태블릿 가로에서 문제 탭을 둘로 나눠 쓰는지 본다.
void main() {
  setUpOnoWidgetTest();

  testWidgets('태블릿 가로에서는 문제 이미지 오른쪽에 다시 풀기를 둔다', (tester) async {
    final problemsProvider = MockProblemsProvider();
    final problem = buildProblem(problemId: 12, reference: '문제 12');
    when(() => problemsProvider.problems).thenReturn([problem]);
    when(() => problemsProvider.getProblem(12))
        .thenAnswer((_) async => problem);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const ProblemDetailScreen(problemId: 12),
        problemsProvider: problemsProvider,
        surfaceSize: const Size(1194, 834),
      );
    });

    final imageTitle = tester.getTopLeft(find.text('문제 이미지').first);
    final solveButton = tester.getTopLeft(find.text('다시 풀기').first);
    expect(solveButton.dx, greaterThan(imageTitle.dx + 300));
  });
}
