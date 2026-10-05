import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Design/AppToast.dart';
import 'package:ono/Util/AppNavigator.dart';
import 'package:ono/Util/PendingDeletion.dart';

import '../helpers/helpers.dart';

/// 지우기를 잠깐 미뤄 되돌릴 수 있는지 본다.
///
/// 전에는 확인 창 뒤에 바로 지워서 잘못 지운 오답노트를 되살릴 수 없었다.
void main() {
  setUpOnoTest();

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
  }

  tearDown(AppToast.dismiss);

  testWidgets('되돌리기를 누르면 지우지 않고 다시 보인다', (tester) async {
    await pumpApp(tester);
    var committed = false;

    final future = PendingDeletion.instance.schedule(
      problemIds: [101],
      message: '오답노트를 지웠어요 1',
      commit: () async => committed = true,
    );
    await tester.pump();
    expect(PendingDeletion.instance.isProblemHidden(101), isTrue);

    await tester.tap(find.text('되돌리기'));
    await tester.pump();

    expect(await future, isFalse);
    expect(committed, isFalse);
    expect(PendingDeletion.instance.isProblemHidden(101), isFalse);
  });

  testWidgets('그냥 두면 시간이 지난 뒤 지우고 계속 숨긴다', (tester) async {
    await pumpApp(tester);
    var committed = false;

    final future = PendingDeletion.instance.schedule(
      problemIds: [102],
      folderIds: [7],
      message: '오답노트를 지웠어요 2',
      commit: () async => committed = true,
    );
    await tester.pump();
    expect(committed, isFalse, reason: '되돌리기를 기다리는 동안은 지우지 않는다');

    await tester.pump(const Duration(seconds: 5));

    expect(await future, isTrue);
    expect(committed, isTrue);
    expect(PendingDeletion.instance.isProblemHidden(102), isTrue);
    expect(PendingDeletion.instance.isFolderHidden(7), isTrue);
  });

  testWidgets('지우기 요청이 실패하면 다시 보이고 예외를 넘긴다', (tester) async {
    await pumpApp(tester);

    final future = PendingDeletion.instance.schedule(
      problemIds: [103],
      message: '오답노트를 지웠어요 3',
      commit: () async => throw Exception('네트워크'),
    );
    // 실패가 테스트 밖으로 새지 않도록 기다리기 전에 받아 둔다.
    final failed = expectLater(future, throwsException);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    await failed;
    expect(PendingDeletion.instance.isProblemHidden(103), isFalse);
  });

  testWidgets('다른 알림이 덮으면 되돌리지 않은 것으로 보고 지운다', (tester) async {
    await pumpApp(tester);
    var committed = false;

    final future = PendingDeletion.instance.schedule(
      problemIds: [104],
      message: '오답노트를 지웠어요 4',
      commit: () async => committed = true,
    );
    await tester.pump();
    AppToast.info('다른 알림');
    await tester.pump();

    expect(await future, isTrue);
    expect(committed, isTrue);
  });

  testWidgets('복습 기록도 되돌리기를 기다리는 동안 숨기고 그 뒤에 지운다', (tester) async {
    await pumpApp(tester);
    var committed = false;

    final future = PendingDeletion.instance.schedule(
      solveIds: [501],
      message: '복습 기록을 지웠어요 5',
      commit: () async => committed = true,
    );
    await tester.pump();
    expect(PendingDeletion.instance.isSolveHidden(501), isTrue);
    expect(committed, isFalse);

    await tester.pump(const Duration(seconds: 5));

    expect(await future, isTrue);
    expect(committed, isTrue);
    expect(PendingDeletion.instance.isSolveHidden(501), isTrue);
  });
}
