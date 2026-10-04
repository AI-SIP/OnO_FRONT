// 추천 복습 문제 화면 테스트.
//
// 몇 번 맞혀야 추천에서 빠지는지와, 문제마다 몇 번 맞혔는지를 보여 주는지 본다.
// 예전 서버는 두 값을 주지 않으므로 그때는 안내를 띄우지 않아야 한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Provider/ReviewDueProvider.dart';
import 'package:ono/Screen/ReviewDue/ReviewDueScreen.dart';

import '../../helpers/helpers.dart';
import '../../helpers/widget_harness.dart';

void main() {
  setUpOnoWidgetTest();

  late MockProblemService problemService;

  setUp(() {
    problemService = MockProblemService();
    // 카드 썸네일용 상세 조회. 실패해도 화면은 목록 응답만으로 그려진다.
    when(
      () => problemService.getProblem(
        any(),
        showErrorSnackBar: any(named: 'showErrorSnackBar'),
      ),
    ).thenThrow(Exception('상세 조회 안 함'));
  });

  Future<void> pumpScreen(WidgetTester tester, ReviewDueResponse response) {
    when(() => problemService.getReviewDueProblems())
        .thenAnswer((_) async => response);
    return pumpOnoWidget(
      tester,
      ReviewDueScreen(problemService: problemService),
      reviewDueProvider: ReviewDueProvider(problemService: problemService),
    );
  }

  testWidgets('맞힌 횟수를 주면 빠지는 기준과 문제마다 정답 진행을 보여 준다', (tester) async {
    await pumpScreen(
      tester,
      ReviewDueResponse(
        dueCount: 1,
        overdueCount: 0,
        requiredCorrectCount: 3,
        problems: [
          ReviewDueProblemModel(
            problemId: 1,
            reference: '수학 3-2',
            reviewInterval: 1,
            consecutiveCorrectCount: 0,
            correctCount: 1,
          ),
        ],
      ),
    );

    expect(find.text('3번 맞히면 추천에서 빠져요'), findsOneWidget);
    expect(find.text('정답 1/3'), findsOneWidget);
  });

  testWidgets('예전 서버라 맞힌 횟수가 없으면 안내를 띄우지 않는다', (tester) async {
    await pumpScreen(
      tester,
      ReviewDueResponse(
        dueCount: 1,
        overdueCount: 0,
        problems: [
          ReviewDueProblemModel(
            problemId: 1,
            reference: '수학 3-2',
            reviewInterval: 1,
            consecutiveCorrectCount: 0,
          ),
        ],
      ),
    );

    expect(find.textContaining('추천에서 빠져요'), findsNothing);
    expect(find.textContaining('정답 '), findsNothing);
  });

  testWidgets('처음 불러오다 실패하면 빈 목록이 아니라 다시 시도를 보인다', (tester) async {
    var calls = 0;
    when(() => problemService.getReviewDueProblems()).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw Exception('네트워크');
      return ReviewDueResponse(dueCount: 0, overdueCount: 0, problems: []);
    });
    await pumpOnoWidget(
      tester,
      ReviewDueScreen(problemService: problemService),
      reviewDueProvider: ReviewDueProvider(problemService: problemService),
    );

    expect(find.text('추천 복습을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('추천 복습 문제가 없어요'), findsNothing);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('추천 복습 문제가 없어요'), findsOneWidget);
  });

  testWidgets('카드에 오늘인지 며칠 밀렸는지 붙인다', (tester) async {
    final today = DateTime.now();
    await pumpScreen(
      tester,
      ReviewDueResponse(
        dueCount: 2,
        overdueCount: 1,
        problems: [
          ReviewDueProblemModel(
            problemId: 1,
            reference: '밀린 문제',
            nextReviewAt: today.subtract(const Duration(days: 3)),
            reviewInterval: 1,
            consecutiveCorrectCount: 0,
          ),
          ReviewDueProblemModel(
            problemId: 2,
            reference: '오늘 문제',
            nextReviewAt: today,
            reviewInterval: 1,
            consecutiveCorrectCount: 0,
          ),
        ],
      ),
    );

    expect(find.text('3일 밀림'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
  });

  testWidgets('받아 둔 목록이 있어도 화면에 들어오면 다시 받는다', (tester) async {
    final provider = ReviewDueProvider(problemService: problemService);
    when(() => problemService.getReviewDueProblems()).thenAnswer(
      (_) async =>
          ReviewDueResponse(dueCount: 0, overdueCount: 0, problems: []),
    );
    await provider.fetchReviewDue();
    clearInteractions(problemService);

    await pumpOnoWidget(
      tester,
      ReviewDueScreen(problemService: problemService),
      reviewDueProvider: provider,
    );

    verify(() => problemService.getReviewDueProblems()).called(1);
  });
}
