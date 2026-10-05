import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Tag/TagModel.dart';
import 'package:ono/Screen/PracticeNote/PracticeContinueSheet.dart';
import 'package:ono/Screen/ProblemSolve/ProblemSolveEntry.dart';

import '../../helpers/helpers.dart';

/// 시트를 띄우는 버튼 하나만 있는 화면. 누르면 시트 결과를 [onResult] 로 넘긴다.
Future<void> _pumpLauncher(
  WidgetTester tester, {
  required ProblemModel? next,
  required void Function(PracticeContinueChoice) onResult,
  ProblemSolveMode mode = ProblemSolveMode.inApp,
}) async {
  await pumpOnoWidget(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => onResult(await showPracticeContinueSheet(
              context,
              solvedPosition: next == null ? 5 : 3,
              total: 5,
              next: next,
              mode: mode,
              accentColor: Colors.green,
            )),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

ProblemModel _next() => ProblemModel(
      problemId: 2,
      reference: '2026 9월 모평 27번',
      tags: const [TagModel(tagId: 1, name: '확률')],
    );

void main() {
  setUpOnoWidgetTest();

  testWidgets('다음 문제가 있으면 몇 번째까지 풀었는지와 다음 문제 제목을 보여 준다', (tester) async {
    await withMockedNetworkImages(() async {
      await _pumpLauncher(tester, next: _next(), onResult: (_) {});

      expect(find.text('3 / 5 복습 끝!'), findsOneWidget);
      expect(find.text('2026 9월 모평 27번'), findsOneWidget);
    });
  });

  for (final entry in {
    '다음 문제 바로 풀기': PracticeContinueChoice.solveNext,
    '문제 먼저 볼게요': PracticeContinueChoice.viewNext,
    '그만할게요': PracticeContinueChoice.stop,
  }.entries) {
    testWidgets('「${entry.key}」를 누르면 ${entry.value.name}', (tester) async {
      await withMockedNetworkImages(() async {
        PracticeContinueChoice? result;
        await _pumpLauncher(tester,
            next: _next(), onResult: (choice) => result = choice);

        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();

        expect(result, entry.value);
      });
    });
  }

  testWidgets('마지막 문제면 복습을 마칠지 묻는다', (tester) async {
    PracticeContinueChoice? result;
    await _pumpLauncher(tester,
        next: null, onResult: (choice) => result = choice);

    expect(find.text('마지막 문제까지 풀었어요'), findsOneWidget);
    expect(find.text('복습 세트를 마칠까요?'), findsOneWidget);
    expect(find.text('이번 회차를 마쳐요.'), findsOneWidget);
    expect(find.text('다음 문제 바로 풀기'), findsNothing);

    await tester.tap(find.text('복습 마치기'));
    await tester.pumpAndSettle();
    expect(result, PracticeContinueChoice.finish);
  });

  testWidgets('시트를 그냥 닫으면 그만하기로 본다', (tester) async {
    await withMockedNetworkImages(() async {
      PracticeContinueChoice? result;
      await _pumpLauncher(tester,
          next: _next(), onResult: (choice) => result = choice);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(result, PracticeContinueChoice.stop);
    });
  });

  testWidgets('추천 복습에서는 마지막 문제에서 목록으로 돌아갈지 묻는다', (tester) async {
    PracticeContinueChoice? result;
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async => result = await showPracticeContinueSheet(
                context,
                solvedPosition: 3,
                total: 3,
                next: null,
                mode: ProblemSolveMode.inApp,
                accentColor: Colors.green,
                finishQuestion: '추천 복습 목록으로 돌아갈까요?',
                finishLabel: '목록으로 돌아가기',
                finishDescription: '남은 추천 문제를 확인해요.',
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(find.text('추천 복습 목록으로 돌아갈까요?'), findsOneWidget);
    expect(find.text('복습 세트를 마칠까요?'), findsNothing);

    await tester.tap(find.text('목록으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(result, PracticeContinueChoice.finish);
  });
}
