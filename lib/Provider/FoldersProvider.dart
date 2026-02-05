import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Folder/FolderRegisterModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Service/Api/FileUpload/FileUploadService.dart';
import 'package:ono/Service/Api/Folder/FolderService.dart';

import '../Model/Folder/FolderModel.dart';
import '../Model/Problem/ProblemModel.dart';

// 폴더별 스크롤 상태를 저장하는 클래스
class FolderScrollState {
  List<FolderThumbnailModel> subfolders = [];
  List<ProblemModel> problems = [];
  int? subfolderNextCursor;
  int? problemNextCursor;
  bool subfolderHasNext = false;
  bool problemHasNext = false;
  bool isLoadingSubfolders = false;
  bool isLoadingProblems = false;

  FolderScrollState();
}

class FoldersProvider with ChangeNotifier {
  final ProblemsProvider problemsProvider;
  FolderModel? _currentFolder;
  List<FolderModel> _folders = [];

  // 폴더별 캐시 데이터 (핵심!)
  final Map<int, FolderScrollState> _folderCache = {};

  final folderService = FolderService();
  final fileUploadService = FileUploadService();

  FolderModel? get currentFolder => _currentFolder;
  List<FolderModel> get folders => _folders;
  FolderModel? get rootFolder => _folders.isNotEmpty ? _folders[0] : null;

  // 현재 폴더의 하위 폴더와 문제 목록
  List<FolderThumbnailModel> get currentSubfolders {
    if (_currentFolder == null) return [];
    return _folderCache[_currentFolder!.folderId]?.subfolders ?? [];
  }

  List<ProblemModel> get currentProblems {
    if (_currentFolder == null) return [];
    return _folderCache[_currentFolder!.folderId]?.problems ?? [];
  }

  // 로딩 상태
  bool get isLoadingSubfolders {
    if (_currentFolder == null) return false;
    return _folderCache[_currentFolder!.folderId]?.isLoadingSubfolders ?? false;
  }

  bool get isLoadingProblems {
    if (_currentFolder == null) return false;
    return _folderCache[_currentFolder!.folderId]?.isLoadingProblems ?? false;
  }

  bool get subfolderHasNext {
    if (_currentFolder == null) return false;
    return _folderCache[_currentFolder!.folderId]?.subfolderHasNext ?? false;
  }

  bool get problemHasNext {
    if (_currentFolder == null) return false;
    return _folderCache[_currentFolder!.folderId]?.problemHasNext ?? false;
  }

  FoldersProvider({required this.problemsProvider});

  FolderModel getFolder(int folderId) {
    int low = 0, high = _folders.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midId = _folders[mid].folderId;
      if (midId == folderId) {
        return _folders[mid];
      } else if (midId < folderId) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    log('can\'t find folderId: $folderId');
    throw Exception('Folder with id $folderId not found.');
  }

  // 루트 폴더 fetch (로그인 시 호출)
  Future<void> fetchRootFolder() async {
    final rootFolder = await folderService.getRootFolder();

    final index = _folders.indexWhere((folder) => folder.folderId == rootFolder.folderId);
    if (index != -1) {
      _folders[index] = rootFolder;
    } else {
      _folders.add(rootFolder);
    }

    log('Root folder fetched: ${rootFolder.folderId}');
    notifyListeners();
  }

  // 폴더 메타데이터만 fetch (이름, 부모폴더 등)
  Future<void> fetchFolderMetadata(int folderId) async {
    final folder = await folderService.fetchFolder(folderId);

    final index = _folders.indexWhere((f) => f.folderId == folderId);
    if (index != -1) {
      _folders[index] = folder;
    } else {
      _folders.add(folder);
    }

    log('Folder metadata fetched: $folderId');
    notifyListeners();
  }

  // 폴더 이동 (캐싱 로직 포함)
  Future<void> moveToFolder(int folderId) async {
    try {
      // 1. 폴더 메타데이터 fetch (항상 최신 정보 가져오기)
      await fetchFolderMetadata(folderId);
      _currentFolder = getFolder(folderId);

      // 2. 캐시 확인
      if (_folderCache.containsKey(folderId)) {
        // 캐시에 있으면 저장된 데이터 사용
        log('Using cached data for folder: $folderId');
        notifyListeners();
        return;
      }

      // 3. 캐시에 없으면 새로 생성하고 첫 페이지 로드
      log('Loading first page for folder: $folderId');
      _folderCache[folderId] = FolderScrollState();

      await Future.wait([
        loadMoreSubfolders(folderId),
        loadMoreProblems(folderId),
      ]);

      notifyListeners();
    } catch (e, stackTrace) {
      log('Error moving to folder: $e');
      log(stackTrace.toString());
      rethrow;
    }
  }

  // 루트 폴더로 이동
  Future<void> moveToRootFolder() async {
    if (rootFolder == null) {
      await fetchRootFolder();
    }
    await moveToFolder(rootFolder!.folderId);
  }

