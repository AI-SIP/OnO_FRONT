import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/LearningReport/LearningOverviewModel.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Provider/ReviewDueProvider.dart';
import 'package:ono/Screen/User/Widget/ReviewReportScreen.dart';
import 'package:ono/Util/AppClock.dart';

import '../../helpers/helpers.dart';

/// 학습 보고서가 글자 크기를 키운 기기에서 깨지지 않는지 본다.
///
/// 삼성 기기처럼 기본 글자가 크거나 접근성에서 글자를 키운 사용자가 많다.
/// 요약 카드의 세 칸은 폭을 나눠 써서 특히 넘치기 쉽다. 넘치면 Flutter 가
/// RenderFlex 넘침 예외를 던지므로 예외가 없는지로 확인한다.
void main() {
  setUpOnoWidgetTest();

  setUpAll(() {
    registerFallbackValue(LearningOverviewPeriod.week);
  });

  late MockLearningReportService reportService;
  late MockProblemService problemService;

  setUp(() {
    AppClock.setForTest(() => DateTime(2026, 10, 8, 10));
    reportService = MockLearningReportService();
    problemService = MockProblemService();
    when(() => problemService.getReviewDueProblems()).thenAnswer(
      (_) async => ReviewDueResponse(
        dueCount: 128,
        overdueCount: 0,
        problems: [
          ReviewDueProblemModel(
            problemId: 1,
            nextReviewAt: DateTime(2026, 8, 1),
            reviewInterval: 1,
            consecutiveCorrectCount: 0,
          ),
        ],
      ),
    );
  });

  tearDown(AppClock.resetForTest);

  /// 숫자를 키워 둔 주간 보고서. 자릿수가 많을수록 넘치기 쉽다.
  LearningOverviewModel bigWeek() => LearningOverviewModel.fromJson({
        ...loadJsonFixture('learning_report/learning_overview_week.json'),
        'summary': {
          'reviewCount': 1284,
          'accuracy': 100.0,
          'studyDays': 7,
          'currentStreak': 365,
        },
        'previous': {'reviewCount': 9, 'accuracy': 12.0, 'studyDays': 1},
        'weakFolders': [
          {
            'folderId': 1,
            'name': '아주 긴 폴더 이름이 들어가면 한 줄에 다 안 들어간다 고등 수학 상',
            'solveCount': 999,
            'wrongCount': 512,
            'accuracy': 12.5,
          },
        ],
      });

  Future<void> pumpReport(
    WidgetTester tester, {
    required double textScale,
    required Size size,
    required LearningOverviewModel overview,
  }) async {
    when(() => reportService.getOverview(
          period: any(named: 'period'),
          baseDate: any(named: 'baseDate'),
        )).thenAnswer((_) async => overview);

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: ReviewReportScreen(reportService: reportService),
        ),
      ),
      reviewDueProvider: ReviewDueProvider(problemService: problemService),
      surfaceSize: size,
    );
  }

  for (final scale in [1.0, 1.3, 1.6]) {
    for (final entry in {
      '작은 폰': OnoSurface.smallPhone,
      '폰': OnoSurface.phone,
      '태블릿': OnoSurface.tablet,
    }.entries) {
      testWidgets('글자 $scale배, ${entry.key}에서 기록 있는 주가 넘치지 않는다',
          (tester) async {
        await pumpReport(
          tester,
          textScale: scale,
          size: entry.value,
          overview: bigWeek(),
        );

        expect(find.text('자주 틀린 폴더'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('글자 $scale배, ${entry.key}에서 빈 주가 넘치지 않는다', (tester) async {
        await pumpReport(
          tester,
          textScale: scale,
          size: entry.value,
          overview: LearningOverviewModel.fromJson(
            loadJsonFixture('learning_report/learning_overview_empty.json'),
          ),
        );

        expect(find.text('지난주 보고서 보기'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('글자를 키우면 요약 세 칸의 값 줄이 줄어들어 칸 안에 들어간다', (tester) async {
    await pumpReport(
      tester,
      textScale: 1.6,
      size: OnoSurface.smallPhone,
      overview: bigWeek(),
    );

    // 값 줄은 FittedBox 로 감싸 두었다. 칸보다 넓어지면 줄여서 넣는다.
    final value = find.text('365일째');
    final box = find.ancestor(of: value, matching: find.byType(FittedBox));
    expect(box, findsOneWidget);
    final cell = tester.getRect(box);
    final text = tester.getRect(value);
    expect(text.right, lessThanOrEqualTo(cell.right + 0.5));
  });
}
