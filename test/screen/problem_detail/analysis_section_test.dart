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

  testWidgets('상태가 NOT_STARTED 면 분석 중 문구를 보여준다', (tester) async {
    final analysis = buildAnalysis(status: ProblemAnalysisStatus.NOT_STARTED);

    // CircularProgressIndicator 가 계속 애니메이션하므로 pumpAndSettle 을
    // 쓰지 않는다.
    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            _wrap(buildAnalysisSection(context, analysis, Colors.pink)),
      ),
      settle: false,
    );

    expect(find.text('AI가 문제를 분석하고 있어요'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
