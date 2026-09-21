// 책장(폴더) 화면 골든 테스트.
//
// 하위 폴더 둘과 문제 셋이 있는 책장을 뜬다.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Provider/ReviewDueProvider.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/Folder/DirectoryScreen.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

void main() {
  setUpOnoWidgetTest();

  // 문제 그림은 비워 둔다. 그림이 있으면 CachedNetworkImage 가 뜨는데, 골든을
  // 비교하는 동안 진짜 비동기가 흐르면서 캐시 폴더(path_provider)를 찾다가
  // MissingPluginException 으로 깨진다. 그림이 없으면 기본 그림(SVG)이 들어가서
  // 카드의 틀은 똑같이 잠긴다.
  ProblemModel problem(int id, String reference) {
    return ProblemModel(
      problemId: id,
      folderId: 1,
      reference: reference,
      solveCount: 2,
      problemImageDataList: const [],
    );
  }

  Future<Widget> buildApp() async {
    final userProvider = _FakeUserProvider();
    when(() => userProvider.isLoggedIn).thenReturn(LoginStatus.login);
    when(() => userProvider.addListener(any())).thenReturn(null);
    when(() => userProvider.removeListener(any())).thenReturn(null);
    when(() => userProvider.dispose()).thenReturn(null);

    final folderService = MockFolderService();
    final problemService = MockProblemService();

    final root = FolderModel(
      folderId: 1,
      folderName: '책장',
      problemIdList: const [],
      subFolderList: const [],
    );
    when(() => folderService.getRootFolder()).thenAnswer((_) async => root);
    when(() => folderService.fetchFolder(any(),
            showErrorSnackBar: any(named: 'showErrorSnackBar')))
        .thenAnswer((_) async => root);

    final subfolders = [
      FolderThumbnailModel(folderId: 10, folderName: '수학', problemCount: 3),
      FolderThumbnailModel(folderId: 11, folderName: '영어', problemCount: 12),
    ];
    when(() => folderService.getSubfoldersV2(
          folderId: any(named: 'folderId'),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => PaginatedResponse(
          content: subfolders,
          nextCursor: null,
          hasNext: false,
          size: subfolders.length,
        ));

    final problems = [
      problem(100, '수학 문제집 p.12'),
      problem(101, '모의고사 21번'),
      problem(102, '단어 시험'),
    ];
    when(() => problemService.getFolderProblemsV2(
          folderId: any(named: 'folderId'),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => PaginatedResponse(
          content: problems,
          nextCursor: null,
          hasNext: false,
          size: problems.length,
        ));
    when(() => problemService.getReviewDueProblems()).thenAnswer(
      (_) async =>
          ReviewDueResponse(dueCount: 0, overdueCount: 0, problems: []),
    );

    final problemsProvider = ProblemsProvider(problemService: problemService);
    return buildOnoApp(
      const DirectoryScreen(),
      cosmeticProvider: await loadedCosmeticProvider(),
      userProvider: userProvider,
      problemsProvider: problemsProvider,
      foldersProvider: FoldersProvider(
        problemsProvider: problemsProvider,
        folderService: folderService,
      ),
      reviewDueProvider: ReviewDueProvider(problemService: problemService),
    );
  }

  screenGoldenTest(
    '책장 화면',
    fileName: 'directory_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: buildApp,
  );

  // 공책을 꾹 눌러 다른 공책 위로 끌고 간 순간. 손에 붙은 카드와 놓을 자리의
  // 강조가 함께 잠긴다. 손가락은 떼지 않은 채로 찍는다.
  screenGoldenTest(
    '책장 화면 (공책을 끄는 중)',
    fileName: 'directory_screen_dragging',
    surfaces: const [GoldenSurface.phone],
    buildApp: buildApp,
    prepare: (tester) async {
      final from = tester.getCenter(find.text('영어'));
      final to = tester.getCenter(find.text('수학'));
      final gesture = await tester.startGesture(from);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
      await tester.pump();
      await gesture.moveTo(to);
      await tester.pump(const Duration(milliseconds: 300));
    },
  );
}
