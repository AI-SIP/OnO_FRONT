// 태그 선택 화면 골든 테스트.
//
// 이 화면은 TagService 를 스스로 만들어 주입할 수 없어서, 위젯 테스트와 같이
// dart:io 수준에서 HTTP 를 가로채 태그 목록을 돌려준다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:ono/Screen/ProblemRegister/TagSelectionScreen.dart';

import '../../helpers/helpers.dart';
import '_test_support.dart';

void main() {
  setUpOnoWidgetTest();

  screenGoldenTest(
    '태그 선택 화면',
    fileName: 'tag_selection_screen',
    surfaces: GoldenSurface.layouts,
    runWith: (body) => withFakeJsonApi(
      body,
      json: [
        {'tagId': 1, 'name': '수학'},
        {'tagId': 2, 'name': '영어'},
        {'tagId': 3, 'name': '함수'},
        {'tagId': 4, 'name': '계산 실수'},
      ],
    ),
    buildApp: () async {
      seedValidAuthToken();
      return buildOnoApp(
        const TagSelectionScreen(
          initialTags: [],
          initialSelectedTagIds: {1, 3},
        ),
        cosmeticProvider: await loadedCosmeticProvider(),
      );
    },
  );
}
