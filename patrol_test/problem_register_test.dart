// 갤러리에서 사진을 골라 오답노트를 여러 장 등록하는 E2E 테스트.
//
// 앱의 가장 핵심 동선이다. 사진 선택이 OS 화면이라 integration_test 로는 못 누르고,
// Patrol 이 iOS 사진 선택 화면을 대신 누른다.
//
// 1장 작성이 아니라 여러 장 작성을 쓰는 이유: 1장 작성은 사진을 고른 뒤 네이티브
// 자르기 화면을 한 번 더 거친다. 여러 장 작성은 자르기를 건너뛰어서 OS 화면 조작이
// 사진 선택 한 번으로 끝난다.
//
// 실행 전에 시뮬레이터 사진첩에 사진이 있어야 한다. 실행: patrol_test/README.md
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../integration_test/helpers/e2e_app.dart';
import '../integration_test/helpers/guest.dart';

void main() {
  patrolTest('갤러리에서 사진을 골라 오답노트를 등록한다', ($) async {
    final tester = $.tester;
    await runFreshApp(tester, cleanup: () => deleteGuestAccount(tester),
        () async {
      await pumpUntilFound(
        tester,
        find.text('게스트로 시작하기'),
        timeout: const Duration(seconds: 60),
      );
      await signInAsGuest(tester);

      await tapText(tester, '추가');
      await tapText(tester, '오답노트 여러장 작성');
      // 들어가자마자 사진을 어디서 가져올지 묻는 시트가 뜬다.
      await tapText(tester, '갤러리에서 여러 장 선택');

      // 여기부터 iOS 사진 선택 화면. 첫 사진을 누르고 추가를 누른다.
      await $.platform.ios.pickMultipleImagesFromGallery(imageIndexes: [0]);

      // 사진을 고른 뒤 공통 정보(공책, 태그, 날짜) 화면을 거쳐 초안 목록으로 간다.
      await tapText(tester, '상세 정보 입력하기');
      await tapText(tester, '1개 등록하기');
      await pumpUntilFound(
        tester,
        find.text('1개의 문제가 등록되었습니다.'),
        timeout: const Duration(seconds: 60),
      );
    });
  });
}
