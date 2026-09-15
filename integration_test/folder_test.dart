// 공책(폴더)을 만들고 지우는 E2E 테스트.
//
// 사진이나 OS 화면 없이 서버에 쓰는 동선이다. 만들기(POST)와 지우기(DELETE)가
// 서버에 반영되고 책장 목록이 그에 맞춰 바뀌는지를 본다.
//
// 실행: integration_test/README.md
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_app.dart';
import 'helpers/guest.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('공책을 만들면 책장에 보이고, 지우면 사라진다', (tester) async {
    await runFreshApp(tester, cleanup: () => deleteGuestAccount(tester),
        () async {
      await pumpUntilFound(
        tester,
        find.text('게스트로 시작하기'),
        timeout: const Duration(seconds: 60),
      );
      await signInAsGuest(tester);

      // 실행마다 다른 이름을 쓴다. 앞 실행이 지우지 못하고 남긴 공책과 헷갈리지 않게.
      final name = 'E2E ${DateTime.now().millisecondsSinceEpoch % 100000}';

      // 만들기: 추가 버튼 → 공책 추가 → 이름 → 확인.
      await tapText(tester, '추가');
      await tapText(tester, '공책 추가');
      final nameField = find.widgetWithText(TextField, '공책 이름을 입력하세요');
      await pumpUntilFound(tester, nameField);
      await tester.enterText(nameField, name);
      await tapText(tester, '확인');
      // find.text 는 입력칸의 글자도 찾는다. 다이얼로그가 닫힌 뒤에 책장에서 찾는다.
      await pumpUntilGone(tester, nameField);
      await pumpUntilFound(tester, find.text(name));

      // 지우기: 더보기 → 공책 편집하기(선택 모드) → 공책 선택 → 삭제하기 → 삭제.
      await tester.tap(find.byIcon(Icons.more_vert));
      await pumpFor(tester, const Duration(milliseconds: 600));
      // 시트 제목도 '공책 편집하기' 라서, 마지막에 그려지는 메뉴 항목을 누른다.
      await tapText(tester, '공책 편집하기');
      await tapText(tester, name);
      await tapText(tester, '삭제하기');
      await tapText(tester, '삭제');
      await pumpUntilGone(tester, find.text(name));
    });
  });
}
