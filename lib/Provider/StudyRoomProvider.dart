import 'package:flutter/material.dart';

import '../Model/StudyRoom/ActivityFeedModel.dart';
import '../Model/StudyRoom/ChallengeModel.dart';
import '../Model/StudyRoom/InviteCodeModel.dart';
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
  List<ChallengeModel> challenges = [];
  List<StudySessionModel> activeSessions = [];
  List<SharedProblemModel> sharedProblems = [];
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
    if (notify) notifyListeners();
  }

  String _normalizeEmojiKey(String emoji) {
    return OnoEmojiCatalog.byKey(emoji)?.key ?? emoji;
  }

  String _toServerEmoji(String emoji) {
    const serverEmojiByKey = {
      'fired_up_sparkle_eyes': '🔥',
      'thumbs_up_happy': '👍',
      'celebrating_confetti': '🎉',
      'dizzy_spiral_eyes2': '😱',
    };
    return serverEmojiByKey[emoji] ?? emoji;
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
      emoji: _toServerEmoji(emojiKey),
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

  Future<void> shareProblems(String reference, String? comment) async {
    throw UnsupportedError('Problem sharing requires a backend problemId.');
  }

  Future<void> fetchSharedProblems(int roomId, {bool notify = true}) async {
    final page = await _service.fetchSharedProblems(roomId);
    sharedProblems = page.content;
    if (notify) notifyListeners();
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
      emoji: _toServerEmoji(emojiKey),
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
