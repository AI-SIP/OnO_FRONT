import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Model/Problem/ImprovementType.dart';
import 'package:ono/Model/Problem/ProblemSolveUpdateDto.dart';
import 'package:ono/Screen/ProblemDetail/Widget/RepeatSectionV2.dart';

import '../../helpers/helpers.dart';
import 'problem_detail_fixtures.dart';
import 'review_trend_panel_test.dart' show buildSolves;

/// 서비스를 넘기지 않으면 RepeatSectionV2 는 실제 `ProblemSolveService` 를
/// 만든다. flutter_test 환경은 dart:io HttpClient 요청을 곧바로 가짜 400 으로
/// 돌려주므로, 서비스를 넘기지 않은 테스트는 항상 에러 상태로 끝난다.
///
/// 복습 기록이 있을 때의 목록과 추이 판은 `service:` 로 mock 을 넣어 본다.
void main() {
  setUpOnoWidgetTest();

  testWidgets('네트워크 요청이 실패하면 에러 문구를 보여준다', (tester) async {
    final problem = buildProblem();

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: RepeatSectionV2(
          problem: problem,
          iconColor: Colors.pink,
          isWide: false,
        ),
      ),
      settle: false,
    );

    for (var i = 0;
        i < 50 && find.text('복습 기록을 불러오지 못했어요').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('복습 기록을 불러오지 못했어요'), findsOneWidget);
  });

  testWidgets('buildRepeatSectionV2 헬퍼로 띄워도 예외 없이 그려진다', (tester) async {
    final problem = buildProblem();

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: buildRepeatSectionV2(context, problem, Colors.pink, false),
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    final problem = buildProblem();

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: RepeatSectionV2(
          problem: problem,
          iconColor: Colors.pink,
          isWide: true,
        ),
      ),
      surfaceSize: OnoSurface.tablet,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets('refreshSignal 이 바뀌어도 예외 없이 다시 요청한다', (tester) async {
    final problem = buildProblem();

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: RepeatSectionV2(
          problem: problem,
          iconColor: Colors.pink,
          isWide: false,
          refreshSignal: 0,
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: RepeatSectionV2(
          problem: problem,
          iconColor: Colors.pink,
          isWide: false,
          refreshSignal: 1,
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  group('복습 기록이 있을 때', () {
    late MockProblemSolveService service;

    // 테스트 글꼴은 글자마다 정사각형이라 실제 Pretendard 보다 훨씬 넓다. 390 폭에서는
    // 기존 카드의 날짜 줄('2026년 09월 01일 20:00')이 테스트에서만 넘쳐서, 폰
    // 배치(isWide: false)는 그대로 두고 화면 폭만 넓힌다.
    const phoneSurface = Size(500, 900);

    setUpAll(() {
      registerFallbackValue(ProblemSolveUpdateDto(
          problemSolveId: 0,
          answerStatus: AnswerStatus.CORRECT,
          improvements: const []));
    });

    setUp(() {
      service = MockProblemSolveService();
      // 서버는 최신순으로 보낸다.
      final solves = buildSolves([
        AnswerStatus.WRONG,
        AnswerStatus.PARTIAL,
        AnswerStatus.CORRECT,
        AnswerStatus.CORRECT,
        AnswerStatus.CORRECT,
      ]).reversed.toList();
      when(() => service.getProblemSolvesByProblemId(any()))
          .thenAnswer((_) async => solves);
    });

    testWidgets('폰에서는 추이 카드 아래에 최근 복습부터 카드가 이어진다', (tester) async {
      await pumpOnoWidget(
        tester,
        Scaffold(
          body: RepeatSectionV2(
            problem: buildProblem(),
            iconColor: Colors.pink,
            isWide: false,
            service: service,
          ),
        ),
        surfaceSize: phoneSurface,
      );

      expect(find.text('복습 흐름'), findsOneWidget);
      expect(find.text('3연속 정답'), findsOneWidget);
      // 회차 번호는 오래된 기록이 1회차지만 목록은 최근 복습이 위다. 가장
      // 최근 회차는 펼친 채로 시작해서 4회차는 아래로 내려야 보인다.
      expect(find.text('5회차'), findsOneWidget);
      expect(find.text('4회차'), findsNothing);
      // 아래로 내려서(양수 delta) 찾으면 5회차 아래에 있다는 뜻이다.
      await tester.scrollUntilVisible(find.text('4회차'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('4회차'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('결과 고치기로 정오만 바꾸고 나머지 값은 그대로 보낸다', (tester) async {
      when(() => service.updateProblemSolve(any())).thenAnswer((_) async {});
      await pumpOnoWidget(
        tester,
        Scaffold(
          body: RepeatSectionV2(
            problem: buildProblem(),
            iconColor: Colors.pink,
            isWide: false,
            service: service,
          ),
        ),
        surfaceSize: phoneSurface,
      );

      // 맨 위 카드는 가장 최근인 5회차(정답)다.
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('결과 고치기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('오답').last);
      await tester.pumpAndSettle();

      final sent = verify(() => service.updateProblemSolve(captureAny()))
          .captured
          .single as ProblemSolveUpdateDto;
      expect(sent.problemSolveId, 5);
      expect(sent.answerStatus, AnswerStatus.WRONG);
      expect(sent.reflection, '4회차 메모', reason: 'PATCH 는 전체 교체라 빼면 지워진다');
      expect(sent.improvements, [ImprovementType.NO_REPEAT_MISTAKE]);
      expect(sent.timeSpentSeconds, 740);
    });

    testWidgets('추이 카드 위에서 위로 밀어도 목록이 스크롤된다', (tester) async {
      await pumpOnoWidget(
        tester,
        Scaffold(
          body: RepeatSectionV2(
            problem: buildProblem(),
            iconColor: Colors.pink,
            isWide: false,
            service: service,
          ),
        ),
        surfaceSize: phoneSurface,
      );

      final list = find.byType(Scrollable).first;
      expect(tester.state<ScrollableState>(list).position.pixels, 0);

      await tester.drag(find.text('풀이 시간'), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(
        tester.state<ScrollableState>(list).position.pixels,
        greaterThan(100),
      );
    });

    testWidgets('복습 흐름의 동그라미를 누르면 그 회차 카드가 펼쳐진다', (tester) async {
      await pumpOnoWidget(
        tester,
        Scaffold(
          body: RepeatSectionV2(
            problem: buildProblem(),
            iconColor: Colors.pink,
            isWide: false,
            service: service,
          ),
        ),
        surfaceSize: phoneSurface,
      );
      expect(find.text('0회차 메모'), findsNothing);

      await tester.tap(find.bySemanticsLabel(RegExp(r'^1회차 오답')));
      await tester.pumpAndSettle();

      expect(find.text('0회차 메모'), findsOneWidget);
      expect(find.text('0회차 메모').hitTestable(), findsOneWidget);
    });

    testWidgets('태블릿에서 동그라미를 누르면 오른쪽 상세가 그 회차로 바뀐다', (tester) async {
      await pumpOnoWidget(
        tester,
        Scaffold(
          body: RepeatSectionV2(
            problem: buildProblem(),
            iconColor: Colors.pink,
            isWide: true,
            service: service,
          ),
        ),
        surfaceSize: const Size(1194, 834),
      );
      // 처음에는 가장 최근 기록을 고른다.
      expect(find.text('4회차 메모'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(RegExp(r'^3회차 정답')));
      await tester.pumpAndSettle();

      expect(find.text('2회차 메모'), findsOneWidget);
      expect(find.text('4회차 메모'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
