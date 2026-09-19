// 복습 세트 상세 화면 골든 테스트.
//
// 마지막 복습 일시는 비워 둔다. 날짜가 들어가면 날짜 문구가 실행하는 날에 따라
// 달라질 수 있어서다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeDetailScreen.dart';

import '../../helpers/helpers.dart';

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
        ),
        cosmeticProvider: await loadedCosmeticProvider(),
        practiceProvider: practiceProvider,
      );
    },
  );

  // 지난 복습 소감이 있는 모습은 따로 뜬다. 위 픽스처는 소감이 없어서 그 칸이
  // 아예 그려지지 않아, 생김새가 잠기지 않는다.
  screenGoldenTest(
    '복습 세트 상세 화면 (지난 복습 소감 있음)',
    fileName: 'practice_detail_screen_with_mood',
    surfaces: GoldenSurface.layouts,
    buildApp: () async {
      final practiceProvider = ProblemPracticeProvider(
        problemsProvider: MockProblemsProvider(),
        practiceNoteService: MockPracticeNoteService(),
      );
      practiceProvider.currentProblems = [
        ProblemModel(problemId: 10, reference: '수학 문제집 p.12'),
      ];

      return buildOnoApp(
        PracticeDetailScreen(
          practice: PracticeNoteDetailModel(
            practiceId: 1,
            practiceTitle: '수학 오답노트',
            practiceCount: 3,
            createdAt: DateTime(2024, 1, 1),
            lastSolvedAt: null,
            lastSessionMoodEmojiKey: 'cool_sunglasses',
            problemIdList: const [10],
          ),
        ),
        cosmeticProvider: await loadedCosmeticProvider(),
        practiceProvider: practiceProvider,
      );
    },
  );
}
