import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeCompletionScreen.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';

import '../../helpers/helpers.dart';
import 'problem_detail_fixtures.dart';

/// 복습 세트에서 연 오답노트도 공책처럼 이전, 다음을 다시 풀기 버튼 줄에 둔다.
/// 마지막 문제에서는 다음 자리에 복습 마치기가 온다.
PracticeNoteDetailModel _practice({List<int> problemIds = const []}) {
  return PracticeNoteDetailModel(
    practiceId: 1,
    practiceTitle: '세트',
    practiceCount: 2,
    createdAt: DateTime(2024, 1, 1),
    lastSolvedAt: null,
    problemIdList: [...problemIds],
  );
}

void main() {
  setUpOnoWidgetTest();

  late MockProblemsProvider problemsProvider;
  late ProblemPracticeProvider practiceProvider;

  setUp(() {
    problemsProvider = MockProblemsProvider();
    final problems = {
      for (final id in [10, 20, 30])
        id: buildProblem(problemId: id, reference: '문제 $id'),
    };
    when(() => problemsProvider.problems).thenReturn(problems.values.toList());
    for (final entry in problems.entries) {
      when(() => problemsProvider.getProblem(entry.key))
          .thenAnswer((_) async => entry.value);
    }
    final service = MockPracticeNoteService();
    when(() => service.getPracticeNoteById(1, showErrorSnackBar: true))
        .thenAnswer((_) async => _practice(problemIds: [10, 20, 30]));
    practiceProvider = ProblemPracticeProvider(
      problemsProvider: problemsProvider,
      practiceNoteService: service,
    );
  });

  Future<void> start(List<int> ids) async {
    await practiceProvider.fetchPracticeNote(1);
    practiceProvider.currentProblems = [
      for (final id in ids) buildProblem(problemId: id, reference: '문제 $id'),
    ];
    practiceProvider.currentPracticeNote = _practice(problemIds: ids);
    practiceProvider.startSession();
  }

  Future<void> pump(WidgetTester tester, int problemId) {
    return withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        ProblemDetailScreen(problemId: problemId, isPractice: true),
        problemsProvider: problemsProvider,
        practiceProvider: practiceProvider,
      );
    });
  }

  testWidgets('가운데 문제에서는 다시 풀기 줄에 이전, 다음과 몇 번째인지가 보인다', (tester) async {
    await start([10, 20, 30]);
    await pump(tester, 20);

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.byTooltip('이전 문제'), findsOneWidget);
    expect(find.byTooltip('다음 문제'), findsOneWidget);
    expect(
      tester.getCenter(find.byTooltip('다음 문제')).dy,
      moreOrLessEquals(tester.getCenter(find.text('다시 풀기')).dy, epsilon: 1),
    );
    expect(find.text('복습 마치기'), findsNothing);
  });

  testWidgets('마지막 문제에서는 다음 대신 복습 마치기가 보이고 누르면 완료 화면으로 간다', (tester) async {
    await start([10, 20]);
    practiceProvider.recordSessionResult(10, AnswerStatus.CORRECT);
    await pump(tester, 20);

    expect(find.byTooltip('다음 문제'), findsNothing);
    await tester.tap(find.text('복습 마치기'));
    await tester.pumpAndSettle();

    expect(find.byType(PracticeCompletionScreen), findsOneWidget);
  });

  testWidgets('하나도 저장하지 않고 마치려 하면 한 번 묻는다', (tester) async {
    await start([10, 20]);
    await pump(tester, 20);

    await tester.tap(find.text('복습 마치기'));
    await tester.pumpAndSettle();
    expect(find.text('아직 저장한 복습이 없어요'), findsOneWidget);

    await tester.tap(find.text('더 풀기'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeCompletionScreen), findsNothing);

    await tester.tap(find.text('복습 마치기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마치기'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeCompletionScreen), findsOneWidget);
  });

  testWidgets('태블릿 가로에서도 푼 날짜 다음에 문제 이미지가 온다', (tester) async {
    await start([10, 20]);
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const ProblemDetailScreen(problemId: 10, isPractice: true),
        problemsProvider: problemsProvider,
        practiceProvider: practiceProvider,
        surfaceSize: const Size(1366, 1024),
      );
    });

    expect(tester.takeException(), isNull);
    final dateY = tester.getCenter(find.text('푼 날짜')).dy;
    final imageY = tester.getCenter(find.text('문제 이미지').first).dy;
    expect(imageY, greaterThan(dateY));
  });
}
