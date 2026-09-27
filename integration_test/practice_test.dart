// 복습 세트를 만들고 한 바퀴 복습해 완료하는 E2E 테스트.
//
// 앱의 두 번째 핵심 동선이다. 세트 만들기(POST), 풀이 기록(POST), 복습 완료(PATCH)가
// 이어지는지를 본다.
//
// 오답노트는 사진이 있어야 등록되는데 사진 선택은 OS 화면이라 이 도구로는 누를 수
// 없다. 그래서 문제 둘은 앱의 서비스로 서버에 바로 넣고(helpers/seed.dart), 복습은
// "현장에서 풀었어요" 로 사진 없이 기록한다.
//
// 실행: integration_test/README.md
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_app.dart';
import 'helpers/guest.dart';
import 'helpers/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('복습 세트를 만들어 끝까지 복습하면 완료된다', (tester) async {
    await runFreshApp(tester, cleanup: () => deleteGuestAccount(tester),
        () async {
      await pumpUntilFound(
        tester,
        find.text('게스트로 시작하기'),
        timeout: const Duration(seconds: 60),
      );
      await signInAsGuest(tester);

      const first = 'E2E 첫 문제';
      const second = 'E2E 둘째 문제';
      await seedProblems(tester, references: [first, second]);

      // 세트 만들기: 복습 세트 탭 → 추가 → 문제 둘 선택 → 다음 → 제목 → 만들기.
      await tapText(tester, '복습 세트');
      await tapText(tester, '복습 세트 추가');
      await tapText(tester, first);
      await tapText(tester, second);
      await tapText(tester, '다음');
      final titleField = find.widgetWithText(
        TextField,
        'ex) 9월 모의 전과목 모의고사 오답 복습',
      );
      await pumpUntilFound(tester, titleField);
      const title = 'E2E 복습 세트';
      await tester.enterText(titleField, title);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pumpFor(tester, const Duration(milliseconds: 600));
      // 앱바 제목도 '복습 세트 만들기' 라서 버튼으로 찾는다.
      await tester.tap(find.widgetWithText(ElevatedButton, '복습 세트 만들기'));
      // find.text 는 입력칸의 글자도 찾는다. 입력 화면이 닫힌 뒤에 목록에서 찾는다.
      await pumpUntilGone(tester, titleField);
      await pumpUntilFound(tester, find.text(title));

      // 복습: 세트 → 복습하기 → 등록한 순서로.
      await tapText(tester, title);
      await tapText(tester, '복습하기');
      await tapText(tester, '등록한 순서로 복습하기');

      // 첫 문제는 현장에서 풀었다고 기록한다. 기본값(정답, 10분)으로 저장된다.
      await tapText(tester, '다시 풀기');
      await tapText(tester, '현장에서 풀었어요');
      await tapText(tester, '문제 복습 완료');
      await pumpUntilFound(tester, find.text('다음 문제 >'));

      // 둘째 문제로 넘어가 복습을 마친다.
      await tapText(tester, '다음 문제 >');
      await tapText(tester, '복습 마치기');
      await pumpUntilFound(tester, find.text('1회차 복습을 완료했어요'));
      await tapText(tester, '확인');
      await pumpUntilGone(tester, find.text('1회차 복습을 완료했어요'));
    });
  });
}
