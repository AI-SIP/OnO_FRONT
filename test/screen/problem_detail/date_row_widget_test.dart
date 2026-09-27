import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemDetail/Widget/DateRowWidget.dart';

import '../../helpers/helpers.dart';

/// DateRowWidget 은 Row/Padding 을 직접 돌려주는 builder 함수라서
/// Scaffold 로 감싸 화면처럼 띄운다.
Widget _wrap(Widget child) =>
    Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child));

void main() {
  setUpOnoWidgetTest();

  group('buildDateRow', () {
    testWidgets('날짜와 "푼 날짜" 라벨을 보여준다', (tester) async {
      await pumpOnoWidget(
        tester,
        _wrap(buildDateRow(DateTime(2026, 3, 2), Colors.pink)),
      );

      expect(find.text('푼 날짜'), findsOneWidget);
      expect(find.text('2026년 3월 2일'), findsOneWidget);
    });
  });

  group('buildReferenceRow', () {
    testWidgets('출처가 있으면 그대로 보여준다', (tester) async {
      await pumpOnoWidget(
        tester,
        _wrap(buildReferenceRow('2024 수능특강 12p', Colors.pink)),
      );

      expect(find.text('2024 수능특강 12p'), findsOneWidget);
      expect(find.text('작성한 출처가 없습니다!'), findsNothing);
    });

    testWidgets('출처가 null 이면 안내 문구를 보여준다', (tester) async {
      await pumpOnoWidget(
        tester,
        _wrap(buildReferenceRow(null, Colors.pink)),
      );

      expect(find.text('작성한 출처가 없습니다!'), findsOneWidget);
    });

    testWidgets('출처가 빈 문자열이면 안내 문구를 보여준다', (tester) async {
      await pumpOnoWidget(
        tester,
        _wrap(buildReferenceRow('', Colors.pink)),
      );

      expect(find.text('작성한 출처가 없습니다!'), findsOneWidget);
    });
  });

  group('buildMemoSection', () {
    testWidgets('메모가 있으면 그대로 보여준다', (tester) async {
      await pumpOnoWidget(
        tester,
        _wrap(buildMemoSection('부호 실수 조심하기', Colors.pink)),
      );

      expect(find.text('부호 실수 조심하기'), findsOneWidget);
    });

    testWidgets('메모가 null 이면 안내 문구를 보여준다', (tester) async {
      await pumpOnoWidget(
        tester,
        _wrap(buildMemoSection(null, Colors.pink)),
      );

      expect(find.text('작성한 메모가 없습니다!'), findsOneWidget);
    });

    testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
      await pumpOnoWidget(
        tester,
        _wrap(buildMemoSection('메모', Colors.pink)),
        surfaceSize: OnoSurface.tablet,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
