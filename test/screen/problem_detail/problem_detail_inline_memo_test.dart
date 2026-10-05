// 오답노트 상세 정답 탭에서 메모를 바로 쓰는 흐름.
//
// 전에는 메모가 비어 있으면 칸이 아예 없어서, 메모를 쓰려면 ⋮ → 수정 →
// 전체 수정 화면까지 가야 했다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Problem/ProblemRegisterModel.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';

import '../../helpers/helpers.dart';
import 'problem_detail_fixtures.dart';

void main() {
  setUpOnoWidgetTest();

  late MockProblemsProvider problemsProvider;

  setUpAll(() {
    registerFallbackValue(ProblemRegisterModel());
  });

  Future<void> openAnswerTab(WidgetTester tester, ProblemModel problem) async {
    problemsProvider = MockProblemsProvider();
    when(() => problemsProvider.problems).thenReturn([problem]);
    when(() => problemsProvider.getProblem(problem.problemId))
        .thenAnswer((_) async => problem);
    when(() => problemsProvider.updateProblem(any())).thenAnswer((_) async {});

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        ProblemDetailScreen(problemId: problem.problemId),
        problemsProvider: problemsProvider,
      );
      await tester.tap(find.text('정답'));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('메모가 없으면 메모 추가를 보이고, 쓰고 저장하면 메모만 보낸다', (tester) async {
    await openAnswerTab(tester, buildProblem(problemId: 11, memo: null));

    await tester.scrollUntilVisible(find.text('메모 추가'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('메모 추가'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  부호를 놓쳤다  ');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final sent = verify(() => problemsProvider.updateProblem(captureAny()))
        .captured
        .single as ProblemRegisterModel;
    expect(sent.problemId, 11);
    expect(sent.memo, '부호를 놓쳤다');
    expect(sent.tagIds, isNull, reason: '태그를 보내면 서버가 태그를 다시 맞춘다');
    expect(sent.folderId, isNull);
  });

  testWidgets('그대로면 저장할 수 없고, 비우고 저장하면 메모를 지운다', (tester) async {
    when(() => problemsProvider.updateProblem(any())).thenAnswer((_) async {});
    await openAnswerTab(tester, buildProblem(problemId: 11, memo: '원래 메모'));

    await tester.scrollUntilVisible(find.byTooltip('메모 고치기'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byTooltip('메모 고치기'));
    await tester.pumpAndSettle();

    ElevatedButton saveButton() => tester.widget<ElevatedButton>(find.ancestor(
        of: find.text('저장'), matching: find.byType(ElevatedButton)));

    expect(saveButton().onPressed, isNull, reason: '바뀐 것이 없다');

    // 서버는 빈 메모를 받으면 메모를 지운다.
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(saveButton().onPressed, isNotNull);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final sent = verify(() => problemsProvider.updateProblem(captureAny()))
        .captured
        .single as ProblemRegisterModel;
    expect(sent.memo, '');
  });
}
