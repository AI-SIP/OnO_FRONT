import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Notice/NoticeModel.dart';
import 'package:ono/Module/Notice/ServiceNoticeDialog.dart';

import '../../helpers/helpers.dart';

/// 공지 팝업이 두 버튼을 어떻게 구분해 돌려주는지 본다.
///
/// `그만 보기` 와 `닫기` 를 헷갈리면 사용자가 다시 안 보겠다고 눌렀는데도
/// 계속 뜨거나, 그냥 닫았는데 24시간 안 보이게 된다. 팝업이 돌려주는 값이
/// 그 갈림길이라 여기를 잠가 둔다.
void main() {
  setUpOnoWidgetTest();

  NoticeModel buildNotice({
    NoticeType type = NoticeType.warning,
    DateTime? expiresAt,
  }) {
    return NoticeModel(
      noticeId: 12,
      title: '점검 안내',
      content: '오늘 밤 2시부터 30분간 점검이 있습니다.',
      type: type,
      expiresAt: expiresAt,
    );
  }

  /// 팝업을 띄우고, 사용자가 고른 결과를 받아 볼 수 있게 감싼다.
  Future<List<NoticeDialogResult?>> pumpDialog(
    WidgetTester tester,
    NoticeModel notice, {
    Size surfaceSize = OnoSurface.phone,
  }) async {
    final results = <NoticeDialogResult?>[];

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                results.add(await ServiceNoticeDialog.show(context, notice));
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
      surfaceSize: surfaceSize,
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('제목과 본문, 버튼 두 개가 뜬다', (tester) async {
    await pumpDialog(tester, buildNotice());

    expect(find.text('점검 안내'), findsOneWidget);
    expect(find.text('오늘 밤 2시부터 30분간 점검이 있습니다.'), findsOneWidget);
    expect(find.text('그만 보기'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
  });

  testWidgets('그만 보기를 누르면 dismissed 를 돌려준다', (tester) async {
    final results = await pumpDialog(tester, buildNotice());

    await tester.tap(find.text('그만 보기'));
    await tester.pumpAndSettle();

    expect(results, [NoticeDialogResult.dismissed]);
  });

  testWidgets('닫기를 누르면 closed 를 돌려준다', (tester) async {
    final results = await pumpDialog(tester, buildNotice());

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(results, [NoticeDialogResult.closed]);
  });

  testWidgets('바깥을 눌러 닫으면 아무것도 안 고른 것으로 본다', (tester) async {
    // 값이 null 이면 부르는 쪽에서 dismiss API 를 안 부른다. 다음 진입 때
    // 다시 뜨는 쪽이 맞다.
    final results = await pumpDialog(tester, buildNotice());

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });

  testWidgets('expiresAt 이 있으면 언제까지인지 보여준다', (tester) async {
    await pumpDialog(
      tester,
      buildNotice(expiresAt: DateTime(2026, 9, 8, 23, 10)),
    );

    expect(find.text('9월 8일 23:10까지'), findsOneWidget);
  });

  testWidgets('expiresAt 이 없으면 그 줄을 아예 안 그린다', (tester) async {
    await pumpDialog(tester, buildNotice());

    expect(find.textContaining('까지'), findsNothing);
  });

  testWidgets('본문이 아주 길어도 버튼이 화면 밖으로 밀리지 않는다', (tester) async {
    // 본문은 최대 500자다. 작은 폰에서 본문이 버튼을 밀어내면 그만 보기를
    // 누를 수 없게 된다.
    final longNotice = NoticeModel(
      noticeId: 7,
      title: '긴 공지',
      content: List.filled(50, '열 글자짜리 문장입니다').join('\n'),
      type: NoticeType.info,
    );

    await pumpDialog(tester, longNotice, surfaceSize: OnoSurface.smallPhone);

    expect(tester.takeException(), isNull);
    for (final label in ['그만 보기', '닫기']) {
      final box = tester.getRect(find.text(label));
      expect(box.bottom, lessThanOrEqualTo(OnoSurface.smallPhone.height));
      expect(box.top, greaterThanOrEqualTo(0));
    }
  });

  testWidgets('모르는 종류는 info 모양으로 그린다', (tester) async {
    // NoticeType.from 이 모르는 값을 info 로 떨어뜨리므로, 팝업은 세 가지만
    // 알면 된다. 세 가지 모두 예외 없이 그려지는지 본다.
    for (final type in NoticeType.values) {
      await pumpDialog(tester, buildNotice(type: type));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
    }
  });
}
