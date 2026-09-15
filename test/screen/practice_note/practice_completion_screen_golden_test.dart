// 복습 완료 화면 골든 테스트.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeCompletionScreen.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '복습 완료 화면',
    fileName: 'practice_completion_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: () async {
      final practiceNoteService = MockPracticeNoteService();
      when(() => practiceNoteService.getPracticeNoteById(1,
          showErrorSnackBar: true)).thenAnswer(
        (_) async => PracticeNoteDetailModel(
          practiceId: 1,
          practiceTitle: '수학 오답노트',
          practiceCount: 2,
          createdAt: DateTime(2024, 1, 1),
          lastSolvedAt: null,
          problemIdList: const [],
        ),
      );

      return buildOnoApp(
        const PracticeCompletionScreen(
          practiceId: 1,
          totalProblems: 5,
          practiceRound: 2,
        ),
        cosmeticProvider: await loadedCosmeticProvider(),
        practiceProvider: ProblemPracticeProvider(
          problemsProvider: MockProblemsProvider(),
          practiceNoteService: practiceNoteService,
        ),
      );
    },
  );
}
