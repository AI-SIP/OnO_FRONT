import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Model/Problem/ProblemImageDataModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Provider/ReviewDueProvider.dart';
import 'package:ono/Model/Folder/FolderRegisterModel.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/Folder/DirectoryScreen.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

class _FolderRegisterModelFake extends Fake implements FolderRegisterModel {}

/// [DirectoryScreen] 은 2,255줄짜리 화면이라 갈래별로 group 을 나눠 다룬다.
/// - 로그인 상태
/// - 폴더/문제 목록 (초기 로딩·빈 상태·정상 상태·에러)
/// - 폴더 진입
/// - 선택 모드
/// - 공책 생성
/// - 반응형
/// - 알려진 버그(#174) 재현
void main() {
  setUpOnoWidgetTest();

  setUpAll(() {
    registerFallbackValue(_FolderRegisterModelFake());
  });

  late _FakeUserProvider userProvider;
  late MockFolderService folderService;
  late MockProblemService problemService;
  late ProblemsProvider problemsProvider;
  late FoldersProvider foldersProvider;
  late ReviewDueProvider reviewDueProvider;

  FolderModel buildRootFolder({
    int folderId = 1,
    String folderName = '책장',
    FolderThumbnailModel? parentFolder,
  }) {
    return FolderModel(
      folderId: folderId,
      folderName: folderName,
      parentFolder: parentFolder,
      problemIdList: const [],
      subFolderList: const [],
    );
  }

  FolderThumbnailModel buildSubfolder({
    int folderId = 10,
    String folderName = '수학',
    int problemCount = 3,
  }) {
    return FolderThumbnailModel(
      folderId: folderId,
      folderName: folderName,
      problemCount: problemCount,
    );
  }

  ProblemModel buildProblem({
    int problemId = 100,
    String reference = '수학 문제집 p.12',
    bool withImage = true,
  }) {
    return ProblemModel(
      problemId: problemId,
      folderId: 1,
      reference: reference,
      solveCount: 2,
      problemImageDataList: withImage
          ? [
              ProblemImageDataModel(
                imageUrl: 'https://test.ono.local/image.png',
                problemImageType: ProblemImageType.PROBLEM_IMAGE,
                createdAt: DateTime(2026, 1, 1),
              ),
            ]
          : const [],
    );
  }

  /// 폴더 진입(초기 로딩)에서 쓰는 기본 stub 을 걸어 둔다.
  /// 개별 테스트가 다른 그림을 보고 싶으면 다시 `when` 으로 덮어써라.
  void stubDefaultFolderLoad({
    FolderModel? folder,
    List<FolderThumbnailModel> subfolders = const [],
    List<ProblemModel> problems = const [],
    bool subfolderHasNext = false,
    bool problemHasNext = false,
  }) {
    when(() => folderService.getRootFolder())
        .thenAnswer((_) async => folder ?? buildRootFolder());
    // 요청한 folderId 로 그대로 되돌려준다. FoldersProvider 는 응답의
    // folderId 를 캐시 키로 쓰므로, 항상 같은 id 를 돌려주면 하위 폴더 진입
    // 같은 다른 folderId 조회가 "폴더를 찾을 수 없음" 으로 깨진다.
    when(() => folderService.fetchFolder(any(),
            showErrorSnackBar: any(named: 'showErrorSnackBar')))
        .thenAnswer((invocation) async {
      final requestedId = invocation.positionalArguments[0] as int;
      return folder ??
          buildRootFolder(
              folderId: requestedId, folderName: '하위 폴더 $requestedId');
    });
    when(() => folderService.getSubfoldersV2(
          folderId: any(named: 'folderId'),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => PaginatedResponse(
          content: subfolders,
          nextCursor: subfolderHasNext ? 999 : null,
          hasNext: subfolderHasNext,
          size: subfolders.length,
        ));
    when(() => problemService.getFolderProblemsV2(
          folderId: any(named: 'folderId'),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => PaginatedResponse(
          content: problems,
          nextCursor: problemHasNext ? 999 : null,
          hasNext: problemHasNext,
          size: problems.length,
        ));
  }

  setUp(() {
    userProvider = _FakeUserProvider();
    when(() => userProvider.isLoggedIn).thenReturn(LoginStatus.login);
    when(() => userProvider.addListener(any())).thenReturn(null);
    when(() => userProvider.removeListener(any())).thenReturn(null);
    when(() => userProvider.dispose()).thenReturn(null);

    folderService = MockFolderService();
    problemService = MockProblemService();
    problemsProvider = ProblemsProvider(problemService: problemService);
    foldersProvider = FoldersProvider(
      problemsProvider: problemsProvider,
      folderService: folderService,
    );
    reviewDueProvider = ReviewDueProvider(problemService: problemService);

    when(() => problemService.getReviewDueProblems()).thenAnswer(
      (_) async =>
          ReviewDueResponse(dueCount: 0, overdueCount: 0, problems: []),
    );

    stubDefaultFolderLoad();
  });

  Future<void> pumpDirectory(
    WidgetTester tester, {
    Size surfaceSize = OnoSurface.phone,
    List<NavigatorObserver> navigatorObservers = const [],
    bool settle = true,
  }) {
    return withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const DirectoryScreen(),
        userProvider: userProvider,
        foldersProvider: foldersProvider,
        problemsProvider: problemsProvider,
        reviewDueProvider: reviewDueProvider,
        surfaceSize: surfaceSize,
        navigatorObservers: navigatorObservers,
        settle: settle,
      );
    });
  }

  group('로그인 상태', () {
    testWidgets('로그아웃 상태면 안내 문구만 보이고 목록·FAB 는 없다', (tester) async {
      when(() => userProvider.isLoggedIn).thenReturn(LoginStatus.logout);

      await pumpDirectory(tester);

      expect(find.textContaining('로그인을 통해'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('폴더/문제 목록', () {
    testWidgets('초기 로딩 중에는 스피너가 보인다', (tester) async {
      // 루트 폴더 조회에 지연을 줘서, 응답이 오기 전 로딩 상태를 붙잡는다.
      // (mock 은 기본적으로 즉시 완료되어 pump 한 번으로는 로딩 상태를 볼 수 없다.)
      when(() => folderService.getRootFolder()).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return buildRootFolder();
        },
      );

      await pumpDirectory(tester, settle: false);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 지연된 응답을 마저 흘려보내 테스트 종료 시 pending 타이머를 남기지 않는다.
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('하위 폴더도 문제도 없으면 빈 상태 문구가 보인다', (tester) async {
      await pumpDirectory(tester);

      expect(find.textContaining('공책에 저장해 관리하세요'), findsOneWidget);
    });

    testWidgets('하위 폴더와 문제가 있으면 폴더명과 문제 수 배지, 문제 제목이 보인다', (tester) async {
      stubDefaultFolderLoad(
        subfolders: [
          buildSubfolder(folderId: 10, folderName: '수학', problemCount: 3)
        ],
        problems: [buildProblem(problemId: 100, reference: '수학 문제집 p.12')],
      );

      await pumpDirectory(tester);

      expect(find.text('수학'), findsOneWidget);
      expect(find.text('3개'), findsOneWidget);
      expect(find.text('수학 문제집 p.12'), findsOneWidget);
      expect(find.textContaining('공책에 저장해 관리하세요'), findsNothing);
    });

    testWidgets('폴더 조회가 실패하면 에러 스낵바가 뜬다', (tester) async {
      when(() => folderService.getRootFolder())
          .thenThrow(Exception('network down'));

      await pumpDirectory(tester);

      expect(find.textContaining('서버 응답이 올바르지 않아'), findsOneWidget);
    });

    testWidgets('제목 없는 문제는 "제목 없음" 으로 보인다', (tester) async {
      stubDefaultFolderLoad(
        problems: [buildProblem(problemId: 100, reference: '')],
      );

      await pumpDirectory(tester);

      expect(find.text('제목 없음'), findsOneWidget);
    });
  });

  group('무한 스크롤', () {
    testWidgets('다음 페이지가 있으면 목록 하단에 로딩 인디케이터가 추가로 붙는다', (tester) async {
      stubDefaultFolderLoad(
        subfolders: [buildSubfolder()],
        problemHasNext: true,
      );

      await pumpDirectory(tester, settle: false);
      await tester.pump();
      await tester.pump();

      // 폴더 타일 하나 + 하단 '더 불러오는 중' 인디케이터
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('폴더 진입', () {
    testWidgets('폴더 타일을 탭하면 하위 DirectoryScreen 으로 push 된다', (tester) async {
      stubDefaultFolderLoad(
        subfolders: [buildSubfolder(folderId: 10, folderName: '수학')],
      );
      final observer = _RecordingNavigatorObserver();

      await pumpDirectory(tester, navigatorObservers: [observer]);
      await tester.tap(find.text('수학'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes, greaterThanOrEqualTo(1));
      // 전환이 끝나면 Navigator 가 이전 라우트를 offstage 로 감춰서 화면 밖에
      // 둔다. skipOffstage:false 로 둘 다 세어야 push 가 실제로 일어났음을
      // 확인할 수 있다.
      expect(
        find.byType(DirectoryScreen, skipOffstage: false),
        findsNWidgets(2),
      );
    });
  });

  group('선택 모드', () {
    // 편집 메뉴의 삭제(선택 모드 진입) 항목은 화면에 아이콘(delete_outline)으로만
    // 유일하게 식별된다. 텍스트로 찾으면 바텀시트 헤더 "공책 편집하기"와
    // 라벨이 겹친다 — TODO(#174): 실제 버그. lib/Screen/Folder/DirectoryScreen.dart
    // 의 _showActionDialog 안, 삭제 액션 아이템(Icons.delete_outline) 의
    // title 이 '공책 편집하기'로 돼 있어 바텀시트 헤더 문구와 중복된다.
    // (아이템 자체는 선택 모드 진입 → 삭제 기능이라 '삭제하기' 류의 문구가 맞아 보인다.)
    Finder deleteMenuItem() => find.ancestor(
          of: find.byIcon(Icons.delete_outline),
          matching: find.byType(InkWell),
        );

    testWidgets('더보기 버튼을 누르면 편집 메뉴가 열린다', (tester) async {
      await pumpDirectory(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('공책 추가하기'), findsOneWidget);
      expect(find.text('공책 정리하기'), findsOneWidget);
      expect(deleteMenuItem(), findsOneWidget);
    });

    testWidgets('공책 편집하기를 누르면 선택 모드로 들어가 하단 버튼이 보인다', (tester) async {
      await pumpDirectory(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(deleteMenuItem());
      await tester.pumpAndSettle();

      expect(find.text('삭제할 항목 선택'), findsOneWidget);
      expect(find.text('취소하기'), findsOneWidget);
      expect(find.text('삭제하기'), findsOneWidget);
    });

    testWidgets('선택 모드에서 폴더를 탭하면 선택 개수가 올라간다', (tester) async {
      stubDefaultFolderLoad(
        subfolders: [buildSubfolder(folderId: 10, folderName: '수학')],
      );
      await pumpDirectory(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(deleteMenuItem());
      await tester.pumpAndSettle();

      await tester.tap(find.text('수학'));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget); // 삭제하기 옆 선택 개수 뱃지
    });

    testWidgets('X 버튼을 누르면 선택 모드가 풀린다', (tester) async {
      await pumpDirectory(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(deleteMenuItem());
      await tester.pumpAndSettle();
      expect(find.text('삭제할 항목 선택'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('삭제할 항목 선택'), findsNothing);
      expect(find.text('취소하기'), findsNothing);
    });
  });

  group('공책 생성', () {
    testWidgets('빠른 추가 FAB 을 열면 세 가지 옵션이 보인다', (tester) async {
      await pumpDirectory(tester);

      await tester.tap(find.byKey(const ValueKey('quick_fab_closed')));
      await tester.pumpAndSettle();

      expect(find.text('공책 추가'), findsOneWidget);
      expect(find.text('오답노트 1장 작성'), findsOneWidget);
      expect(find.text('오답노트 여러장 작성'), findsOneWidget);
    });

    testWidgets('공책 추가 다이얼로그에 이름을 입력하고 확인하면 registerFolder 가 불린다',
        (tester) async {
      when(() => folderService.registerFolder(any()))
          .thenAnswer((_) async => 20);
      await pumpDirectory(tester);

      await tester.tap(find.byKey(const ValueKey('quick_fab_closed')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('공책 추가'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '영어');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      verify(() => folderService.registerFolder(any())).called(1);
    });

    testWidgets('이름을 비운 채 확인을 눌러도 registerFolder 가 불리지 않는다', (tester) async {
      await pumpDirectory(tester);

      await tester.tap(find.byKey(const ValueKey('quick_fab_closed')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('공책 추가'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      verifyNever(() => folderService.registerFolder(any()));
      // 빈 값이면 다이얼로그가 닫히지 않는다.
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('반응형', () {
    testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
      stubDefaultFolderLoad(
        subfolders: [buildSubfolder()],
        problems: [buildProblem()],
      );

      await pumpDirectory(tester, surfaceSize: OnoSurface.tablet);

      expect(tester.takeException(), isNull);
      expect(find.byType(DirectoryScreen), findsOneWidget);
    });

    testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
      stubDefaultFolderLoad(
        subfolders: [buildSubfolder()],
        problems: [buildProblem()],
      );

      await pumpDirectory(tester, surfaceSize: OnoSurface.smallPhone);

      expect(tester.takeException(), isNull);
    });
  });

  group('알려진 버그 (#174)', () {
    testWidgets(
      'loadProblems() 는 이미지 없는 문제에서 RangeError 로 죽는다',
      (tester) async {
        // TODO(#174): 실제 버그. lib/Model/Problem/ProblemThumbnailModel.dart:36-38
        // ProblemModel.fromJson 은 problemImageDataList 가 없으면 빈 리스트를
        // 만드는데(null 아님), ProblemThumbnailModel.fromProblem 은 `!= null` 만
        // 확인하고 곧장 [0] 에 접근해서 이미지 없는 문제에서 RangeError 가 난다.
        //
        // 이 메서드(DirectoryScreen.loadProblems())는 현재 build() 어디에서도
        // 호출되지 않는 죽은 코드다(실제 렌더링은 _localProblems 를 직접 쓴다).
        // 그래서 일반적인 탭·스크롤로는 도달하지 않고, 마운트된 State 를 통해
        // 직접 호출해서 재현한다.
        final problemWithoutImage = ProblemModel.fromJson({
          'problemId': 100,
          'folderId': 1,
          'reference': '이미지 없는 문제',
          // imageUrlList 를 아예 주지 않으면 ProblemModel.fromJson 이
          // problemImageDataList 를 [] 로 채운다.
        });

        stubDefaultFolderLoad();
        await pumpDirectory(tester);

        foldersProvider.saveProblemsToCache(
            1, [problemWithoutImage], null, false);

        final state = tester.state(find.byType(DirectoryScreen));
        expect(
          () => (state as dynamic).loadProblems(),
          throwsA(isA<RangeError>()),
        );
      },
      skip: true, // #174 에서 수정 예정
    );
  });
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  int pushedRoutes = 0;

  @override
  void didPush(Route route, Route? previousRoute) {
    pushedRoutes++;
    super.didPush(route, previousRoute);
  }
}
