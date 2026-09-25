// PracticeDetailLoader 위젯 테스트.
//
// 목록에서 세트를 누르면 화면부터 넘기고 이 로더 안에서 불러온다. 불러오는
// 동안 사용자가 나가서 다른 세트를 열 수 있는데, 그때 늦게 끝난 쪽이 공용
// 상태를 덮으면 화면에 떠 있는 세트에 다른 세트의 문제가 들어간다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Module/Motion/Skeleton.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeDetailLoader.dart';

import '../../helpers/helpers.dart';

PracticeNoteDetailModel _practice({
  required int practiceId,
  List<int> problemIdList = const [],
}) {
  return PracticeNoteDetailModel(
    practiceId: practiceId,
    practiceTitle: '수학 오답노트',
    practiceCount: 0,
    createdAt: DateTime(2024, 1, 1),
    lastSolvedAt: null,
    problemIdList: problemIdList,
  );
}

ProblemModel _problem(int id) => ProblemModel(
      problemId: id,
      createdAt: DateTime(2024, 1, 1),
    );

void main() {
  setUpOnoWidgetTest();

  late MockPracticeNoteService practiceNoteService;
  late MockProblemsProvider problemsProvider;
  late ProblemPracticeProvider practiceProvider;

  setUp(() {
    practiceNoteService = MockPracticeNoteService();
    problemsProvider = MockProblemsProvider();
    practiceProvider = ProblemPracticeProvider(
      problemsProvider: problemsProvider,
      practiceNoteService: practiceNoteService,
    );
  });

  testWidgets('세트를 불러오는 동안에는 뼈대가 보인다', (tester) async {
    final completer = Completer<PracticeNoteDetailModel>();
    when(() => practiceNoteService.getPracticeNoteById(1,
        showErrorSnackBar: any(named: 'showErrorSnackBar'))).thenAnswer(
      (_) => completer.future,
    );

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const PracticeDetailLoader(practiceId: 1, title: '수학 오답노트'),
        practiceProvider: practiceProvider,
        settle: false,
      );
    });

    expect(find.byType(SkeletonList), findsOneWidget);
    // 세트 이름은 목록에서 이미 알고 있어서 불러오기 전에도 보인다.
    expect(find.text('수학 오답노트'), findsOneWidget);

    completer.complete(_practice(practiceId: 1));
    await tester.pump();
  });

  testWidgets('불러오는 중에 화면을 나가면 다른 세트의 문제를 덮지 않는다', (tester) async {
    final completer = Completer<PracticeNoteDetailModel>();
    when(() => practiceNoteService.getPracticeNoteById(1,
        showErrorSnackBar: any(named: 'showErrorSnackBar'))).thenAnswer(
      (_) => completer.future,
    );
    when(() => problemsProvider.getProblem(any()))
        .thenAnswer((invocation) async => _problem(
              invocation.positionalArguments.first as int,
            ));

    // 화면에는 이미 다른 세트(2번)가 떠 있는 상황을 만든다.
    practiceProvider.currentPracticeNote = _practice(practiceId: 2);
    practiceProvider.currentProblems = [_problem(99)];

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const PracticeDetailLoader(practiceId: 1, title: '수학 오답노트'),
        practiceProvider: practiceProvider,
        settle: false,
      );
    });

    // 사용자가 나가서 로더가 사라진 뒤에 1번 세트 응답이 도착한다.
    await tester.pumpWidget(const SizedBox());
    completer.complete(_practice(practiceId: 1, problemIdList: [10]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(practiceProvider.currentPracticeNote?.practiceId, 2);
    expect(
      practiceProvider.currentProblems.map((p) => p.problemId),
      [99],
      reason: '죽은 로더가 화면에 떠 있는 세트의 문제 목록을 덮으면 복습 횟수도 엉뚱한 세트에 올라간다',
    );
  });
}
