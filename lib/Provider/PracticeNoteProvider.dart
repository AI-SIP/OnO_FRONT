import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:ono/Provider/ProblemsProvider.dart';

import '../Model/PracticeNote/PracticeNoteDetailModel.dart';
import '../Model/PracticeNote/PracticeNoteThumbnailModel.dart';
import '../Model/Problem/AnswerStatus.dart';
import '../Model/Problem/ProblemModel.dart';
import '../Service/Api/HttpService.dart';
import '../Service/Api/PracticeNote/PracticeNoteService.dart';
import '../Util/AppErrorReporter.dart';
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

  /// 지금 열린 복습 세트의 문제들. 등록한 순서 그대로다.
  List<ProblemModel> currentProblems = [];

  /// 복습하기로 시작한 이번 회차에 풀 문제 번호들. 순서가 곧 푸는 순서다.
  ///
  /// 셔플이나 틀린 문제만으로 시작하면 [currentProblems] 와 순서나 개수가
  /// 달라진다. 복습 기록을 저장할 때마다 [moveToPractice] 로 세트를 다시
  /// 받는데, 문제 목록 자체를 섞어 두면 그때 등록 순서로 되돌아가서 셔플이
  /// 첫 문제 뒤로 풀렸다. 번호로 따로 들고 있으면 다시 받아도 그대로다.
  List<int>? _sessionProblemIds;
  final TokenProvider tokenProvider = TokenProvider();
  final HttpService httpService = HttpService();
  final PracticeNoteService practiceNoteService;
  final ProblemsProvider problemsProvider;

  // 복습 세트 목록 새로고침 타임스탬프
  int _practiceRefreshTimestamp = 0;
  int get practiceRefreshTimestamp => _practiceRefreshTimestamp;

  // 호환성을 위한 getter (정렬된 리스트 반환)
  List<PracticeNoteDetailModel> get practices => _practicesMap.values.toList();
  List<PracticeNoteThumbnails> get practiceThumbnails => _practiceThumbnails;
  bool get hasNext => _hasNext;
  bool get isLoading => _isLoading;
  bool get hasCachedData => _hasCachedData;

  ProblemPracticeProvider({
    required this.problemsProvider,
    PracticeNoteService? practiceNoteService,
  }) : practiceNoteService = practiceNoteService ?? PracticeNoteService();

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
    debugPrint(
        'Practice note $practiceNoteId not in cache, fetching from server');
    await fetchPracticeNote(practiceNoteId);

    if (_practicesMap.containsKey(practiceNoteId)) {
      return _practicesMap[practiceNoteId]!;
    }

    debugPrint('Failed to fetch practiceNoteId: $practiceNoteId');
    throw Exception('Practice with id $practiceNoteId not found.');
  }

  Future<void> fetchPracticeNote(
    int? practiceNoteId, {
    bool showErrorSnackBar = true,
  }) async {
    final practiceNote = await practiceNoteService.getPracticeNoteById(
      practiceNoteId!,
      showErrorSnackBar: showErrorSnackBar,
    );

    _upsertPracticeNote(practiceNote);

    // 현재 복습 세트가 업데이트된 것이면 다시 로드
    if (currentPracticeNote != null) {
      if (practiceNoteId == currentPracticeNote!.practiceId) {
        await moveToPractice(practiceNoteId);
      }
    }

    debugPrint('practiceId: $practiceNoteId fetch complete');
    notifyListeners();
  }

  Future<void> fetchAllPracticeContents() async {
    final practicesList = await practiceNoteService.getAllPracticeNoteDetails();
    _practicesMap.clear();
    for (var practice in practicesList) {
      _practicesMap[practice.practiceId] = practice;
    }

    debugPrint('fetch practice complete');
    notifyListeners();
  }

  /// 가장 최근에 시작한 [moveToPractice] 의 번호.
  ///
  /// 복습 세트를 열어 두고 불러오는 사이에 다른 세트를 열면 두 불러오기가
  /// 겹친다. 늦게 끝난 쪽이 먼저 연 세트라면 그 결과로 덮지 않는다.
  int _moveGeneration = 0;

  Future<void> moveToPractice(int practiceId) async {
    final generation = ++_moveGeneration;
    final targetPractice = await getPracticeNote(practiceId);

    // 다 모은 뒤에 한 번에 바꾼다. 공유 목록에 바로 넣으면 겹친 불러오기가
    // 서로의 문제를 섞어 넣는다.
    final loadedProblems = <ProblemModel>[];

    // 복습 세트의 각 문제를 서버에서 조회 (지연 로딩 대응)
    for (var problemId in targetPractice.problemIdList) {
      try {
        // 먼저 로컬 캐시에서 찾아보기
        ProblemModel? problemModel;
        try {
          problemModel = await problemsProvider.getProblem(problemId);
        } catch (e) {
          // 로컬 캐시에 없으면 서버에서 조회
          debugPrint('Problem $problemId not in cache, fetching from server');
          await problemsProvider.fetchProblem(problemId);
          problemModel = await problemsProvider.getProblem(problemId);
        }
        loadedProblems.add(problemModel);
      } catch (e, stackTrace) {
        debugPrint('Error loading problem $problemId: $e');
        debugPrint('Stack trace: $stackTrace');
        await AppErrorReporter.report(
          e,
          stackTrace,
          source: 'practice_note_problem_partial_load',
          severity: AppErrorSeverity.warning,
        );
        // 문제 로드 실패해도 계속 진행
      }
    }

    if (generation != _moveGeneration) return;

    // 다른 세트로 옮겨 가면 앞 세트의 회차 순서는 버린다.
    if (currentPracticeNote?.practiceId != practiceId) {
      _sessionProblemIds = null;
      _sessionResults.clear();
    }

    debugPrint(
        'Moved to practice: $practiceId, loaded ${loadedProblems.length}/${targetPractice.problemIdList.length} problems');
    currentProblems = loadedProblems;
    currentPracticeNote = targetPractice;
    notifyListeners();
  }

  Future<void> registerPractice(
      PracticeNoteRegisterModel practiceNoteRegisterModel) async {
    int createdPracticeId = await practiceNoteService
        .registerPracticeNote(practiceNoteRegisterModel);

    await _runPostMutationRefresh(
      () => fetchPracticeNote(
        createdPracticeId,
        showErrorSnackBar: false,
      ),
      source: 'practice_register_refresh',
    );

    // 복습 세트 목록 새로고침 신호
    _practiceRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;
    debugPrint(
        'Practice list refresh signaled - timestamp: $_practiceRefreshTimestamp');
    notifyListeners();
  }

  Future<void> updatePractice(
    PracticeNoteUpdateModel practiceNoteUpdateModel, {
    bool refreshAfterUpdate = true,
    bool showErrorSnackBar = false,
  }) async {
    await practiceNoteService.updatePracticeNote(
      practiceNoteUpdateModel,
      showErrorSnackBar: showErrorSnackBar,
    );

    if (refreshAfterUpdate) {
      await _runPostMutationRefresh(
        () => fetchPracticeNote(
          practiceNoteUpdateModel.practiceNoteId,
          showErrorSnackBar: false,
        ),
        source: 'practice_update_refresh',
      );
    } else {
      _applyPracticeUpdateToCache(practiceNoteUpdateModel);
    }

    // 복습 세트 목록 새로고침 신호
    _practiceRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;
    debugPrint(
        'Practice list refresh signaled - timestamp: $_practiceRefreshTimestamp');
    notifyListeners();
  }

  void _applyPracticeUpdateToCache(PracticeNoteUpdateModel updateModel) {
    final practiceNote = _practicesMap[updateModel.practiceNoteId];
    if (practiceNote == null) return;

    for (final problemId in updateModel.addProblemIdList) {
      if (!practiceNote.problemIdList.contains(problemId)) {
        practiceNote.problemIdList.add(problemId);
      }
    }

    practiceNote.problemIdList.removeWhere(
      (problemId) => updateModel.removeProblemIdList.contains(problemId),
    );
  }

  Future<void> _runPostMutationRefresh(
    Future<void> Function() refresh, {
    required String source,
  }) async {
    try {
      await refresh();
    } catch (e, stackTrace) {
      debugPrint('Post-mutation refresh failed ($source): $e');
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: source,
        severity: AppErrorSeverity.warning,
      );
    }
  }

  Future<void> deletePractices(List<int> deletePracticeIds) async {
    await practiceNoteService.deletePracticeNotes(deletePracticeIds);

    // 삭제된 항목들을 캐시에서 제거
    _practiceThumbnails.removeWhere(
      (thumbnail) => deletePracticeIds.contains(thumbnail.practiceId),
    );

    debugPrint('🗑️ Removed ${deletePracticeIds.length} practices from cache');
    notifyListeners();
  }

  /// 이번 회차에 풀 문제들. 복습하기로 시작하기 전이면 세트 전체다.
  List<ProblemModel> get sessionProblems {
    final ids = _sessionProblemIds;
    if (ids == null) return currentProblems;

    final problemById = {
      for (final problem in currentProblems) problem.problemId: problem,
    };
    return ids
        .map((problemId) => problemById[problemId])
        .whereType<ProblemModel>()
        .toList();
  }

  /// 복습하기로 회차를 시작했는지. 세트 상세에서 문제 하나를 따로 열어 푸는
  /// 것은 회차가 아니다.
  bool get isPracticing => _sessionProblemIds != null;

  /// 이번 회차에 복습을 저장한 문제와 결과. 같은 문제를 다시 저장하면 마지막
  /// 결과로 바뀐다.
  ///
  /// 완료 화면이 회차 문제 수를 그대로 `풀었어요` 로 적어서, 넘기기만 하고
  /// 마쳐도 다 푼 것처럼 보였다.
  final Map<int, AnswerStatus> _sessionResults = {};
  Map<int, AnswerStatus> get sessionResults =>
      UnmodifiableMapView(_sessionResults);

  /// 회차 안에서 복습을 저장했을 때 부른다. 회차가 아니거나 회차에 없는
  /// 문제면 남기지 않는다.
  void recordSessionResult(int problemId, AnswerStatus status) {
    final ids = _sessionProblemIds;
    if (ids == null || !ids.contains(problemId)) return;
    _sessionResults[problemId] = status;
  }

  /// 이번 회차에 풀 문제와 순서를 정한다.
  ///
  /// [onlyProblemIds] 를 넘기면 그 문제들만 푼다(틀린 문제만). [shuffle] 이면
  /// 고른 문제들끼리 섞는다.
  void startSession({bool shuffle = false, Set<int>? onlyProblemIds}) {
    final registeredIds = currentPracticeNote?.problemIdList ??
        currentProblems.map((problem) => problem.problemId).toList();
    final loadedIds =
        currentProblems.map((problem) => problem.problemId).toSet();

    final ids = registeredIds
        .where(loadedIds.contains)
        .where((id) => onlyProblemIds == null || onlyProblemIds.contains(id))
        .toList();
    if (shuffle) ids.shuffle();

    _sessionProblemIds = ids;
    _sessionResults.clear();
    notifyListeners();
  }

  /// 회차를 마치거나 세트 상세로 돌아와 다른 일을 하면 부른다.
  void endSession() {
    if (_sessionProblemIds == null) return;
    _sessionProblemIds = null;
    _sessionResults.clear();
    notifyListeners();
  }

  /// 복습 세트 화면을 닫을 때 부른다.
  ///
  /// [currentPracticeNote] 를 비우지 않으면 세트를 한 번 연 뒤로는 일반 복습도
  /// 세트 안에서 푼 것으로 기록되고, 복습을 저장할 때마다 그 세트를 다시 받았다.
  /// 그사이 다른 세트를 열었으면 그 세트는 건드리지 않는다.
  ///
  /// 화면이 사라지는 중에 불리므로 알리지 않는다.
  void leavePractice(int practiceId) {
    if (currentPracticeNote?.practiceId != practiceId) return;
    _moveGeneration++;
    currentPracticeNote = null;
    _sessionProblemIds = null;
    _sessionResults.clear();
  }

  /// 세트에서 문제를 뺀다. 서버에 반영된 뒤 화면 목록에서도 바로 지운다.
  Future<void> removeProblems(int practiceId, List<int> problemIds) async {
    await _changeProblems(practiceId, removeProblemIds: problemIds);

    final removed = problemIds.toSet();
    if (currentPracticeNote?.practiceId == practiceId) {
      currentProblems = currentProblems
          .where((problem) => !removed.contains(problem.problemId))
          .toList();
      _sessionProblemIds?.removeWhere(removed.contains);
    }
    notifyListeners();
  }

  /// 세트에 문제를 넣는다. 지금 열린 세트면 문제 목록도 다시 받는다.
  Future<void> addProblems(int practiceId, List<int> problemIds) async {
    await _changeProblems(practiceId, addProblemIds: problemIds);

    if (currentPracticeNote?.practiceId == practiceId) {
      await _runPostMutationRefresh(
        () => moveToPractice(practiceId),
        source: 'practice_add_problem_refresh',
      );
    }
    notifyListeners();
  }

  /// 문제만 넣고 빼는 요청은 모두 여기서 만든다.
  ///
  /// 서버는 `practiceNotification` 이 없으면 그 세트의 복습 알림을 지운다
  /// (OnO_BACKEND PracticeNoteService.updatePracticeInfo). 제목은 비워 보내면
  /// 그대로 두지만 알림은 그렇지 않아서, 세트가 가진 알림을 꼭 다시 싣는다.
  Future<void> _changeProblems(
    int practiceId, {
    List<int> addProblemIds = const [],
    List<int> removeProblemIds = const [],
  }) async {
    final practiceNote = await getPracticeNote(practiceId);
    await updatePractice(
      PracticeNoteUpdateModel(
        practiceNoteId: practiceId,
        addProblemIdList: addProblemIds,
        removeProblemIdList: removeProblemIds,
        practiceNotificationModel: practiceNote.practiceNotificationModel,
      ),
      refreshAfterUpdate: false,
    );
  }

  Future<void> resetProblems() async {
    currentProblems = [];
    notifyListeners();
  }

  void clear() {
    currentProblems = [];
    currentPracticeNote = null;
    _sessionProblemIds = null;
    _sessionResults.clear();
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

  Future<void> addPracticeCount(
    int practiceId, {
    String? moodEmojiKey,
  }) async {
    await practiceNoteService.addPracticeNoteCount(
      practiceId,
      moodEmojiKey: moodEmojiKey,
    );
    // PATCH 성공 후 GET 실패가 전파되면 호출부에서 재시도 → 이중 증가 발생.
    // GET은 화면 갱신용이므로 실패해도 성공으로 간주한다.
    try {
      await fetchPracticeCount(practiceId);
    } catch (_) {}
  }

  Future<void> fetchPracticeCount(int practiceNoteId) async {
    // 서버에서 최신 복습 세트 정보 조회
    await fetchPracticeNote(practiceNoteId);
    debugPrint('복습 카운트 갱신 완료 - Practice ID: $practiceNoteId');
  }

  // ==================== V2 무한 스크롤 메서드들 ====================

  /// 첫 페이지 복습 세트 썸네일 로드 (캐시 우선 사용)
  Future<void> loadInitialPracticeThumbnails(
      {int size = 20, bool forceRefresh = false}) async {
    // 캐시가 있고 강제 새로고침이 아니면 캐시 사용
    if (_hasCachedData && !forceRefresh) {
      debugPrint(
          '✅ Using cached practice thumbnails (${_practiceThumbnails.length} items)');
      return;
    }

    try {
      _isLoading = true;
      _practiceThumbnails.clear();
      _nextCursor = null;
      _hasNext = false;
      _hasCachedData = false;
      notifyListeners();

      debugPrint('📡 Fetching practice thumbnails from server');
      final response = await practiceNoteService.getPracticeNoteThumbnailsV2(
        cursor: null,
        size: size,
      );

      _practiceThumbnails = response.content;
      _nextCursor = response.nextCursor;
      _hasNext = response.hasNext;
      _hasCachedData = true;

      debugPrint(
          '💾 Practice thumbnails loaded and cached: ${_practiceThumbnails.length}');
    } catch (e, stackTrace) {
      debugPrint('Error loading initial practice thumbnails: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 다음 페이지 복습 세트 썸네일 로드 (무한 스크롤)
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

      debugPrint('More practice thumbnails loaded: ${response.content.length}');
      debugPrint('Total thumbnails: ${_practiceThumbnails.length}');
    } catch (e, stackTrace) {
      debugPrint('Error loading more practice thumbnails: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 복습 세트 목록 새로고침 (캐시 무시)
  Future<void> refreshPracticeThumbnails() async {
    await loadInitialPracticeThumbnails(forceRefresh: true);
  }

  /// 특정 복습 세트만 썸네일 캐시에서 업데이트
  Future<void> updateSinglePracticeThumbnail(int practiceId) async {
    try {
      debugPrint('🔄 Updating single practice thumbnail: $practiceId');

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
          lastSessionMoodEmojiKey: practiceDetail.lastSessionMoodEmojiKey,
        );

        _practiceThumbnails[index] = updatedThumbnail;
        debugPrint(
            '✅ Practice thumbnail updated in cache: $practiceId (count: ${practiceDetail.practiceCount})');
        notifyListeners();
      } else {
        debugPrint('⚠️ Practice $practiceId not found in cache');
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating single practice thumbnail: $e');
      debugPrint('Stack trace: $stackTrace');
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: 'practice_thumbnail_update',
        severity: AppErrorSeverity.warning,
      );
    }
  }

  /// 캐시 무효화 (삭제 등의 경우)
  void invalidateCache() {
    _hasCachedData = false;
    debugPrint('🗑️ Practice thumbnails cache invalidated');
  }
}
