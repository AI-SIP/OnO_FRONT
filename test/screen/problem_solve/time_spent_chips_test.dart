// 소요 시간 조절 칩이 어디에 서는지 본다.
//
// 태블릿에서 칩 묶음이 오른쪽 끝이 아니라 화면 가운데쯤에 서고 그 오른쪽이
// 통째로 비어 있었다. 시간 글자를 Flexible 로 둬서 제 몫을 다 쓰지 않았고,
// 뒤따르는 칩 묶음이 배정받은 폭 그대로 글자 바로 뒤에 놓였기 때문이다.
// 834 폭에서 줄은 54 부터 784 까지인데 칩은 465 에서 끝났다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Screen/ProblemSolve/ProblemSolveRegisterTemplate.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  late ProblemsProvider problemsProvider;

  setUp(() {
    final problemService = MockProblemService();
    when(() => problemService.getProblem(any())).thenAnswer(
      (_) async => ProblemModel(problemId: 1),
    );
    problemsProvider = ProblemsProvider(problemService: problemService);
  });

  for (final entry in <String, Size>{
    '폰': OnoSurface.phone,
    '태블릿': OnoSurface.tablet,
  }.entries) {
    testWidgets('${entry.key}에서 조절 칩이 소요 시간 줄의 오른쪽 끝에 붙는다', (tester) async {
      await withMockedNetworkImages(() async {
        await pumpOnoWidget(
          tester,
          Scaffold(body: ProblemSolveRegisterTemplate(problemId: 1)),
          problemsProvider: problemsProvider,
          surfaceSize: entry.value,
          settle: false,
        );
      });
      await tester.pump(const Duration(milliseconds: 300));

      final row = find.ancestor(
        of: find.byType(Wrap).first,
        matching: find.byType(Row),
      );
      final rowRight = tester.getRect(row.first).right;
      final lastChipRight = tester.getRect(find.text('+10초')).right;

      // 칩 상자에 테두리와 여백이 있어서 글자 기준으로는 줄 끝보다 몇 픽셀
      // 안쪽이다. 그 몫만 열어 둔다.
      expect(
        lastChipRight,
        greaterThan(rowRight - 40),
        reason: '${entry.key}: 칩이 오른쪽 끝에서 '
            '${(rowRight - lastChipRight).toStringAsFixed(1)} 만큼 떨어져 있다',
      );
    });
  }
}
