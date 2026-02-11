import 'dart:collection';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:ono/Provider/ProblemsProvider.dart';

import '../Model/PracticeNote/PracticeNoteDetailModel.dart';
import '../Model/PracticeNote/PracticeNoteThumbnailModel.dart';
import '../Model/Problem/ProblemModel.dart';
import '../Service/Api/HttpService.dart';
import '../Service/Api/PracticeNote/PracticeNoteService.dart';
import 'TokenProvider.dart';

class ProblemPracticeProvider with ChangeNotifier {
  PracticeNoteDetailModel? currentPracticeNote;

  // SplayTreeMap: O(log n) 삽입, O(log n) 조회, 자동 정렬
  final SplayTreeMap<int, PracticeNoteDetailModel> _practicesMap =
      SplayTreeMap();

  // V2 무한 스크롤을 위한 썸네일 리스트 (캐시)
  List<PracticeNoteThumbnails> _practiceThumbnails = [];
  int? _nextCursor;
  bool _hasNext = false;
  bool _isLoading = false;
  bool _hasCachedData = false; // 캐시 데이터 존재 여부

  List<ProblemModel> currentProblems = [];
  final TokenProvider tokenProvider = TokenProvider();
  final HttpService httpService = HttpService();
  final PracticeNoteService practiceNoteService = PracticeNoteService();
  final ProblemsProvider problemsProvider;

  // 복습 노트 목록 새로고침 타임스탬프
  int _practiceRefreshTimestamp = 0;
  int get practiceRefreshTimestamp => _practiceRefreshTimestamp;

  // 호환성을 위한 getter (정렬된 리스트 반환)
  List<PracticeNoteDetailModel> get practices => _practicesMap.values.toList();
  List<PracticeNoteThumbnails> get practiceThumbnails => _practiceThumbnails;
  bool get hasNext => _hasNext;
  bool get isLoading => _isLoading;
  bool get hasCachedData => _hasCachedData;

  ProblemPracticeProvider({required this.problemsProvider});

  // O(log n) 삽입/업데이트 (SplayTreeMap이 자동으로 정렬 유지)
  void _upsertPracticeNote(PracticeNoteDetailModel practiceNote) {
    _practicesMap[practiceNote.practiceId] = practiceNote;
  }

  // O(log n) 조회
  Future<PracticeNoteDetailModel> getPracticeNote(int practiceNoteId) async {
    if (_practicesMap.containsKey(practiceNoteId)) {
      return _practicesMap[practiceNoteId]!;
    }

    // 캐시에 없으면 서버에서 fetch
    log('Practice note $practiceNoteId not in cache, fetching from server');
    await fetchPracticeNote(practiceNoteId);

    if (_practicesMap.containsKey(practiceNoteId)) {
      return _practicesMap[practiceNoteId]!;
    }

    log('Failed to fetch practiceNoteId: $practiceNoteId');
    throw Exception('Practice with id $practiceNoteId not found.');
  }

  Future<void> fetchPracticeNote(int? practiceNoteId) async {
    final practiceNote =
        await practiceNoteService.getPracticeNoteById(practiceNoteId!);

    _upsertPracticeNote(practiceNote);

    // 현재 복습노트가 업데이트된 것이면 다시 로드
    if (currentPracticeNote != null) {
      if (practiceNoteId == currentPracticeNote!.practiceId) {
        await moveToPractice(practiceNoteId);
      }
    }

    log('practiceId: $practiceNoteId fetch complete');
    notifyListeners();
  }

  Future<void> fetchAllPracticeContents() async {
    final practicesList = await practiceNoteService.getAllPracticeNoteDetails();
    _practicesMap.clear();
    for (var practice in practicesList) {
      _practicesMap[practice.practiceId] = practice;
    }

    log('fetch practice complete');
    notifyListeners();
  }

  Future<void> moveToPractice(int practiceId) async {
    final targetPractice = await getPracticeNote(practiceId);

    currentProblems.clear();

    // 복습 노트의 각 문제를 서버에서 조회 (지연 로딩 대응)
    for (var problemId in targetPractice.problemIdList) {
      try {
        // 먼저 로컬 캐시에서 찾아보기
        ProblemModel? problemModel;
        try {
          problemModel = await problemsProvider.getProblem(problemId);
        } catch (e) {
          // 로컬 캐시에 없으면 서버에서 조회
          log('Problem $problemId not in cache, fetching from server');
          await problemsProvider.fetchProblem(problemId);
          problemModel = await problemsProvider.getProblem(problemId);
        }
        currentProblems.add(problemModel);
      } catch (e, stackTrace) {
        log('Error loading problem $problemId: $e');
        log('Stack trace: $stackTrace');
        // 문제 로드 실패해도 계속 진행
      }
    }

    log('Moved to practice: $practiceId, loaded ${currentProblems.length}/${targetPractice.problemIdList.length} problems');
    currentPracticeNote = targetPractice;
    notifyListeners();
  }

  Future<void> registerPractice(
      PracticeNoteRegisterModel practiceNoteRegisterModel) async {
    int createdPracticeId = await practiceNoteService
        .registerPracticeNote(practiceNoteRegisterModel);

    await fetchPracticeNote(createdPracticeId);

    // 복습 노트 목록 새로고침 신호
    _practiceRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;
    log('Practice list refresh signaled - timestamp: $_practiceRefreshTimestamp');
    notifyListeners();
  }

