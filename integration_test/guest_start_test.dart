// 게스트로 시작해서 하단 탭 다섯을 한 바퀴 도는 E2E 테스트.
//
// 모든 E2E 의 공통 전제다. 서버 인증, 토큰 저장, 첫 데이터 조회, 튜토리얼 처리가
// 한 번에 지나가고, 탭마다 조회 API 가 dev 서버와 맞는지가 드러난다.
//
// 실행: integration_test/README.md
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_app.dart';
import 'helpers/guest.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('게스트로 시작해 탭 다섯이 모두 열린다', (tester) async {
    await runFreshApp(tester, cleanup: () => deleteGuestAccount(tester),
        () async {
      await pumpUntilFound(
        tester,
        find.text('게스트로 시작하기'),
        timeout: const Duration(seconds: 60),
      );
      await signInAsGuest(tester);

      // 탭마다 그 화면에만 있는 글자로 확인한다.
      const tabs = <String, String>{
        '복습 세트': '복습 세트 추가',
        '옷장': '꾸미기',
        '스터디룸': '스터디룸 참여',
        '마이 페이지': '학습 리포트',
        '오답노트 관리': '책장',
      };
      for (final tab in tabs.entries) {
        await tapText(tester, tab.key);
        await pumpUntilFound(tester, find.text(tab.value));
      }
    });
  });
}
