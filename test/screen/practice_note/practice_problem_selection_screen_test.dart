// PracticeProblemSelectionScreen(복습 문제 선택) 위젯 테스트.
//
// 폴더와 문제는 화면이 뜬 뒤 비동기로 불러온다. 그 사이 사용자가 화면을 나가면
// 늦게 온 응답이 dispose 된 State 에 setState 를 부른다. 디버그에서는 assert,
// 릴리스에서는 Null check 오류로 터져 Sentry 에 쌓였다 (#400).
//
// 그 오류는 로더의 catch 가 잡아 AppErrorReporter 로 보내고 삼킨다. 그래서
// 테스트는 예외 대신 "오류 보고가 남았는가" 를 본다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/ListSort.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Tag/TagModel.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeProblemSelectionScreen.dart';

import '../../helpers/helpers.dart';

PaginatedResponse<T> _page<T>(List<T> content) {
  return PaginatedResponse<T>(
    content: content,
    nextCursor: null,
    hasNext: false,
    size: 20,
  );
}

void main() {
  setUpOnoWidgetTest();
  setUpAll(() => registerFallbackValue(ListSort.newest));

  late MockFolderService folderService;
  late MockProblemService problemService;
  late MockTagService tagService;
  late ProblemsProvider problemsProvider;
  late FoldersProvider foldersProvider;

  setUp(() {
    folderService = MockFolderService();
    problemService = MockProblemService();
    tagService = MockTagService();
    problemsProvider = ProblemsProvider(problemService: problemService);
    foldersProvider = FoldersProvider(
      problemsProvider: problemsProvider,
      folderService: folderService,
    );
    when(() => tagService.getMyTags()).thenAnswer((_) async => <TagModel>[]);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await pumpOnoWidget(
      tester,
      PracticeProblemSelectionScreen(tagService: tagService),
      problemsProvider: problemsProvider,
      foldersProvider: foldersProvider,
      settle: false,
    );
    // 첫 프레임 뒤 콜백에서 불러오기를 시작한다.
    await tester.pump();
  }

  Future<void> leaveScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
  }

  /// [body] 동안 AppErrorReporter 가 남긴 로그 줄을 모은다.
  Future<List<String>> collectErrorReports(Future<void> Function() body) async {
    final reports = <String>[];
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.contains('[AppErrorReporter]')) {
        reports.add(message);
      }
    };
    try {
      await body();
    } finally {
      debugPrint = original;
    }
    return reports;
  }

  testWidgets('폴더를 불러오는 중에 화면을 나가면 늦게 온 응답을 버린다', (tester) async {
    final folders = Completer<PaginatedResponse<FolderThumbnailModel>>();
    when(() => folderService.getAllFolderThumbnailsV2(
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) => folders.future);

    await pumpScreen(tester);
    await leaveScreen(tester);

    final reports = await collectErrorReports(() async {
      folders.complete(_page([
        FolderThumbnailModel(folderId: 1, folderName: '수학'),
      ]));
      await tester.pump();
      await tester.pump();
    });

    expect(tester.takeException(), isNull);
    expect(reports, isEmpty);
    // 화면이 없으니 첫 폴더의 문제를 이어서 부르지도 않는다.
    verifyNever(() => problemService.getFolderProblemsV2(
          folderId: any(named: 'folderId'),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
          sort: any(named: 'sort'),
        ));
  });

  testWidgets('첫 폴더의 문제를 불러오는 중에 화면을 나가면 늦게 온 응답을 버린다', (tester) async {
    when(() => folderService.getAllFolderThumbnailsV2(
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => _page([
          FolderThumbnailModel(folderId: 1, folderName: '수학'),
        ]));
    final problems = Completer<PaginatedResponse<ProblemModel>>();
    when(() => problemService.getFolderProblemsV2(
          folderId: 1,
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
          sort: any(named: 'sort'),
        )).thenAnswer((_) => problems.future);

    await pumpScreen(tester);
    await tester.pump();

    // 폴더 응답을 받고 첫 폴더의 문제를 부르기 시작했다.
    verify(() => problemService.getFolderProblemsV2(
          folderId: 1,
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
          sort: any(named: 'sort'),
        )).called(1);

    await leaveScreen(tester);

    final reports = await collectErrorReports(() async {
      problems.complete(_page([
        ProblemModel(problemId: 10, createdAt: DateTime(2024, 1, 1)),
      ]));
      await tester.pump();
      await tester.pump();
    });

    expect(tester.takeException(), isNull);
    expect(reports, isEmpty);
  });
}
