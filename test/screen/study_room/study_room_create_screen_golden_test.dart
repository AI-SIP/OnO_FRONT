// 스터디룸 만들기 화면 골든 테스트.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:ono/Provider/StudyRoomProvider.dart';
import 'package:ono/Screen/StudyRoom/StudyRoomCreateScreen.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '스터디룸 만들기 화면',
    fileName: 'study_room_create_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: () async => buildOnoApp(
      const StudyRoomCreateScreen(),
      cosmeticProvider: await loadedCosmeticProvider(),
      studyRoomProvider: StudyRoomProvider(
        studyRoomService: MockStudyRoomService(),
      ),
    ),
  );
}
