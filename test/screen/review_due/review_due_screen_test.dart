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
}
