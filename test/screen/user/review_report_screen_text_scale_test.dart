import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/LearningReport/LearningReportResponseModel.dart';
import 'package:ono/Screen/User/Widget/ReviewReportScreen.dart';

import '../../helpers/helpers.dart';

/// 학습 리포트의 핵심 지표 카드가 글자 크기를 키운 기기에서 깨지지 않는지 본다.
///
/// 카드 높이가 104 로 고정돼 있어서, 삼성 기기처럼 기본 글자가 크거나 접근성
/// 에서 글자를 키운 사용자에게 라벨과 숫자가 카드 밖으로 넘쳤다. 숫자와 단위도
/// 한 줄에 안 들어가면 오른쪽으로 넘쳤다.
void main() {
  setUpOnoWidgetTest();

  late MockLearningReportService reportService;

  setUp(() {
    reportService = MockLearningReportService();
    final report = LearningReportResponseModel.fromJson(
      loadJsonFixture('learning_report/learning_report_full.json'),
    );
    when(() =>
            reportService.getLearningReport(baseDate: any(named: 'baseDate')))
        .thenAnswer((_) async => report);
  });

  Future<void> pumpReport(WidgetTester tester, double textScale) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: ReviewReportScreen(reportService: reportService),
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// 지표 카드들의 높이. 카드는 minHeight 104 로 잡아 둔 Container 다.
  List<double> cardHeights(WidgetTester tester) {
    final finder = find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.minHeight == 104,
    );
    return finder
        .evaluate()
        .map((e) => tester.getSize(find.byWidget(e.widget)).height)
        .toList();
  }

  testWidgets('기본 글자 크기에서는 카드가 104 높이로 그려진다', (tester) async {
    await pumpReport(tester, 1.0);

    expect(find.text('핵심 지표'), findsOneWidget);
    expect(cardHeights(tester), everyElement(104.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('글자 크기를 키우면 카드가 내용에 맞춰 늘어난다', (tester) async {
    // 이게 이슈의 핵심이다. 높이를 104 로 고정해 두면 여기서 카드가 안 늘어나고
    // 라벨과 숫자가 카드 밖으로 넘친다.
    await pumpReport(tester, 1.6);

    final heights = cardHeights(tester);
    expect(heights, isNotEmpty, reason: '지표 카드를 못 찾으면 검사가 의미 없다');
    expect(
      heights,
      everyElement(greaterThan(104.0)),
      reason: '카드가 안 늘어나면 내용이 카드 밖으로 넘친다',
    );
  });

  testWidgets('글자를 키워도 숫자와 단위가 가로로 넘치지 않는다', (tester) async {
    await pumpReport(tester, 1.6);

    expect(
      tester.takeException(),
      isNull,
      reason: '숫자 줄이 카드 폭을 넘으면 RenderFlex 가로 넘침이 난다',
    );
  });

  testWidgets('같은 줄의 두 카드는 높이가 서로 같다', (tester) async {
    await pumpReport(tester, 1.6);

    // 지표는 두 개씩 세 줄이다. 줄마다 높이가 하나여야 어긋나 보이지 않는다.
    final heights = cardHeights(tester);
    expect(heights.length, 6);
    for (var i = 0; i < heights.length; i += 2) {
      expect(heights[i], heights[i + 1]);
    }
  });
}
