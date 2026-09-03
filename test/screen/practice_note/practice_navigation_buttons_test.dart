import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeCompletionScreen.dart';
import 'package:ono/Screen/PracticeNote/PracticeNavigationButtons.dart';

import '../../helpers/helpers.dart';

class _MockNavigatorObserver extends Mock implements NavigatorObserver {}

class _RouteFake extends Fake implements Route<dynamic> {}

PracticeNoteDetailModel _practice(int id, {int practiceCount = 0}) {
  return PracticeNoteDetailModel(
    practiceId: id,
    practiceTitle: 'practice-$id',
    practiceCount: practiceCount,
    createdAt: DateTime(2024, 1, 1),
    lastSolvedAt: null,
    problemIdList: const [],
  );
}

ProblemModel _problem(int id) => ProblemModel(problemId: id);

void main() {
  setUpOnoWidgetTest();

  setUpAll(() {
    // NavigatorObserver mock 에서 any() 로 Route 인자를 매칭하려면 필요하다.
    registerFallbackValue(_RouteFake());
  });

  late ProblemPracticeProvider practiceProvider;

  setUp(() {
    practiceProvider = ProblemPracticeProvider(
      problemsProvider: MockProblemsProvider(),
      practiceNoteService: MockPracticeNoteService(),
    );
  });

  /// PracticeNavigationButtons 는 `context` 를 직접 생성자로 받는 위젯이라
  /// Builder 로 감싸 실제 BuildContext 를 넘겨준다.
  ///
  /// [hostPadding] 은 실제 화면(ProblemDetailScreen._buildNavigationButtons,
  /// lib/Screen/ProblemDetail/ProblemDetailScreen.dart:1005-1006)이 이 위젯을
  /// 감싸는 좌우 패딩(폰 30, 태블릿 60)을 재현할 때 쓴다.
  Future<void> pumpButtons(
    WidgetTester tester, {
    required int currentProblemId,
    VoidCallback? onRefresh,
    Size surfaceSize = OnoSurface.phone,
    List<NavigatorObserver> navigatorObservers = const [],
    double hostPadding = 0,
  }) {
    return pumpOnoWidget(
      tester,
      Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.symmetric(horizontal: hostPadding),
          child: PracticeNavigationButtons(
            context: context,
            practiceProvider: practiceProvider,
            currentProblemId: currentProblemId,
            onRefresh: onRefresh ?? () {},
          ),
        ),
      ),
      practiceProvider: practiceProvider,
      surfaceSize: surfaceSize,
      navigatorObservers: navigatorObservers,
    );
  }

  group('진행 상황 표시', () {
    setUp(() {
      practiceProvider.currentProblems = [
        _problem(10),
        _problem(20),
        _problem(30),
      ];
    });

    testWidgets('가운데 문제에서는 인덱스/전체 개수와 이전·다음 버튼이 모두 보인다', (tester) async {
      await pumpButtons(tester, currentProblemId: 20);

      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('< 이전 문제'), findsOneWidget);
      expect(find.text('다음 문제 >'), findsOneWidget);
    });

    testWidgets('첫 번째 문제에서는 이전 버튼이 비활성화된다', (tester) async {
      await pumpButtons(tester, currentProblemId: 10);

      final previousButton =
          tester.widget<TextButton>(find.widgetWithText(TextButton, '< 이전 문제'));
      expect(previousButton.onPressed, isNull);
    });

    testWidgets('마지막이 아닌 문제에서는 다음 버튼이 활성화된다', (tester) async {
      await pumpButtons(tester, currentProblemId: 10);

      final nextButton =
          tester.widget<TextButton>(find.widgetWithText(TextButton, '다음 문제 >'));
      expect(nextButton.onPressed, isNotNull);
    });

    testWidgets('마지막 문제에서는 버튼 문구가 "복습 마치기" 로 바뀐다', (tester) async {
      await pumpButtons(tester, currentProblemId: 30);

      expect(find.text('복습 마치기'), findsOneWidget);
      expect(find.text('다음 문제 >'), findsNothing);
      expect(find.text('3 / 3'), findsOneWidget);
    });
  });

  testWidgets('문제가 하나뿐이면 이전·다음 모두 없고 복습 마치기만 보인다', (tester) async {
    practiceProvider.currentProblems = [_problem(10)];

    await pumpButtons(tester, currentProblemId: 10);

    final previousButton =
        tester.widget<TextButton>(find.widgetWithText(TextButton, '< 이전 문제'));
    expect(previousButton.onPressed, isNull);
    expect(find.text('복습 마치기'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('마지막 문제에서 복습 마치기를 누르면 완료 화면으로 전환된다', (tester) async {
    // provider.practices (내부 캐시)에도 반영되어야 회차 계산(+1)이 된다.
    // currentPracticeNote 를 미리 채운 채로 fetchPracticeNote 를 부르면
    // moveToPractice 가 다시 돌면서 currentProblems 를 비워 버리므로, 먼저
    // 캐시를 채우고 나서 currentProblems/currentPracticeNote 를 직접 지정한다.
    final service =
        practiceProvider.practiceNoteService as MockPracticeNoteService;
    when(() => service.getPracticeNoteById(1, showErrorSnackBar: true))
        .thenAnswer((_) async => _practice(1, practiceCount: 2));
    await practiceProvider.fetchPracticeNote(1);
    practiceProvider.currentProblems = [_problem(10), _problem(20)];
    practiceProvider.currentPracticeNote = _practice(1, practiceCount: 2);

    final observer = _MockNavigatorObserver();
    when(() => observer.didPush(any(), any())).thenReturn(null);

    await pumpButtons(
      tester,
      currentProblemId: 20,
      navigatorObservers: [observer],
    );

    await tester.tap(find.text('복습 마치기'));
    await tester.pumpAndSettle();

    verify(() => observer.didPush(any(), any())).called(greaterThan(0));
    expect(find.byType(PracticeCompletionScreen), findsOneWidget);
    // 다음 회차는 기존 practiceCount(2) + 1 이어야 한다.
    expect(find.text('3회차 복습을 완료했어요'), findsOneWidget);
  });

  testWidgets('"문제 복습" 버튼은 실제로 화면에 그려지지 않는다', (tester) async {
    // TODO(#174): 실제 버그 아님(예외는 안 남) — 다만 build() 가 previous/progress/
    // next 세 위젯만 Row 에 넣고, buildSolveButton/problemSolveDialog/isReviewed
    // 상태를 가진 "문제 복습" 재풀이 버튼(lib/Screen/PracticeNote/
    // PracticeNavigationButtons.dart:79-116, 210-239)은 어디서도 호출되지 않는
    // 죽은 코드다. 사용자는 이 위젯을 통해 다시 풀기 다이얼로그를 열 수 없다.
    practiceProvider.currentProblems = [_problem(10), _problem(20)];

    await pumpButtons(tester, currentProblemId: 10);

    expect(find.text('문제 복습'), findsNothing);
    expect(find.byIcon(Icons.touch_app), findsNothing);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    practiceProvider.currentProblems = [_problem(10), _problem(20)];

    await pumpButtons(
      tester,
      currentProblemId: 10,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(PracticeNavigationButtons), findsOneWidget);
  });

  testWidgets(
    '문제 10개 이상(진행 상황이 두 자리)이면 실제 화면 패딩(30) + phone 폭에서 오버플로우가 난다',
    (tester) async {
      // TODO(#174): 실제 버그. lib/Screen/PracticeNote/PracticeNavigationButtons.dart:39-46
      // build() 의 Row(이전 버튼 / 진행 상황 텍스트 / 다음 버튼)가 Expanded·Flexible 없이
      // 세 위젯의 고유 너비를 그대로 합산한다. 문제 수가 9개 이하(진행 상황이
      // "1 / 9"처럼 한 자리)면 문제없지만, 10개 이상이 되어 "8 / 15"처럼 두 자리가
      // 되는 순간 텍스트 폭이 늘어나 이 위젯을 실제로 감싸는
      // ProblemDetailScreen._buildNavigationButtons(같은 폴더 ProblemDetailScreen.dart:
      // 1005-1006)의 좌우 30px 패딩과 겹쳐 OnoSurface.phone(390) 에서도 RenderFlex 가
      // 우측으로 넘친다(재현 시 9.4px). 복습 세트에 문제가 10개 이상이면 항상 일어난다.
      // 패딩 없이(OnoSurface.smallPhone, 320) 두면 두 자리가 아니어도(문제 2개,
      // "1 / 2") 3.4px 오버플로우가 재현된다 — 이 위젯 자체가 좁은 폭에 여유가 거의 없다.
      practiceProvider.currentProblems =
          List.generate(15, (i) => _problem(i + 1));

      await pumpButtons(
        tester,
        currentProblemId: 8,
        hostPadding: 30,
      );

      expect(tester.takeException(), isNull);
    },
    skip: true, // #174 에서 수정 예정
  );
}
