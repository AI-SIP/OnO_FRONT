import 'package:flutter/material.dart';

import '../Model/StudyRoom/ActivityFeedModel.dart';
import '../Model/StudyRoom/ChallengeModel.dart';
import '../Model/StudyRoom/InviteCodeModel.dart';
import '../Model/StudyRoom/SharedProblemCommentModel.dart';
import '../Model/StudyRoom/SharedProblemModel.dart';
import '../Model/StudyRoom/StudyRoomMemberModel.dart';
import '../Model/StudyRoom/StudyRoomModel.dart';
import '../Model/StudyRoom/StudySessionModel.dart';
import '../Model/StudyRoom/WeeklyReportModel.dart';
import '../Module/Emoji/OnoEmojiCatalog.dart';
import '../Service/Api/StudyRoom/StudyRoomService.dart';

class StudyRoomProvider extends ChangeNotifier {
  final StudyRoomService _service = StudyRoomService();

  List<StudyRoomModel> rooms = [];
  StudyRoomModel? selectedRoom;
  bool isLoading = false;

  List<ActivityFeedModel> feedItems = [];
  int? _feedNextCursor;
  bool feedHasNext = false;
  bool isFeedLoadingMore = false;
  List<ChallengeModel> challenges = [];
  List<StudySessionModel> activeSessions = [];
  List<SharedProblemModel> sharedProblems = [];
  int? _sharedProblemsNextCursor;
  bool sharedProblemsHasNext = false;
  bool isSharedProblemsLoadingMore = false;
  final Map<int, List<SharedProblemCommentModel>> sharedProblemComments = {};
  WeeklyReportModel? weeklyReport;
  int? myWeeklyGoal;

  int? currentUserId;
  int? _activeRoomId;
  int? _mySessionId;

  void updateCurrentUserId(int? userId) {
    currentUserId = userId;
  }

  bool isHost(StudyRoomModel room) => room.hostUserId == currentUserId;

  // ── 기존 방 CRUD ──

