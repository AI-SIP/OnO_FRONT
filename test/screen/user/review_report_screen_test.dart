import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/LearningReport/LearningOverviewModel.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Module/Motion/TossPageRoute.dart';
import 'package:ono/Provider/ReviewDueProvider.dart';
import 'package:ono/Screen/Folder/DirectoryScreen.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';
import 'package:ono/Screen/User/Widget/LearningReport/ReviewDueCard.dart';
import 'package:ono/Screen/User/Widget/ReviewReportScreen.dart';
import 'package:ono/Util/AppClock.dart';

import '../../helpers/helpers.dart';

/// 화면에 올린 라우트를 모아 둔다. 올라간 화면을 실제로 그리면 그 화면이
/// 네트워크를 타서, 라우트의 builder 로 어떤 화면을 열려고 했는지만 본다.
class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    pushed.add(route);
  }
}

/// 학습 보고서 화면. 오늘은 2026년 10월 8일 목요일로 고정한다.
void main() {
  setUpOnoWidgetTest();

  setUpAll(() {
    registerFallbackValue(LearningOverviewPeriod.week);
  });

  late MockLearningReportService reportService;
  late MockProblemService problemService;

  /// 화면 전체가 한 번에 보이는 높이. 아래쪽 카드도 눌러 볼 수 있다.
  const tallPhone = Size(390, 2400);

  LearningOverviewModel fixture(String name) => LearningOverviewModel.fromJson(
        loadJsonFixture('learning_report/learning_overview_$name.json'),
      );

  ReviewDueResponse dueResponse(int count) => ReviewDueResponse(
        dueCount: count,
        overdueCount: 0,
        problems: [
          for (var i = 0; i < count; i++)
            ReviewDueProblemModel(
              problemId: 100 + i,
              // 목록은 예정일 오름차순이다. 맨 앞이 9일 밀렸다.
              nextReviewAt: DateTime(2026, 9, 29 + i),
              reviewInterval: 1,
              consecutiveCorrectCount: 0,
            ),
        ],
      );

  setUp(() {
    AppClock.setForTest(() => DateTime(2026, 10, 8, 10));
    reportService = MockLearningReportService();
    problemService = MockProblemService();
    when(() => problemService.getReviewDueProblems())
        .thenAnswer((_) async => dueResponse(5));
    when(() => reportService.getOverview(
          period: any(named: 'period'),
          baseDate: any(named: 'baseDate'),
        )).thenAnswer((_) async => fixture('week'));
  });

  tearDown(AppClock.resetForTest);

  void answerOverview(
    LearningOverviewModel overview, {
    LearningOverviewPeriod period = LearningOverviewPeriod.week,
  }) {
    when(() => reportService.getOverview(
          period: any(named: 'period', that: equals(period)),
          baseDate: any(named: 'baseDate'),
        )).thenAnswer((_) async => overview);
  }

  Future<_RecordingNavigatorObserver> pumpReport(
    WidgetTester tester, {
    Size size = tallPhone,
  }) async {
    final observer = _RecordingNavigatorObserver();
    await pumpOnoWidget(
      tester,
      ReviewReportScreen(reportService: reportService),
      reviewDueProvider: ReviewDueProvider(problemService: problemService),
      navigatorObservers: [observer],
      surfaceSize: size,
    );
    return observer;
  }

  /// 올라간 라우트가 그릴 화면. 그리지 않고 만들기만 한다.
  Widget pushedScreen(WidgetTester tester, Route<dynamic> route) {
    final context = tester.element(find.byType(ReviewReportScreen));
    return (route as TossPageRoute).builder(context);
  }

  group('기록이 있는 주', () {
    testWidgets('다섯 칸이 다 보인다', (tester) async {
      await pumpReport(tester);

      expect(find.text('학습 보고서'), findsOneWidget);
      // 요약
      expect(find.text('10월 5일 ~ 10월 11일'), findsOneWidget);
      expect(find.text('이번 주에'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('지난주보다 5문제 더 풀었어요'), findsOneWidget);
      expect(find.text('64%'), findsOneWidget);
      expect(find.text('+8%p'), findsOneWidget);
      expect(find.text('4일'), findsOneWidget);
      expect(find.text('+1일'), findsOneWidget);
      expect(find.text('5일째'), findsOneWidget);
      // 오답노트 상태
      expect(find.text('오답노트 상태'), findsOneWidget);
      // 큰 숫자와 확실히 아는 문제 줄의 개수.
      expect(find.text('21'), findsNWidgets(2));
      expect(find.text('/ 86문제 확실히 알아요'), findsOneWidget);
      expect(find.text('연달아 3번 맞힌 문제'), findsOneWidget);
      expect(find.text('맞혔다 틀렸다 하는 문제'), findsOneWidget);
      expect(find.text('등록만 하고 아직 안 푼 문제'), findsOneWidget);
      expect(
        find.text('이번 주에 3문제가 확실히 아는 문제가 됐어요', findRichText: true),
        findsOneWidget,
      );
      // 오늘 복습할 문제
      expect(find.text('오늘 복습할 문제 5개'), findsOneWidget);
      expect(find.text('9일째 밀린 문제도 있어요'), findsOneWidget);
      expect(find.text('복습하기'), findsOneWidget);
      // 자주 틀린 폴더
      expect(find.text('자주 틀린 폴더'), findsOneWidget);
      expect(find.text('이차함수'), findsOneWidget);
      expect(find.text('6번 틀렸어요'), findsOneWidget);
      expect(find.text('38%'), findsOneWidget);
      // 요일별 복습
      expect(find.text('요일별 복습'), findsOneWidget);
      expect(find.text('하루 평균 3.5문제'), findsOneWidget);
      expect(find.text('오늘'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('다음 화살표는 이번 주에서 꺼져 있다', (tester) async {
      await pumpReport(tester);

      final next = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
      );
      final previous = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
      );
      expect(next.onPressed, isNull);
      expect(previous.onPressed, isNotNull);
    });

    testWidgets('이전 화살표는 지난주 안의 날로 다시 부른다', (tester) async {
      await pumpReport(tester);
      final pastWeek = LearningOverviewModel.fromJson({
        ...loadJsonFixture('learning_report/learning_overview_week.json'),
        'startDate': '2026-09-28',
        'endDate': '2026-10-04',
        'hasNext': true,
      });
      when(() => reportService.getOverview(
            period: any(
              named: 'period',
              that: equals(LearningOverviewPeriod.week),
            ),
            baseDate:
                any(named: 'baseDate', that: equals(DateTime(2026, 10, 4))),
          )).thenAnswer((_) async => pastWeek);

      await tester.tap(find.byTooltip('이전 주'));
      await tester.pumpAndSettle();

      verify(() => reportService.getOverview(
            period: any(
              named: 'period',
              that: equals(LearningOverviewPeriod.week),
            ),
            baseDate:
                any(named: 'baseDate', that: equals(DateTime(2026, 10, 4))),
          )).called(1);
      expect(find.text('9월 28일 ~ 10월 4일'), findsOneWidget);
      // 넘겨 본 주에서는 `이번 주` 라고 쓰지 않는다.
      expect(find.text('이 주에'), findsOneWidget);
      expect(find.text('전 주보다 5문제 더 풀었어요'), findsOneWidget);

      final next = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
      );
      expect(next.onPressed, isNotNull);
    });

    testWidgets('탭을 바꾸면 그 기간으로 부르고, 돌아오면 받아 둔 것을 쓴다', (tester) async {
      await pumpReport(tester);
      answerOverview(fixture('total'), period: LearningOverviewPeriod.month);

      await tester.tap(find.text('월간'));
      await tester.pumpAndSettle();

      verify(() => reportService.getOverview(
            period: any(
              named: 'period',
              that: equals(LearningOverviewPeriod.month),
            ),
            baseDate: any(named: 'baseDate', that: isNull),
          )).called(1);

      await tester.tap(find.text('주간'));
      await tester.pumpAndSettle();

      // 처음 연 한 번뿐이다.
      verify(() => reportService.getOverview(
            period: any(
              named: 'period',
              that: equals(LearningOverviewPeriod.week),
            ),
            baseDate: any(named: 'baseDate', that: isNull),
          )).called(1);
      expect(find.text('이번 주에'), findsOneWidget);
    });

    testWidgets('세그먼트를 바꾸면 기존 값 그대로 period 를 남긴다', (tester) async {
      await pumpReport(tester);
      final before = analyticsRecorder.loggedEvents.length;

      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle();

      final index =
          analyticsRecorder.loggedEvents.indexOf('report_period_view', before);
      expect(index, isNot(-1));
      expect(analyticsRecorder.loggedParameters[index], {'period': 'total'});
    });

    testWidgets('복습하기는 추천 목록 순서대로 문제 상세를 연다', (tester) async {
      final observer = await pumpReport(tester);
      final before = observer.pushed.length;

      // 누른 뒤 다음 프레임을 그리면 문제 상세가 실제로 빌드되며 네트워크를
      // 타므로 pump 하지 않는다.
      await tester.tap(find.text('복습하기'));

      expect(observer.pushed.length, before + 1);
      final screen = pushedScreen(tester, observer.pushed.last);
      expect(screen, isA<ProblemDetailScreen>());
      screen as ProblemDetailScreen;
      expect(screen.problemId, 100);
      expect(screen.reviewQueue, [100, 101, 102, 103, 104]);

      final index = analyticsRecorder.loggedEvents.lastIndexOf(
        'review_due_start',
      );
      expect(
        analyticsRecorder.loggedParameters[index],
        {'count': 5, 'source': 'report'},
      );
    });

    testWidgets('자주 틀린 폴더 줄은 그 폴더를 연다', (tester) async {
      final observer = await pumpReport(tester);
      final before = observer.pushed.length;

      await tester.tap(find.text('확률과 통계'));

      expect(observer.pushed.length, before + 1);
      final screen = pushedScreen(tester, observer.pushed.last);
      expect(screen, isA<DirectoryScreen>());
      expect((screen as DirectoryScreen).folderId, 7);

      final index = analyticsRecorder.loggedEvents.lastIndexOf(
        'report_folder_tap',
      );
      expect(analyticsRecorder.loggedParameters[index], {'rank': 2});
    });
  });

  group('기록이 없는 주', () {
    testWidgets('빈 화면 문구와 복습하기가 보이고 폴더와 막대는 숨는다', (tester) async {
      answerOverview(fixture('empty'));
      await pumpReport(tester);

      expect(find.text('이번 주는 아직\n복습을 안 했어요'), findsOneWidget);
      expect(
        find.text('오늘 복습할 문제가 5개 있어요', findRichText: true),
        findsOneWidget,
      );
      // 같은 버튼이 두 번 나오지 않게 오늘 복습할 문제 카드는 숨긴다.
      expect(find.text('복습하기'), findsOneWidget);
      expect(find.byType(ReviewDueCard), findsNothing);

      expect(find.text('오답노트 상태'), findsOneWidget);
      expect(find.text('자주 틀린 폴더'), findsNothing);
      expect(find.text('요일별 복습'), findsNothing);
      expect(find.text('지난주 보고서 보기'), findsOneWidget);
      expect(find.text('9월 28일 ~ 10월 4일'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('오늘 복습할 문제가 없으면 버튼 없이 없다고 쓴다', (tester) async {
      answerOverview(fixture('empty'));
      when(() => problemService.getReviewDueProblems())
          .thenAnswer((_) async => dueResponse(0));
      await pumpReport(tester);

      expect(find.text('오늘 복습할 문제는 없어요'), findsOneWidget);
      expect(find.text('복습하기'), findsNothing);
    });

    testWidgets('지난 주를 보고 있으면 복습하기를 넣지 않는다', (tester) async {
      answerOverview(LearningOverviewModel.fromJson({
        ...loadJsonFixture('learning_report/learning_overview_empty.json'),
        'hasNext': true,
      }));
      await pumpReport(tester);

      expect(find.text('이 주에는 복습한 기록이 없어요'), findsOneWidget);
      expect(
        find.text('오늘 복습할 문제가 5개 있어요', findRichText: true),
        findsNothing,
      );
      expect(find.text('전 주 보고서 보기'), findsOneWidget);
    });

    testWidgets('지난주 보고서 보기를 누르면 지난주를 부른다', (tester) async {
      answerOverview(fixture('empty'));
      await pumpReport(tester);

      await tester.tap(find.text('지난주 보고서 보기'));
      await tester.pumpAndSettle();

      verify(() => reportService.getOverview(
            period: any(
              named: 'period',
              that: equals(LearningOverviewPeriod.week),
            ),
            baseDate:
                any(named: 'baseDate', that: equals(DateTime(2026, 10, 4))),
          )).called(1);
    });
  });

  testWidgets('전체는 화살표와 지난 기간 비교가 없다', (tester) async {
    answerOverview(fixture('total'), period: LearningOverviewPeriod.total);
    await pumpReport(tester);

    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();

    expect(find.text('지금까지'), findsOneWidget);
    expect(find.text('312'), findsOneWidget);
    expect(find.byTooltip('이전 주'), findsNothing);
    expect(find.textContaining('보다'), findsNothing);
    expect(find.textContaining('%p'), findsNothing);
    expect(find.text('월별 복습'), findsOneWidget);
    expect(find.text('한 달 평균 48문제'), findsOneWidget);
    // 지금까지 알게 된 수는 위 숫자와 같아서 따로 적지 않는다.
    expect(
      find.textContaining('확실히 아는 문제가 됐어요', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('오답노트가 없으면 상태 카드 대신 한 줄만 둔다', (tester) async {
    answerOverview(LearningOverviewModel.fromJson({
      ...loadJsonFixture('learning_report/learning_overview_empty.json'),
      'noteStatus': {
        'totalCount': 0,
        'knownCount': 0,
        'unsureCount': 0,
        'unsolvedCount': 0,
        'newlyKnownCount': 0,
        'knownThreshold': 3,
      },
    }));
    await pumpReport(tester);

    expect(find.text('아직 등록한 오답노트가 없어요'), findsOneWidget);
    expect(find.text('오답노트 상태'), findsNothing);
  });

  testWidgets('불러오지 못하면 다시 시도할 수 있다', (tester) async {
    when(() => reportService.getOverview(
          period: any(named: 'period'),
          baseDate: any(named: 'baseDate'),
        )).thenThrow(Exception('서버 오류'));
    await pumpReport(tester);

    expect(find.text('보고서를 불러오지 못했어요'), findsOneWidget);

    answerOverview(fixture('week'));
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('이번 주에'), findsOneWidget);
  });

  group('오늘 복습할 문제 둘째 줄', () {
    final today = DateTime(2026, 10, 8, 10);

    test('밀린 날 수를 쓴다', () {
      expect(
        ReviewDueCard.subtitleFor(DateTime(2026, 9, 29, 23), today),
        '9일째 밀린 문제도 있어요',
      );
    });

    test('오늘이 예정일이면 차례라고 쓴다', () {
      expect(
        ReviewDueCard.subtitleFor(DateTime(2026, 10, 8), today),
        '오늘 복습할 차례예요',
      );
    });

    test('예정일을 모르면 줄을 비운다', () {
      expect(ReviewDueCard.subtitleFor(null, today), isNull);
    });
  });
}
