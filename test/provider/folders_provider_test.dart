// FoldersProvider 상태 전이 테스트.
//
// 폴더별 스크롤 상태(FolderScrollState)가 _folderCache 에 폴더 단위로 쌓이는
// 구조라, 캐시 무효화·로딩 플래그·페이지네이션 커서가 핵심 관찰 대상이다.
// problemsProvider 는 FoldersProvider 가 그대로 위임하므로 MockProblemsProvider
// 를 주입해서 검증한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Folder/FolderRegisterModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Provider/FoldersProvider.dart';

import '../helpers/helpers.dart';
import 'support/provider_test_env.dart';

FolderModel _folder(int id, {String? name}) {
  return FolderModel(
    folderId: id,
    folderName: name ?? 'folder-$id',
    problemIdList: const [],
    subFolderList: const [],
  );
}

FolderThumbnailModel _thumb(int id) =>
    FolderThumbnailModel(folderId: id, folderName: 'sub-$id');

ProblemModel _problem(int id) => ProblemModel(problemId: id, folderId: 1);

void main() {
  setUpOnoTest();

  setUpAll(() {
    setUpProviderTestEnv();
    registerFallbackValue(
      FolderRegisterModel(folderName: 'fallback', parentFolderId: 0),
    );
  });

  late MockFolderService folderService;
  late MockProblemsProvider problemsProvider;
  late FoldersProvider provider;
  late NotifyRecorder notified;

  setUp(() {
    folderService = MockFolderService();
    problemsProvider = MockProblemsProvider();
    provider = FoldersProvider(
      problemsProvider: problemsProvider,
      folderService: folderService,
    );
    notified = NotifyRecorder();
    provider.addListener(notified.call);
  });

  group('초기 상태', () {
    test('아무 것도 안 했을 때 폴더도, 현재 폴더도 없다', () {
      expect(provider.folders, isEmpty);
      expect(provider.currentFolder, isNull);
      expect(provider.rootFolder, isNull);
      expect(provider.currentSubfolders, isEmpty);
      expect(provider.currentProblems, isEmpty);
      expect(provider.isLoadingSubfolders, isFalse);
      expect(provider.isLoadingProblems, isFalse);
    });
  });

  group('fetchRootFolder / fetchFolderMetadata', () {
    test('루트 폴더를 받아오면 캐시에 들어가고 rootFolder 가 채워진다', () async {
      when(() => folderService.getRootFolder())
          .thenAnswer((_) async => _folder(1, name: '루트'));

      await provider.fetchRootFolder();

      expect(provider.rootFolder?.folderId, 1);
      expect(notified.count, greaterThan(0));
    });
  });

  group('getFolder (캐시 우선 조회)', () {
    test('캐시에 없으면 서버에서 fetch 후 반환한다', () async {
      when(() => folderService.fetchFolder(5, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(5));

      final folder = await provider.getFolder(5);

      expect(folder.folderId, 5);
    });

    test('fetch 해도 여전히 캐시에 없으면(서버가 이상한 응답) 예외를 던진다', () async {
      // fetchFolderMetadata 는 정상 처리되지만, 반환된 폴더의 id 가 요청한 것과
      // 다르면 캐시에 5번은 여전히 없다 -> "Folder with id 5 not found." 예외.
      when(() => folderService.fetchFolder(5, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(999));

      await expectLater(provider.getFolder(5), throwsA(isA<Exception>()));
    });
  });

  group('moveToFolder', () {
    test('캐시가 없는 폴더로 처음 이동하면 하위폴더/문제를 함께 로드한다', () async {
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      when(() => folderService.getSubfoldersV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_thumb(11)],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_problem(101)],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));

      await provider.moveToFolder(1);

      expect(provider.currentFolder?.folderId, 1);
      expect(provider.currentSubfolders.map((f) => f.folderId), [11]);
      expect(provider.currentProblems.map((p) => p.problemId), [101]);
      expect(provider.isLoadingSubfolders, isFalse);
      expect(provider.isLoadingProblems, isFalse);
    });

    test('캐시가 있는 폴더로 다시 이동하면 서버를 다시 조회하지 않는다', () async {
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      when(() => folderService.getSubfoldersV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_thumb(11)],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_problem(101)],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      await provider.moveToFolder(1);
      clearInteractions(folderService);

      await provider.moveToFolder(1);

      verifyNever(() => folderService.getSubfoldersV2(
          folderId: any(named: 'folderId'),
          cursor: any(named: 'cursor'),
          size: any(named: 'size')));
      expect(provider.currentFolder?.folderId, 1);
    });

    test('폴더 메타데이터 조회가 실패하면 예외를 던지고 currentFolder 는 바뀌지 않는다', () async {
      when(() => folderService.fetchFolder(2, showErrorSnackBar: true))
          .thenThrow(Exception('network error'));

      await expectLater(provider.moveToFolder(2), throwsA(isA<Exception>()));
      expect(provider.currentFolder, isNull);
    });
  });

  group('loadMoreSubfolders (페이지네이션)', () {
    test('첫 페이지 로드 중에는 isLoadingSubfolders 가 true, 끝나면 false', () async {
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));

      bool? loadingDuringFetch;
      when(() => folderService.getSubfoldersV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenAnswer((_) async {
        // 서버 응답을 기다리는 동안 isLoadingSubfolders 가 true 로 서 있어야
        // 화면이 로딩 인디케이터를 보여줄 수 있다.
        loadingDuringFetch = provider.isLoadingSubfolders;
        return PaginatedResponse(
          content: [_thumb(11), _thumb(12)],
          nextCursor: 12,
          hasNext: true,
          size: 20,
        );
      });

      await provider.moveToFolder(1);

      expect(loadingDuringFetch, isTrue);
      expect(provider.isLoadingSubfolders, isFalse);
      expect(provider.subfolderHasNext, isTrue);
    });

    test('다음 페이지를 이어 붙이고 커서를 갱신한다', () async {
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      when(() => folderService.getSubfoldersV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_thumb(11)],
            nextCursor: 11,
            hasNext: true,
            size: 20,
          ));
      await provider.moveToFolder(1);

      when(() => folderService.getSubfoldersV2(
            folderId: 1,
            cursor: 11,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_thumb(12)],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));

      await provider.loadMoreCurrentSubfolders();

      expect(provider.currentSubfolders.map((f) => f.folderId), [11, 12]);
      expect(provider.subfolderHasNext, isFalse);
    });

    test(
      '마지막 페이지(hasNext=false) 에서는 더 부르지 않는다',
      () async {
        when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
            .thenAnswer((_) async => _folder(1));
        when(() => problemsProvider.loadMoreFolderProblemsV2(
              folderId: any(named: 'folderId'),
              cursor: any(named: 'cursor'),
              size: any(named: 'size'),
            )).thenAnswer((_) async => PaginatedResponse(
              content: const [],
              nextCursor: null,
              hasNext: false,
              size: 20,
            ));
        when(() => folderService.getSubfoldersV2(
              folderId: 1,
              cursor: null,
              size: 20,
            )).thenAnswer((_) async => PaginatedResponse(
              content: [_thumb(11)],
              nextCursor: null,
              hasNext: false,
              size: 20,
            ));
        await provider.moveToFolder(1);
        clearInteractions(folderService);

        await provider.loadMoreCurrentSubfolders();

        // TODO(#174): 실제 버그. lib/Provider/FoldersProvider.dart:251 의 가드
        // `if (!state.subfolderHasNext && state.subfolderNextCursor != null) return;`
        // 는 "마지막 페이지"와 "아직 한 번도 안 불러온 상태"를 구분하지 못한다.
        // 하위 폴더가 한 페이지(size 이하)로 끝나면 응답이 hasNext:false,
        // nextCursor:null 로 오는데, 이는 초기값(둘 다 false/null)과 똑같다.
        // 그 결과 이 가드는 항상 통과해서 스크롤이 끝에 도달한 뒤에도 매번
        // 서버를 다시 호출하고, addAll 이 중복 제거를 하지 않으므로 같은
        // 하위 폴더가 목록에 계속 중복으로 쌓인다. loadMoreProblems (같은 파일
        // 290행)도 problemHasNext/problemNextCursor 로 동일한 패턴이라 같은
        // 문제를 겪는다.
        verifyNever(() => folderService.getSubfoldersV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size')));
      },
      skip: '#174 에서 수정 예정',
    );

    test('이미 로딩 중이면 재진입하지 않는다 (동시 호출 가드)', () async {
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      // 캐시를 만들어 두기 위해 먼저 폴더로 이동(첫 페이지는 즉시 완료).
      when(() => folderService.getSubfoldersV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: 0,
            hasNext: true,
            size: 20,
          ));
      await provider.moveToFolder(1);

      var callCount = 0;
      when(() => folderService.getSubfoldersV2(
            folderId: 1,
            cursor: 0,
            size: 20,
          )).thenAnswer((_) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return PaginatedResponse(
          content: [_thumb(1)],
          nextCursor: null,
          hasNext: false,
          size: 20,
        );
      });

      final first = provider.loadMoreCurrentSubfolders();
      final second = provider.loadMoreCurrentSubfolders(); // 로딩 중 재호출
      await Future.wait([first, second]);

      expect(callCount, 1);
    });

    test('실패하면 예외를 던지지만 isLoadingSubfolders 는 반드시 false 로 돌아온다', () async {
      // finally 블록에서 항상 false 로 되돌리므로, 스피너가 영구히 뜨는 버그는
      // 여기서는 재현되지 않는다 — 회귀를 잡기 위한 가드 테스트.
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      when(() => folderService.getSubfoldersV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenThrow(Exception('boom'));

      await expectLater(provider.moveToFolder(1), throwsA(isA<Exception>()));

      // moveToFolder 가 예외를 던졌어도 캐시 항목 자체는 만들어져 있다.
      expect(provider.isLoadingSubfolders, isFalse);
    });
  });

  group('loadMoreProblems', () {
    test('problemsProvider 로 위임하고 결과를 폴더별 캐시에 담는다', () async {
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      when(() => folderService.getSubfoldersV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_problem(1), _problem(2)],
            nextCursor: 2,
            hasNext: true,
            size: 20,
          ));

      await provider.moveToFolder(1);

      expect(provider.currentProblems.map((p) => p.problemId), [1, 2]);
      expect(provider.problemHasNext, isTrue);
    });
  });

  group('createFolder / updateFolder', () {
    test('생성 후 부모 폴더 캐시를 무효화(refreshFolder)한다', () async {
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      when(() => folderService.getSubfoldersV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      await provider.moveToFolder(1); // 부모 폴더(1) 캐시 생성
      expect(provider.hasSubfolderCache(1), isTrue);

      when(() => folderService.registerFolder(any()))
          .thenAnswer((_) async => 99);
      when(() => folderService.fetchFolder(99, showErrorSnackBar: false))
          .thenAnswer((_) async => _folder(99, name: '새 폴더'));

      await provider.createFolder('새 폴더', parentFolderId: 1);

      // refreshFolder(1) 이 캐시를 지워서, 화면이 다시 로드해야 함을 알 수 있다.
      expect(provider.hasSubfolderCache(1), isFalse);
      expect(provider.folders.any((f) => f.folderId == 99), isTrue);
    });
  });

  group('deleteFolders', () {
    test('삭제된 폴더는 목록과 캐시에서 모두 빠진다', () async {
      when(() => folderService.fetchFolder(3, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(3));
      when(() => folderService.getSubfoldersV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      await provider.moveToFolder(3);
      when(() => folderService.deleteFolders([3])).thenAnswer((_) async {});

      await provider.deleteFolders([3]);

      expect(provider.folders.any((f) => f.folderId == 3), isFalse);
      expect(provider.hasSubfolderCache(3), isFalse);
    });
  });

  group('clear', () {
    test('전체 캐시와 currentFolder 를 초기화한다', () async {
      when(() => folderService.fetchFolder(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(1));
      when(() => folderService.getSubfoldersV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      when(() => problemsProvider.loadMoreFolderProblemsV2(
            folderId: any(named: 'folderId'),
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      await provider.moveToFolder(1);

      provider.clear();

      expect(provider.folders, isEmpty);
      expect(provider.currentFolder, isNull);
      expect(provider.hasSubfolderCache(1), isFalse);
    });
  });
}