  Future<void> fetchMyRooms() async {
    isLoading = true;
    notifyListeners();
    try {
      rooms = await _service.fetchMyRooms();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoomDetail(int roomId) async {
    isLoading = true;
    notifyListeners();
    try {
      _activeRoomId = roomId;
      selectedRoom = await _service.fetchRoomDetail(roomId);
      rooms = [
        for (final room in rooms)
          if (room.roomId == roomId) selectedRoom! else room,
      ];
      await Future.wait([
        fetchFeed(roomId, notify: false),
        fetchChallenges(roomId, notify: false),
        fetchActiveSessions(roomId, notify: false),
        fetchWeeklyReport(roomId, notify: false),
      ]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<StudyRoomModel> createRoom(String name) async {
    isLoading = true;
    notifyListeners();
    try {
      final newRoom = await _service.createRoom(name);
      rooms = [...rooms.where((r) => r.roomId != newRoom.roomId), newRoom];
      return newRoom;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinRoom(String code) async {
    isLoading = true;
    notifyListeners();
    try {
      final joinedRoom = await _service.joinRoom(code);
      rooms = [
        ...rooms.where((r) => r.roomId != joinedRoom.roomId),
        joinedRoom
      ];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveRoom(int roomId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.leaveRoom(roomId);
      rooms = rooms.where((r) => r.roomId != roomId).toList();
      if (selectedRoom?.roomId == roomId) selectedRoom = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRoom(int roomId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.deleteRoom(roomId);
      rooms = rooms.where((r) => r.roomId != roomId).toList();
      if (selectedRoom?.roomId == roomId) selectedRoom = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> kickMember(int roomId, int memberId) async {
    await _service.kickMember(roomId, memberId);
    rooms = rooms.map((r) {
      if (r.roomId != roomId) return r;
      return r.copyWith(
        members: r.members.where((m) => m.userId != memberId).toList(),
        serverMemberCount: r.memberCount - 1,
      );
    }).toList();
    if (selectedRoom?.roomId == roomId) {
      await fetchRoomDetail(roomId);
      return;
    }
    notifyListeners();
  }

  bool _isUploadingThumbnail = false;

  Future<void> updateRoomThumbnail(int roomId, String imagePath) async {
    if (_isUploadingThumbnail) return;
    _isUploadingThumbnail = true;
    try {
      final thumbnailUrl = await _service.uploadRoomThumbnail(
        roomId: roomId,
        imagePath: imagePath,
      );
      if (thumbnailUrl == null) return;
      rooms = rooms.map((r) {
        if (r.roomId != roomId) return r;
        return r.copyWith(thumbnailImagePath: thumbnailUrl);
      }).toList();
      if (selectedRoom?.roomId == roomId) {
        selectedRoom = selectedRoom!.copyWith(thumbnailImagePath: thumbnailUrl);
      }
      notifyListeners();
    } finally {
      _isUploadingThumbnail = false;
    }
  }

  Future<void> updateRoomName(int roomId, String name) async {
    final updatedRoom = await _service.updateRoomName(
      roomId: roomId,
      name: name,
    );
    rooms = rooms.map((r) {
      if (r.roomId != roomId) return r;
      return r.copyWith(name: updatedRoom.name);
    }).toList();
    if (selectedRoom?.roomId == roomId) {
      selectedRoom = selectedRoom!.copyWith(name: updatedRoom.name);
    }
    notifyListeners();
  }

  Future<InviteCodeModel> generateInviteCode(int roomId) async {
    final code = await _service.generateInviteCode(roomId);
    selectedRoom = selectedRoom?.roomId == roomId
        ? selectedRoom!.copyWith(
            inviteCode: code.code,
            inviteExpiredAt: code.expiredAt,
          )
        : selectedRoom;
    return code;
  }

  // ── A. 활동 피드 ──

  Future<void> fetchFeed(int roomId, {bool notify = true}) async {
    final page = await _service.fetchFeed(roomId);
    feedItems = page.content;
    _feedNextCursor = page.nextCursor;
    feedHasNext = page.hasNext;
    if (notify) notifyListeners();
  }

  Future<void> loadMoreFeed(int roomId) async {
    if (!feedHasNext || isFeedLoadingMore || _feedNextCursor == null) return;
    isFeedLoadingMore = true;
    notifyListeners();
    try {
      final page = await _service.fetchFeed(roomId, cursor: _feedNextCursor);
      feedItems = [...feedItems, ...page.content];
      _feedNextCursor = page.nextCursor;
      feedHasNext = page.hasNext;
    } finally {
      isFeedLoadingMore = false;
      notifyListeners();
    }
  }

  String _normalizeEmojiKey(String emoji) {
    return OnoEmojiCatalog.byKey(emoji)?.key ?? emoji;
  }

  Future<void> toggleFeedReaction(int feedId, String emoji) async {
    final feed = feedItems.where((f) => f.feedId == feedId).firstOrNull;
    if (feed == null) return;
    final emojiKey = _normalizeEmojiKey(emoji);
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;

    feed.reactions = await _service.toggleFeedReaction(
      roomId: roomId,
      feedId: feedId,
      emoji: emojiKey,
    );
    notifyListeners();
  }

  // ── B. 챌린지 ──

  Future<void> fetchChallenges(int roomId, {bool notify = true}) async {
    challenges = await _service.fetchChallenges(roomId);
    if (notify) notifyListeners();
  }

  Future<void> createChallenge({
    required String title,
    required String type,
    required String metric,
    String? period,
    int? periodDays,
    required int targetValue,
    required DateTime endAt,
  }) async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    final newChallenge = await _service.createChallenge(
      roomId: roomId,
      title: title,
      type: type,
      metric: metric,
      period: period,
      periodDays: periodDays,
      targetValue: targetValue,
      endAt: endAt,
    );
    challenges = [...challenges, newChallenge];
    notifyListeners();
  }

  Future<void> deleteChallenge(int challengeId) async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    await _service.deleteChallenge(roomId: roomId, challengeId: challengeId);
    challenges = challenges.where((c) => c.challengeId != challengeId).toList();
    notifyListeners();
  }

  // ── C. 공부 세션 ──

  Future<void> fetchActiveSessions(int roomId, {bool notify = true}) async {
    activeSessions = await _service.fetchActiveSessions(roomId);
    if (notify) notifyListeners();
  }

  Future<void> addMySession() async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    _mySessionId = await _service.startSession(roomId);
    await fetchActiveSessions(roomId, notify: false);
    notifyListeners();
  }

  Future<void> removeMySession() async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    if (_mySessionId != null) {
      await _service.endSession(roomId: roomId, sessionId: _mySessionId!);
      _mySessionId = null;
    }
    await fetchActiveSessions(roomId, notify: false);
    notifyListeners();
  }

  // ── D. 문제 공유 ──

  Future<void> shareProblems(
    int problemId, {
    String? comment,
    bool notify = true,
  }) async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    final shared = await _service.shareProblems(
      roomId: roomId,
      problemId: problemId,
      comment: comment,
    );
    sharedProblems = [shared, ...sharedProblems];
    if (notify) notifyListeners();
  }

  Future<void> deleteSharedProblem(int sharedProblemId) async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    await _service.deleteSharedProblem(
      roomId: roomId,
      sharedProblemId: sharedProblemId,
    );
    sharedProblems.removeWhere((s) => s.sharedProblemId == sharedProblemId);
    sharedProblemComments.remove(sharedProblemId);
    notifyListeners();
  }

  Future<void> fetchSharedProblems(int roomId, {bool notify = true}) async {
    final page = await _service.fetchSharedProblems(roomId);
    sharedProblems = page.content;
    _sharedProblemsNextCursor = page.nextCursor;
    sharedProblemsHasNext = page.hasNext;
    if (notify) notifyListeners();
  }

  Future<void> loadMoreSharedProblems(int roomId) async {
    if (!sharedProblemsHasNext ||
        isSharedProblemsLoadingMore ||
        _sharedProblemsNextCursor == null) {
      return;
    }
    isSharedProblemsLoadingMore = true;
    notifyListeners();
    try {
      final page = await _service.fetchSharedProblems(
        roomId,
        cursor: _sharedProblemsNextCursor,
      );
      sharedProblems = [...sharedProblems, ...page.content];
      _sharedProblemsNextCursor = page.nextCursor;
      sharedProblemsHasNext = page.hasNext;
    } finally {
      isSharedProblemsLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleSharedProblemReaction(
    int sharedProblemId,
    String emoji,
  ) async {
    final shared = sharedProblems
        .where((s) => s.sharedProblemId == sharedProblemId)
        .firstOrNull;
    if (shared == null) return;
    final emojiKey = _normalizeEmojiKey(emoji);
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    shared.reactions = await _service.toggleSharedProblemReaction(
      roomId: roomId,
      sharedProblemId: sharedProblemId,
      emoji: emojiKey,
    );
    notifyListeners();
  }

  Future<void> fetchSharedProblemComments(int sharedProblemId) async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    final all = <SharedProblemCommentModel>[];
    int? cursor;
    bool hasNext = true;
    while (hasNext) {
      final page = await _service.fetchSharedProblemComments(
        roomId: roomId,
        sharedProblemId: sharedProblemId,
        cursor: cursor,
        size: 50,
      );
      all.addAll(page.content);
      cursor = page.nextCursor;
      hasNext = page.hasNext && page.nextCursor != null;
    }
    sharedProblemComments[sharedProblemId] = all;
    notifyListeners();
  }

  Future<void> createSharedProblemComment(
    int sharedProblemId,
    String content,
  ) async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    final comment = await _service.createSharedProblemComment(
      roomId: roomId,
      sharedProblemId: sharedProblemId,
      content: content,
    );
    sharedProblemComments[sharedProblemId] = [
      ...(sharedProblemComments[sharedProblemId] ?? const []),
      comment,
    ];
    final shared = sharedProblems
        .where((problem) => problem.sharedProblemId == sharedProblemId)
        .firstOrNull;
    if (shared != null) {
      shared.commentCount = (shared.commentCount ?? 0) + 1;
    }
    notifyListeners();
  }

  Future<void> updateSharedProblemComment({
    required int sharedProblemId,
    required int commentId,
    required String content,
  }) async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    final updated = await _service.updateSharedProblemComment(
      roomId: roomId,
      sharedProblemId: sharedProblemId,
      commentId: commentId,
      content: content,
    );
    sharedProblemComments[sharedProblemId] =
        (sharedProblemComments[sharedProblemId] ?? const [])
            .map(
                (comment) => comment.commentId == commentId ? updated : comment)
            .toList();
    notifyListeners();
  }

  Future<void> deleteSharedProblemComment({
    required int sharedProblemId,
    required int commentId,
  }) async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    await _service.deleteSharedProblemComment(
      roomId: roomId,
      sharedProblemId: sharedProblemId,
      commentId: commentId,
    );
    sharedProblemComments[sharedProblemId] =
        (sharedProblemComments[sharedProblemId] ?? const [])
            .where((comment) => comment.commentId != commentId)
            .toList();
    final shared = sharedProblems
        .where((problem) => problem.sharedProblemId == sharedProblemId)
        .firstOrNull;
    if (shared != null) {
      final nextCount = (shared.commentCount ?? 1) - 1;
      shared.commentCount = nextCount < 0 ? 0 : nextCount;
    }
    notifyListeners();
  }

  Future<void> toggleSharedProblemCommentReaction({
    required int sharedProblemId,
    required int commentId,
    required String emoji,
  }) async {
    final comments = sharedProblemComments[sharedProblemId];
    final comment =
        comments?.where((c) => c.commentId == commentId).firstOrNull;
    if (comment == null) return;
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    final emojiKey = _normalizeEmojiKey(emoji);
    comment.reactions = await _service.toggleSharedProblemCommentReaction(
      roomId: roomId,
      sharedProblemId: sharedProblemId,
      commentId: commentId,
      emoji: emojiKey,
    );
    notifyListeners();
  }

  // ── E. 주간 리포트 ──

  Future<void> fetchWeeklyReport(int roomId, {bool notify = true}) async {
    final reports = await _service.fetchWeeklyReports(roomId: roomId);
    weeklyReport = reports.firstOrNull;
    if (notify) notifyListeners();
  }

  Future<void> markReportRead() async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    final report = weeklyReport;
    if (roomId != null && report != null) {
      await _service.markWeeklyReportRead(
        roomId: roomId,
        reportId: report.reportId,
      );
    }
    weeklyReport?.isRead = true;
    notifyListeners();
  }

  // ── F. 목표 설정 ──

  Future<void> setMyGoal(int goal) async {
    final roomId = selectedRoom?.roomId ?? _activeRoomId;
    if (roomId == null) return;
    final weeklyGoal = goal == 0 ? null : goal;
    final result = await _service.setMyGoal(
      roomId: roomId,
      weeklyGoal: weeklyGoal,
    );
    myWeeklyGoal = result.weeklyGoal;

    if (selectedRoom != null) {
      final updatedMembers = selectedRoom!.members.map((m) {
        if (m.userId != currentUserId) return m;
        return StudyRoomMemberModel(
          userId: m.userId,
          name: m.name,
          totalStudyLevel: m.totalStudyLevel,
          currentStreak: m.currentStreak,
          weeklyProblemCount: m.weeklyProblemCount,
          weeklyPracticeCount: m.weeklyPracticeCount,
          todayPracticeCount: m.todayPracticeCount,
          practicedToday: m.practicedToday,
          weeklyGoal: result.weeklyGoal,
          goalProgress: result.goalProgress,
        );
      }).toList();
      selectedRoom = selectedRoom!.copyWith(members: updatedMembers);
    }
    notifyListeners();
  }
}
