// 복습 세트 목록 화면 골든 테스트.
//
// 이 화면은 스스로 목록을 부르지 않고 들어오기 전에 받아 둔 것을 그린다.
// 위젯 테스트와 같이 프로바이더에서 첫 페이지를 받아 둔 뒤 띄운다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteThumbnailModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeThumbnailScreen.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '복습 세트 목록 화면',
    fileName: 'practice_thumbnail_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: () async {
      final practiceNoteService = MockPracticeNoteService();
      final thumbnails = [
        PracticeNoteThumbnails(
          practiceId: 1,
          practiceTitle: '수학 오답노트',
          practiceCount: 3,
          lastSolvedAt: null,
        ),
        PracticeNoteThumbnails(
          practiceId: 2,
          practiceTitle: '영어 단어',
          practiceCount: 0,
          lastSolvedAt: null,
        ),
      ];
      when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: thumbnails,
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));

      final practiceProvider = ProblemPracticeProvider(
        problemsProvider: MockProblemsProvider(),
        practiceNoteService: practiceNoteService,
      );
      await practiceProvider.loadInitialPracticeThumbnails();

      return buildOnoApp(
        const PracticeThumbnailScreen(),
        cosmeticProvider: await loadedCosmeticProvider(),
        practiceProvider: practiceProvider,
      );
    },
  );
}
