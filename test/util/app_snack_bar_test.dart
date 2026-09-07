import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Util/AppSnackBar.dart';

import '../helpers/helpers.dart';

/// lib/Util/AppSnackBar.dart 검증.
///
/// AppSnackBar.messengerKey 는 앱 전체가 공유하는 static GlobalKey 라서,
/// 테스트 사이에도 상태가 이어질 수 있다. 각 테스트는 시작할 때 반드시
/// key 가 붙은 위젯을 새로 pump 해서(또는 떼어내서) 이전 테스트의 잔여 상태와
/// 섞이지 않게 한다.
void main() {
  setUpOnoTest();

  Future<void> pumpAppWithMessenger(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: AppSnackBar.messengerKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
  }

  Future<void> detachMessenger(WidgetTester tester) async {
    // AppSnackBar.messengerKey 를 참조하지 않는 트리로 교체해서
    // 이전 트리를 unmount 시키고 currentState 를 null 로 되돌린다.
    await tester.pumpWidget(const SizedBox.shrink());
  }

  group('AppSnackBar.showError', () {
    testWidgets('messengerKey.currentState 가 없으면 조용히 무시한다', (tester) async {
      await detachMessenger(tester);

      expect(AppSnackBar.messengerKey.currentState, isNull);

      expect(() => AppSnackBar.showError('에러 메시지'), returnsNormally);
    });

    testWidgets('빈 문자열이나 공백 메시지는 무시하고 스낵바를 띄우지 않는다', (tester) async {
      await pumpAppWithMessenger(tester);

      AppSnackBar.showError('');
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);

      AppSnackBar.showError('   ');
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);

      await detachMessenger(tester);
    });

    testWidgets('안전한 메시지는 그대로 스낵바에 노출된다', (tester) async {
      await pumpAppWithMessenger(tester);

      AppSnackBar.showError('폴더 이름은 20자 이하여야 합니다.');
      await tester.pump();

      expect(find.text('폴더 이름은 20자 이하여야 합니다.'), findsOneWidget);

      await detachMessenger(tester);
    });

    testWidgets('내부 정보로 보이는 메시지는 ErrorMessageMapper 로 걸러진다', (tester) async {
      await pumpAppWithMessenger(tester);

      AppSnackBar.showError('SocketException: Failed host lookup');
      await tester.pump();

      expect(find.text('네트워크 연결이 원활하지 않습니다. 인터넷 상태를 확인해주세요.'), findsOneWidget);

      await detachMessenger(tester);
    });

    testWidgets('800ms 안에 같은 메시지가 다시 오면 중복 표시를 무시한다', (tester) async {
      await pumpAppWithMessenger(tester);

      AppSnackBar.showError('같은 에러 메시지');
      await tester.pump();
      expect(find.text('같은 에러 메시지'), findsOneWidget);

      // 곧바로 같은 메시지를 다시 보내도 새 스낵바가 겹쳐 뜨지 않는다.
      AppSnackBar.showError('같은 에러 메시지');
      await tester.pump();
      expect(find.text('같은 에러 메시지'), findsOneWidget);

      await detachMessenger(tester);
    });

    testWidgets('800ms 가 지난 뒤 같은 메시지가 오면 다시 표시한다', (tester) async {
      await pumpAppWithMessenger(tester);

      AppSnackBar.showError('반복되는 에러 메시지');
      await tester.pump();
      expect(find.text('반복되는 에러 메시지'), findsOneWidget);

      // 실제 시간으로 800ms 넘게 기다린다. AppSnackBar 는 DateTime.now() 를
      // 직접 읽기 때문에 tester.pump(Duration) 으로는 시간을 앞당길 수 없고,
      // testWidgets 기본 zone 은 fake time 이라 await Future.delayed 를
      // 그냥 쓰면 가짜 타이머가 영영 안 울려서 테스트가 멈춘다. tester.runAsync 로
      // 잠깐 진짜 시간 zone 으로 나가야 한다.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 850)),
      );

      AppSnackBar.showError('반복되는 에러 메시지');
      await tester.pump();
      expect(find.text('반복되는 에러 메시지'), findsOneWidget);

      await detachMessenger(tester);
    });

    testWidgets('메시지가 다르면 800ms 이내여도 새로 표시한다', (tester) async {
      await pumpAppWithMessenger(tester);

      AppSnackBar.showError('첫 번째 에러');
      await tester.pump();
      expect(find.text('첫 번째 에러'), findsOneWidget);

      AppSnackBar.showError('두 번째 에러');
      await tester.pump();
      expect(find.text('두 번째 에러'), findsOneWidget);

      await detachMessenger(tester);
    });
  });
}