  // 하위 폴더 무한 스크롤 로드
  Future<void> loadMoreSubfolders(int folderId) async {
    final state = _folderCache[folderId];
    if (state == null) return;
    if (state.isLoadingSubfolders) return;
    if (state.subfolderNextCursor != null && !state.subfolderHasNext) return;

    try {
      state.isLoadingSubfolders = true;
      notifyListeners();

      final response = await folderService.getSubfoldersV2(
        folderId: folderId,
        cursor: state.subfolderNextCursor,
        size: 20,
      );

      state.subfolders.addAll(response.content);
      state.subfolderNextCursor = response.nextCursor;
      state.subfolderHasNext = response.hasNext;

      log('Loaded ${response.content.length} subfolders for folder $folderId, hasNext: ${response.hasNext}');
    } catch (e, stackTrace) {
      log('Error loading subfolders: $e');
      log(stackTrace.toString());
    } finally {
      state.isLoadingSubfolders = false;
      notifyListeners();
    }
  }

  // 폴더 내 문제 무한 스크롤 로드
  Future<void> loadMoreProblems(int folderId) async {
    final state = _folderCache[folderId];
    if (state == null) return;
    if (state.isLoadingProblems) return;
    if (state.problemNextCursor != null && !state.problemHasNext) return;

    try {
      state.isLoadingProblems = true;
      notifyListeners();

      final response = await problemsProvider.loadMoreFolderProblemsV2(
        folderId: folderId,
        cursor: state.problemNextCursor,
        size: 20,
      );

      state.problems.addAll(response.content);
      state.problemNextCursor = response.nextCursor;
      state.problemHasNext = response.hasNext;

      log('Loaded ${response.content.length} problems for folder $folderId, hasNext: ${response.hasNext}');
    } catch (e, stackTrace) {
      log('Error loading problems: $e');
      log(stackTrace.toString());
    } finally {
      state.isLoadingProblems = false;
      notifyListeners();
    }
  }

  // 현재 폴더 기준으로 더 로드
  Future<void> loadMoreCurrentSubfolders() async {
    if (_currentFolder == null) return;
    await loadMoreSubfolders(_currentFolder!.folderId);
  }

  Future<void> loadMoreCurrentProblems() async {
    if (_currentFolder == null) return;
    await loadMoreProblems(_currentFolder!.folderId);
  }

  // 폴더 생성
  Future<void> createFolder(String folderName, {int? parentFolderId}) async {
    parentFolderId = parentFolderId ?? _currentFolder?.folderId;
    if (parentFolderId == null) return;

    FolderRegisterModel folderRegisterModel = FolderRegisterModel(
      folderName: folderName,
      parentFolderId: parentFolderId,
    );

    final createdFolderId = await folderService.registerFolder(folderRegisterModel);

    // 생성된 폴더 메타데이터 fetch
    await fetchFolderMetadata(createdFolderId);

    // 부모 폴더의 캐시 갱신 (하위 폴더 목록 다시 로드)
    await refreshFolder(parentFolderId);
  }

  // 폴더 수정
  Future<void> updateFolder(String newName, int? folderId, int? parentId) async {
    if (folderId == null) return;

    FolderRegisterModel folderRegisterModel = FolderRegisterModel(
      folderId: folderId,
      folderName: newName,
      parentFolderId: parentId,
    );

    await folderService.updateFolderInfo(folderRegisterModel);

    // 메타데이터 갱신
    await fetchFolderMetadata(folderId);

    // 부모 폴더 캐시 갱신
    if (parentId != null) {
      await refreshFolder(parentId);
    }
  }

  // 폴더 삭제
  Future<void> deleteFolders(List<int> deleteFolderIdList) async {
    await folderService.deleteFolders(deleteFolderIdList);

    // 삭제된 폴더들의 캐시 제거
    for (var folderId in deleteFolderIdList) {
      _folderCache.remove(folderId);
      _folders.removeWhere((f) => f.folderId == folderId);
    }

    // 현재 폴더 캐시 갱신
    if (_currentFolder != null) {
      await refreshFolder(_currentFolder!.folderId);
    }
  }

  // 폴더 캐시 강제 갱신 (새로고침)
  Future<void> refreshFolder(int folderId) async {
    // 캐시 제거
    _folderCache.remove(folderId);

    // 현재 폴더이면 다시 로드
    if (_currentFolder?.folderId == folderId) {
      await moveToFolder(folderId);
    }
  }

  // 현재 폴더 새로고침
  Future<void> refreshCurrentFolder() async {
    if (_currentFolder == null) return;
    await refreshFolder(_currentFolder!.folderId);
  }

  // 캐시 전체 초기화 (로그아웃 시 등)
  void clearCache() {
    _folderCache.clear();
    _folders.clear();
    _currentFolder = null;
    notifyListeners();
  }
}