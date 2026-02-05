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
  List<PracticeNoteDetailModel> _practices = [];

  // V2 무한 스크롤을 위한 썸네일 리스트
  List<PracticeNoteThumbnails> _practiceThumbnails = [];
  int? _nextCursor;
  bool _hasNext = false;
  bool _isLoading = false;

  List<ProblemModel> currentProblems = [];
  final TokenProvider tokenProvider = TokenProvider();
  final HttpService httpService = HttpService();
  final PracticeNoteService practiceNoteService = PracticeNoteService();
  final ProblemsProvider problemsProvider;

  List<PracticeNoteDetailModel> get practices => _practices;
  List<PracticeNoteThumbnails> get practiceThumbnails => _practiceThumbnails;
  bool get hasNext => _hasNext;
  bool get isLoading => _isLoading;

  ProblemPracticeProvider({required this.problemsProvider});

  // 동기적으로 캐시에서만 찾기 (내부용)
  int? _findPracticeNoteIndex(int practiceNoteId) {
    int low = 0, high = _practices.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midId = _practices[mid].practiceId;
      if (midId == practiceNoteId) {
        return mid;
      } else if (midId < practiceNoteId) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return null;
  }

  // 정렬을 유지하면서 복습노트를 추가하는 헬퍼 메서드
  void _insertPracticeNoteSorted(PracticeNoteDetailModel practiceNote) {
    final existingIndex = _findPracticeNoteIndex(practiceNote.practiceId);
    if (existingIndex != null) {
      // 이미 존재하면 업데이트
      _practices[existingIndex] = practiceNote;
    } else {
      // 없으면 정렬된 위치에 삽입 (practiceId 오름차순)
      int insertIndex = 0;
      while (insertIndex < _practices.length &&
          _practices[insertIndex].practiceId < practiceNote.practiceId) {
        insertIndex++;
      }
      _practices.insert(insertIndex, practiceNote);
    }
  }

  // 비동기로 복습노트 가져오기 (캐시에 없으면 서버에서 fetch)
  Future<PracticeNoteDetailModel> getPracticeNote(int practiceNoteId) async {
    final index = _findPracticeNoteIndex(practiceNoteId);
    if (index != null) {
      return _practices[index];
    }

    // 캐시에 없으면 서버에서 fetch
    log('Practice note $practiceNoteId not in cache, fetching from server');
    await fetchPracticeNote(practiceNoteId);

    final newIndex = _findPracticeNoteIndex(practiceNoteId);
    if (newIndex != null) {
      return _practices[newIndex];
    }

    log('Failed to fetch practiceNoteId: $practiceNoteId');
    throw Exception('Practice with id $practiceNoteId not found.');
  }

  Future<void> fetchPracticeNote(int? practiceNoteId) async {
    final practiceNote =
        await practiceNoteService.getPracticeNoteById(practiceNoteId!);

    _insertPracticeNoteSorted(practiceNote);

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
    _practices = await practiceNoteService.getAllPracticeNoteDetails();

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
  }

  Future<void> updatePractice(
      PracticeNoteUpdateModel practiceNoteUpdateModel) async {
    await practiceNoteService.updatePracticeNote(practiceNoteUpdateModel);

    await fetchPracticeNote(practiceNoteUpdateModel.practiceNoteId);
  }

  Future<void> deletePractices(List<int> deletePracticeIds) async {
    await practiceNoteService.deletePracticeNotes(deletePracticeIds);
    // V2 썸네일 리스트 새로고침
    await refreshPracticeThumbnails();
  }

  Future<void> resetProblems() async {
    currentProblems = [];
    notifyListeners();
  }

  void clear() {
    currentProblems = [];
    _practices = [];
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

  /// 첫 페이지 복습 노트 썸네일 로드 (초기 로딩)
  Future<void> loadInitialPracticeThumbnails({int size = 20}) async {
    try {
      _isLoading = true;
      _practiceThumbnails.clear();
      _nextCursor = null;
      _hasNext = false;
      notifyListeners();

      final response = await practiceNoteService.getPracticeNoteThumbnailsV2(
        cursor: null,
        size: size,
      );

      _practiceThumbnails = response.content;
      _nextCursor = response.nextCursor;
      _hasNext = response.hasNext;

      log('Initial practice thumbnails loaded: ${_practiceThumbnails.length}');
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

  /// 복습 노트 목록 새로고침
  Future<void> refreshPracticeThumbnails() async {
    await loadInitialPracticeThumbnails();
  }
}
