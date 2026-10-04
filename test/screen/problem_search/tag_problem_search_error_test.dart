import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Screen/ProblemSearch/TagProblemSearchScreen.dart';

import '../../helpers/helpers.dart';

/// 검색이 실패하면 결과가 없다는 화면이 아니라 다시 시도를 보이는지 본다.
///
/// 예전에는 catch 가 없어서 네트워크 오류도 `검색 결과가 없습니다` 로 보였다.
void main() {
  setUpOnoWidgetTest();

  late MockProblemService problemService;
  late ProblemsProvider problemsProvider;

  setUp(() {
    problemService = MockProblemService();
    problemsProvider = ProblemsProvider(problemService: problemService);
  });

  testWidgets('제목 검색이 실패하면 다시 시도를 보이고, 다시 시도하면 결과를 보인다', (tester) async {
    var calls = 0;
    when(() => problemService.getTitleProblemsV2(
          query: any(named: 'query'),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw Exception('네트워크');
      return PaginatedResponse<ProblemModel>(
        content: [ProblemModel(problemId: 1, reference: '이차함수 최댓값')],
        nextCursor: null,
        hasNext: false,
        size: 20,
      );
    });

    await pumpOnoWidget(
      tester,
      const TagProblemSearchScreen(),
      problemsProvider: problemsProvider,
    );

    await tester.tap(find.text('제목으로 검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '이차');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('오답노트를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('검색 결과가 없습니다.'), findsNothing);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('오답노트를 불러오지 못했어요'), findsNothing);
    expect(find.text('이차함수 최댓값'), findsOneWidget);
  });

  testWidgets('제목 검색으로 열리고 바로 입력할 수 있으며 결과에 공책 이름을 붙인다', (tester) async {
    when(() => problemService.getTitleProblemsV2(
          query: any(named: 'query'),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => PaginatedResponse<ProblemModel>(
          content: [
            ProblemModel(problemId: 1, reference: '이차함수 최댓값', folderId: 7),
          ],
          nextCursor: null,
          hasNext: false,
          size: 20,
        ));
    final foldersProvider = FoldersProvider(problemsProvider: problemsProvider);

    await pumpOnoWidget(
      tester,
      const TagProblemSearchScreen(),
      problemsProvider: problemsProvider,
      foldersProvider: foldersProvider,
    );
    // 태그 목록을 받다 인증 실패로 캐시가 비워질 수 있어서 화면이 뜬 뒤에 넣는다.
    foldersProvider.saveSubfoldersToCache(
      1,
      [FolderThumbnailModel(folderId: 7, folderName: '수학 1', problemCount: 1)],
      null,
      false,
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofocus, isTrue);

    await tester.enterText(find.byType(TextField), '이차');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('이차함수 최댓값'), findsOneWidget);
    expect(find.text('수학 1'), findsOneWidget);
  });
}
