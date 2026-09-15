// 복습 세트 만들기(제목 쓰기) 화면 골든 테스트.
//
// 알림 시각 기본값이 지금 시각이라 골든 시계(goldenNow) 로 고정된 채 뜬다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeTitleWriteScreen.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '복습 세트 만들기 화면',
    fileName: 'practice_title_write_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: () async => buildOnoApp(
      PracticeTitleWriteScreen(
        practiceRegisterModel: PracticeNoteRegisterModel(
          practiceTitle: '',
          registerProblemIdList: const [],
        ),
      ),
      cosmeticProvider: await loadedCosmeticProvider(),
      practiceProvider: ProblemPracticeProvider(
        problemsProvider: MockProblemsProvider(),
        practiceNoteService: MockPracticeNoteService(),
      ),
    ),
  );
}