  Future<void> updatePractice(
      PracticeNoteUpdateModel practiceNoteUpdateModel) async {
    await practiceNoteService.updatePracticeNote(practiceNoteUpdateModel);

    await fetchPracticeNote(practiceNoteUpdateModel.practiceNoteId);

    // 복습 노트 목록 새로고침 신호
    _practiceRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;
    log('Practice list refresh signaled - timestamp: $_practiceRefreshTimestamp');
    notifyListeners();
  }

  Future<void> deletePractices(List<int> deletePracticeIds) async {
    await practiceNoteService.deletePracticeNotes(deletePracticeIds);

    // 삭제된 항목들을 캐시에서 제거
    _practiceThumbnails.removeWhere(
      (thumbnail) => deletePracticeIds.contains(thumbnail.practiceId),
    );

    log('🗑️ Removed ${deletePracticeIds.length} practices from cache');
    notifyListeners();
  }

  Future<void> resetProblems() async {
    currentProblems = [];
    notifyListeners();
  }

  void clear() {
    currentProblems = [];
    _hasCachedData = false;
    _nextCursor = null;
    _practiceThumbnails.clear();
    _practicesMap.clear();
    notifyListeners();
  }

  Future<ProblemModel?> getProblemDetails(int? problemId) async {
    return currentProblems
        .firstWhere((problem) => problem.problemId == problemId);
  }

  Future<void> addPracticeCount(int practiceId) async {
    await practiceNoteService.addPracticeNoteCount(practiceId);
    await fetchPracticeCount(practiceId);
  }

  Future<void> fetchPracticeCount(int practiceNoteId) async {
    // 서버에서 최신 복습 노트 정보 조회
    await fetchPracticeNote(practiceNoteId);
    log('복습 카운트 갱신 완료 - Practice ID: $practiceNoteId');
  }

  // ==================== V2 무한 스크롤 메서드들 ====================

  /// 첫 페이지 복습 노트 썸네일 로드 (캐시 우선 사용)
  Future<void> loadInitialPracticeThumbnails(
      {int size = 20, bool forceRefresh = false}) async {
    // 캐시가 있고 강제 새로고침이 아니면 캐시 사용
    if (_hasCachedData && !forceRefresh) {
      log('✅ Using cached practice thumbnails (${_practiceThumbnails.length} items)');
      return;
    }

    try {
      _isLoading = true;
      _practiceThumbnails.clear();
      _nextCursor = null;
      _hasNext = false;
      _hasCachedData = false;
      notifyListeners();

      log('📡 Fetching practice thumbnails from server');
      final response = await practiceNoteService.getPracticeNoteThumbnailsV2(
        cursor: null,
        size: size,
      );

      _practiceThumbnails = response.content;
      _nextCursor = response.nextCursor;
      _hasNext = response.hasNext;
      _hasCachedData = true;

      log('💾 Practice thumbnails loaded and cached: ${_practiceThumbnails.length}');
    } catch (e, stackTrace) {
      log('Error loading initial practice thumbnails: $e');
      log('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 다음 페이지 복습 노트 썸네일 로드 (무한 스크롤)
  Future<void> loadMorePracticeThumbnails({int size = 20}) async {
    if (_isLoading) return;
    if (!_hasNext || _nextCursor == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await practiceNoteService.getPracticeNoteThumbnailsV2(
        cursor: _nextCursor,
        size: size,
      );

      _practiceThumbnails.addAll(response.content);
      _nextCursor = response.nextCursor;
      _hasNext = response.hasNext;

      log('More practice thumbnails loaded: ${response.content.length}');
      log('Total thumbnails: ${_practiceThumbnails.length}');
    } catch (e, stackTrace) {
      log('Error loading more practice thumbnails: $e');
      log('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 복습 노트 목록 새로고침 (캐시 무시)
  Future<void> refreshPracticeThumbnails() async {
    await loadInitialPracticeThumbnails(forceRefresh: true);
  }

  /// 특정 복습 노트만 썸네일 캐시에서 업데이트
  Future<void> updateSinglePracticeThumbnail(int practiceId) async {
    try {
      log('🔄 Updating single practice thumbnail: $practiceId');

      // 상세 정보를 조회하여 최신 카운트 정보 확인
      final practiceDetail =
          await practiceNoteService.getPracticeNoteById(practiceId);

      // 캐시에서 해당 썸네일 찾기
      final index = _practiceThumbnails.indexWhere(
        (thumbnail) => thumbnail.practiceId == practiceId,
      );

      if (index != -1) {
        // 기존 썸네일 정보를 유지하면서 업데이트된 정보만 교체
        final updatedThumbnail = PracticeNoteThumbnails(
          practiceId: practiceDetail.practiceId,
          practiceTitle: practiceDetail.practiceTitle,
          practiceCount: practiceDetail.practiceCount,
          lastSolvedAt: practiceDetail.lastSolvedAt,
        );

        _practiceThumbnails[index] = updatedThumbnail;
        log('✅ Practice thumbnail updated in cache: $practiceId (count: ${practiceDetail.practiceCount})');
        notifyListeners();
      } else {
        log('⚠️ Practice $practiceId not found in cache');
      }
    } catch (e, stackTrace) {
      log('Error updating single practice thumbnail: $e');
      log('Stack trace: $stackTrace');
    }
  }

  /// 캐시 무효화 (삭제 등의 경우)
  void invalidateCache() {
    _hasCachedData = false;
    log('🗑️ Practice thumbnails cache invalidated');
  }
}
