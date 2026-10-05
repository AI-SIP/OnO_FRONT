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
      expect(find.byTooltip('이전 문제'), findsOneWidget);
      // 다시 풀기와 같은 줄에 있다.
      expect(
        tester.getCenter(find.byTooltip('다음 문제')).dy,
        moreOrLessEquals(tester.getCenter(find.text('다시 풀기')).dy, epsilon: 1),
      );

      await tester.tap(find.byTooltip('다음 문제'));
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

    expect(find.byTooltip('이전 문제'), findsNothing);
    expect(find.byTooltip('다음 문제'), findsNothing);
  });

  testWidgets('공책에 받지 않은 오답노트가 더 있으면 개수 뒤에 + 를 붙인다', (tester) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const ProblemDetailScreen(
          problemId: 12,
          folderQueue: [11, 12, 13],
          folderQueueHasMore: true,
        ),
        problemsProvider: problemsProvider,
      );

      expect(find.text('2 / 3+'), findsOneWidget);

      await tester.tap(find.byTooltip('다음 문제'));
      await tester.pumpAndSettle();
    });

    expect(find.text('3 / 3+'), findsOneWidget);
  });
}
