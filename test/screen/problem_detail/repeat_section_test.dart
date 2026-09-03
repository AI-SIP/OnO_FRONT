import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/Problem/ProblemImageDataModel.dart';
import 'package:ono/Module/Image/FullScreenImage.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Screen/ProblemDetail/Widget/RepeatSection.dart';

import '../../helpers/helpers.dart';
import 'problem_detail_fixtures.dart';

/// RepeatSection.dart 는 ProblemDetailScreenWidget 을 통해서만 참조되고
/// ProblemDetailScreenWidget 자체도 현재 화면 어디에서도 쓰이지 않는 죽은
/// 코드다 (RepeatSectionV2 로 대체됨). 그래도 "전부" 요구사항에 맞춰
/// builder 함수 자체는 검증한다.
void main() {
  setUpOnoWidgetTest();

  late MockProblemService problemService;
  late ProblemsProvider problemsProvider;

  setUp(() {
    problemService = MockProblemService();
    problemsProvider = ProblemsProvider(problemService: problemService);
  });

  Widget wrap(Widget child) => Builder(
        builder: (context) =>
            Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('복습 기록이 없으면 복습 횟수 0으로 보여준다', (tester) async {
    final problem = buildProblem(solveImages: const []);

    await pumpOnoWidget(
      tester,
      Builder(
        builder: (context) =>
            wrap(buildRepeatSection(context, problem, Colors.pink)),
      ),
      problemsProvider: problemsProvider,
    );

    expect(find.text('복습 횟수: 0'), findsOneWidget);
  });

  testWidgets('복습 기록이 있으면 개수와 날짜를 보여준다', (tester) async {
    final problem = buildProblem(solveImages: [
      ProblemImageDataModel(
        imageUrl: 'https://example.com/solve1.png',
        problemImageType: ProblemImageType.SOLVE_IMAGE,
        createdAt: DateTime(2026, 2, 1),
      ),
      ProblemImageDataModel(
        imageUrl: 'https://example.com/solve2.png',
        problemImageType: ProblemImageType.SOLVE_IMAGE,
        createdAt: DateTime(2026, 2, 5),
      ),
    ]);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) =>
              wrap(buildRepeatSection(context, problem, Colors.pink)),
        ),
        problemsProvider: problemsProvider,
      );
    });

    expect(find.text('복습 횟수: 2'), findsOneWidget);
    expect(find.textContaining('2026년 02월 01일'), findsOneWidget);
    expect(find.textContaining('2026년 02월 05일'), findsOneWidget);
  });

  testWidgets('이미지를 탭하면 전체화면으로 이동한다', (tester) async {
    final problem = buildProblem(solveImages: [
      ProblemImageDataModel(
        imageUrl: 'https://example.com/solve1.png',
        problemImageType: ProblemImageType.SOLVE_IMAGE,
        createdAt: DateTime(2026, 2, 1),
      ),
    ]);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) =>
              wrap(buildRepeatSection(context, problem, Colors.pink)),
        ),
        problemsProvider: problemsProvider,
      );

      tester
          .widget<GestureDetector>(find.byType(GestureDetector).first)
          .onTap!();
      // FullScreenImage 안의 CachedNetworkImage 로딩 인디케이터가 계속
      // 애니메이션하므로 pumpAndSettle 대신 직접 몇 프레임만 진행시킨다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FullScreenImage), findsOneWidget);
    });
  });

  testWidgets('길게 눌러 삭제를 취소하면 이미지가 그대로 남는다', (tester) async {
    final problem = buildProblem(solveImages: [
      ProblemImageDataModel(
        imageUrl: 'https://example.com/solve1.png',
        problemImageType: ProblemImageType.SOLVE_IMAGE,
        createdAt: DateTime(2026, 2, 1),
      ),
    ]);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) =>
              wrap(buildRepeatSection(context, problem, Colors.pink)),
        ),
        problemsProvider: problemsProvider,
      );

      tester
          .widget<GestureDetector>(find.byType(GestureDetector).first)
          .onLongPress!();
      await tester.pumpAndSettle();

      expect(find.text('이 복습 이미지를 정말 삭제하시겠습니까?'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(() => problemService.deleteProblemImageData(any()));
    });
  });

  testWidgets('길게 눌러 삭제를 확정하면 이미지 삭제와 새로고침이 호출된다', (tester) async {
    final problem = buildProblem(solveImages: [
      ProblemImageDataModel(
        imageUrl: 'https://example.com/solve1.png',
        problemImageType: ProblemImageType.SOLVE_IMAGE,
        createdAt: DateTime(2026, 2, 1),
      ),
    ]);
    when(() => problemService.deleteProblemImageData(any()))
        .thenAnswer((_) async {});
    when(() => problemService.getProblem(any(),
            showErrorSnackBar: any(named: 'showErrorSnackBar')))
        .thenAnswer((_) async => problem);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Builder(
          builder: (context) =>
              wrap(buildRepeatSection(context, problem, Colors.pink)),
        ),
        problemsProvider: problemsProvider,
      );

      tester
          .widget<GestureDetector>(find.byType(GestureDetector).first)
          .onLongPress!();
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      verify(() => problemService
          .deleteProblemImageData('https://example.com/solve1.png')).called(1);
    });
  });
}
