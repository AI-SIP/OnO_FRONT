// 복습 세트 상세 화면 골든 테스트.
//
// 마지막 복습 일시는 비워 둔다. 날짜가 들어가면 날짜 문구가 실행하는 날에 따라
// 달라질 수 있어서다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Model/Problem/ProblemSolveModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeDetailScreen.dart';

import '../../helpers/helpers.dart';

ProblemSolveModel _solve(int problemId, AnswerStatus status, int seconds) {
  final at = DateTime(2026, 9, 1);
  return ProblemSolveModel(
    problemSolveId: problemId,
    problemId: problemId,
    userId: 1,
    practicedAt: at,
    answerStatus: status,
    improvements: const [],
    timeSpentSeconds: seconds,
    migratedFromLegacy: false,
    imageUrls: const [],
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '복습 세트 상세 화면',
    fileName: 'practice_detail_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: () async {
      final practiceProvider = ProblemPracticeProvider(
        problemsProvider: MockProblemsProvider(),
        practiceNoteService: MockPracticeNoteService(),
      );
      practiceProvider.currentProblems = [
        ProblemModel(problemId: 10, reference: '수학 문제집 p.12'),
        ProblemModel(problemId: 20, reference: '모의고사 21번'),
      ];
      // 세트 분석 카드가 채워진 모습을 잠근다. 하나는 맞히고 하나는 틀렸다.
      final solveService = MockProblemSolveService();
      when(() => solveService.getProblemSolvesByProblemId(10,
              showErrorSnackBar: any(named: 'showErrorSnackBar')))
          .thenAnswer((_) async => [_solve(10, AnswerStatus.CORRECT, 150)]);
      when(() => solveService.getProblemSolvesByProblemId(20,
              showErrorSnackBar: any(named: 'showErrorSnackBar')))
          .thenAnswer((_) async => [_solve(20, AnswerStatus.WRONG, 270)]);

      return buildOnoApp(
        PracticeDetailScreen(
          practice: PracticeNoteDetailModel(
            practiceId: 1,
            practiceTitle: '수학 오답노트',
            practiceCount: 3,
            createdAt: DateTime(2024, 1, 1),
            lastSolvedAt: null,
            problemIdList: const [10, 20],
          ),
          problemSolveService: solveService,
        ),
        cosmeticProvider: await loadedCosmeticProvider(),
        practiceProvider: practiceProvider,
      );
    },
  );
}
