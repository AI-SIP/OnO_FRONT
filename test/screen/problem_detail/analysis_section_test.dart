import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ProblemAnalysisStatus.dart';
import 'package:ono/Screen/ProblemDetail/Widget/AnalysisSection.dart';

import '../../helpers/helpers.dart';
import 'problem_detail_fixtures.dart';

Widget _wrap(Widget child) =>
    Scaffold(body: SingleChildScrollView(child: child));

void main() {
  setUpOnoWidgetTest();

  testWidgets('analysis 가 null 이면 이미지 없음 안내를 보여준다', (tester) async {
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildAnalysisSection(context, null, Colors.pink)),
      ),
    );

    expect(find.text('이미지가 없어 분석하지 못했어요'), findsOneWidget);
  });

  testWidgets('상태가 NO_IMAGE 면 이미지 없음 안내를 보여준다', (tester) async {
    final analysis =
        buildAnalysis(status: ProblemAnalysisStatus.NO_IMAGE, subject: null);

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildAnalysisSection(context, analysis, Colors.pink)),
      ),
    );

    expect(find.text('이미지가 없어 분석하지 못했어요'), findsOneWidget);
  });

  testWidgets('상태가 NOT_STARTED 면 분석하지 않은 문제로 보이고 분석하기를 누를 수 있다',
      (tester) async {
    // 등록할 때 AI 분석을 끄면 이 상태로 남는다. 전에는 분석 중으로 보여서
    // 끝나지 않는 로딩처럼 보였다.
    final analysis = buildAnalysis(status: ProblemAnalysisStatus.NOT_STARTED);
    var requested = 0;

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => _wrap(buildAnalysisSection(
          context,
          analysis,
          Colors.pink,
          onRequestAnalysis: () => requested++,
        )),
      ),
    );

    expect(find.text('AI 분석을 하지 않은 문제예요'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('AI 분석하기'));
    expect(requested, 1);
  });

  testWidgets('상태가 RATE_LIMIT_EXCEEDED 면 한도 안내와 다시 분석하기를 보여준다', (tester) async {
    expect(ProblemAnalysisStatus.fromString('RATE_LIMIT_EXCEEDED'),
        ProblemAnalysisStatus.RATE_LIMIT_EXCEEDED);
    final analysis =
        buildAnalysis(status: ProblemAnalysisStatus.RATE_LIMIT_EXCEEDED);
    var requested = 0;

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => _wrap(buildAnalysisSection(
          context,
          analysis,
          Colors.pink,
          onRequestAnalysis: () => requested++,
        )),
      ),
    );

    expect(find.text('오늘 AI 분석 횟수를 모두 썼어요'), findsOneWidget);
    await tester.tap(find.text('다시 분석하기'));
    expect(requested, 1);
  });

  testWidgets('분석하기 콜백이 없으면 버튼을 그리지 않는다', (tester) async {
    final analysis = buildAnalysis(status: ProblemAnalysisStatus.NOT_STARTED);

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildAnalysisSection(context, analysis, Colors.pink)),
      ),
    );

    expect(find.text('AI 분석하기'), findsNothing);
  });

  testWidgets('분석을 기다리다 확인을 멈췄으면 다시 확인하기를 보여준다', (tester) async {
    final analysis = buildAnalysis(status: ProblemAnalysisStatus.PROCESSING);
    var refreshed = 0;

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => _wrap(buildAnalysisSection(
          context,
          analysis,
          Colors.pink,
          timedOut: true,
          onRefreshAnalysis: () => refreshed++,
        )),
      ),
    );

    expect(find.text('분석이 생각보다 오래 걸리고 있어요'), findsOneWidget);
    await tester.tap(find.text('다시 확인하기'));
    expect(refreshed, 1);
  });

  testWidgets('실패하면 다시 분석하기를 누를 수 있다', (tester) async {
    final analysis = buildAnalysis(status: ProblemAnalysisStatus.FAILED);
    var requested = 0;

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => _wrap(buildAnalysisSection(
          context,
          analysis,
          Colors.pink,
          onRequestAnalysis: () => requested++,
        )),
      ),
    );

    await tester.tap(find.text('다시 분석하기'));
    expect(requested, 1);
  });

  testWidgets('상태가 PROCESSING 이면 분석 중 문구를 보여준다', (tester) async {
    final analysis = buildAnalysis(status: ProblemAnalysisStatus.PROCESSING);

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildAnalysisSection(context, analysis, Colors.pink)),
      ),
      settle: false,
    );

    expect(find.text('AI가 문제를 분석하고 있어요'), findsOneWidget);
  });

  testWidgets('상태가 FAILED 면 에러 메시지를 함께 보여준다', (tester) async {
    final analysis = buildAnalysis(
      status: ProblemAnalysisStatus.FAILED,
      errorMessage: '분석 서버 응답 시간 초과',
    );

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildAnalysisSection(context, analysis, Colors.pink)),
      ),
    );

    expect(find.text('분석 중 오류가 발생했어요'), findsOneWidget);
    expect(find.text('분석 서버 응답 시간 초과'), findsOneWidget);
  });

  testWidgets('상태가 FAILED 인데 에러 메시지가 없으면 메시지 줄은 생략한다', (tester) async {
    final analysis = buildAnalysis(
      status: ProblemAnalysisStatus.FAILED,
      errorMessage: null,
    );

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildAnalysisSection(context, analysis, Colors.pink)),
      ),
    );

    expect(find.text('분석 중 오류가 발생했어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('상태가 COMPLETED 면 분석 항목을 전부 보여준다', (tester) async {
    final analysis = buildAnalysis(status: ProblemAnalysisStatus.COMPLETED);

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildAnalysisSection(context, analysis, Colors.pink)),
      ),
    );

    expect(find.text('과목'), findsOneWidget);
    expect(find.text('수학'), findsOneWidget);
    expect(find.text('문제 유형'), findsOneWidget);
    expect(find.text('핵심 포인트'), findsOneWidget);
    expect(find.text('판별식'), findsOneWidget);
    expect(find.text('근의 공식'), findsOneWidget);
    expect(find.text('풀이'), findsOneWidget);
    expect(find.text('자주 하는 실수'), findsOneWidget);
    expect(find.text('학습 팁'), findsOneWidget);
  });

  testWidgets('COMPLETED 인데 일부 항목만 있으면 있는 항목만 보여준다', (tester) async {
    final analysis = buildAnalysis(
      status: ProblemAnalysisStatus.COMPLETED,
      subject: '영어',
      problemType: null,
      keyPoints: null,
      solution: null,
      commonMistakes: null,
      studyTips: null,
    );

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildAnalysisSection(context, analysis, Colors.pink)),
      ),
    );

    expect(find.text('과목'), findsOneWidget);
    expect(find.text('영어'), findsOneWidget);
    expect(find.text('문제 유형'), findsNothing);
    expect(find.text('핵심 포인트'), findsNothing);
    expect(find.text('풀이'), findsNothing);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    final analysis = buildAnalysis(status: ProblemAnalysisStatus.COMPLETED);

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildAnalysisSection(context, analysis, Colors.pink)),
      ),
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
