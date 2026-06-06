import 'dart:math';

import 'package:flutter/material.dart';

import '../Model/StudyRoom/ActivityFeedModel.dart';
import '../Model/StudyRoom/ChallengeModel.dart';
import '../Model/StudyRoom/ChallengeMemberProgressModel.dart';
import '../Model/StudyRoom/FeedReactionModel.dart';
import '../Model/StudyRoom/InviteCodeModel.dart';
import '../Model/StudyRoom/SharedProblemModel.dart';
import '../Model/StudyRoom/StudyRoomMemberModel.dart';
import '../Model/StudyRoom/StudyRoomModel.dart';
import '../Model/StudyRoom/StudySessionModel.dart';
import '../Model/StudyRoom/WeeklyReportModel.dart';

class StudyRoomProvider extends ChangeNotifier {
  List<StudyRoomModel> rooms = [];
  StudyRoomModel? selectedRoom;
  bool isLoading = false;

  // 더미: 활동 피드
  List<ActivityFeedModel> feedItems = [];

  // 더미: 챌린지
  List<ChallengeModel> challenges = [];

  // 더미: 현재 공부 중인 멤버
  List<StudySessionModel> activeSessions = [];

  // 더미: 공유된 문제
  List<SharedProblemModel> sharedProblems = [];

  // 더미: 주간 리포트 (roomId → report)
  WeeklyReportModel? weeklyReport;

  // 더미: 내 목표
  int? myWeeklyGoal;

  static const int _myUserId = 1;

  static const StudyRoomMemberModel _me = StudyRoomMemberModel(
    userId: _myUserId,
    name: '나',
    totalStudyLevel: 15,
    currentStreak: 7,
    weeklyProblemCount: 12,
    weeklyPracticeCount: 5,
    weeklyGoal: 20,
    goalProgress: 12,
  );

  StudyRoomProvider() {
    _loadDummyData();
  }

  void _loadDummyData() {
    rooms = [
      StudyRoomModel(
        roomId: 1,
        name: '수능 준비방',
        hostUserId: _myUserId,
        members: [
          _me,
          const StudyRoomMemberModel(
            userId: 2,
            name: '김민준',
            totalStudyLevel: 22,
            currentStreak: 14,
            weeklyProblemCount: 18,
            weeklyPracticeCount: 8,
            weeklyGoal: 15,
            goalProgress: 18,
          ),
          const StudyRoomMemberModel(
            userId: 3,
            name: '이서연',
            totalStudyLevel: 9,
            currentStreak: 3,
            weeklyProblemCount: 5,
            weeklyPracticeCount: 2,
          ),
          const StudyRoomMemberModel(
            userId: 4,
            name: '박지훈',
            totalStudyLevel: 31,
            currentStreak: 21,
            weeklyProblemCount: 25,
            weeklyPracticeCount: 11,
            weeklyGoal: 25,
            goalProgress: 25,
          ),
        ],
        inviteCode: '391820',
        inviteExpiredAt: DateTime.now().add(const Duration(hours: 24)),
      ),
    ];

    _loadDummyFeed();
    _loadDummyChallenges();
    _loadDummyActiveSessions();
    _loadDummySharedProblems();
    _loadDummyWeeklyReport();
  }

  void _loadDummyFeed() {
    final now = DateTime.now();
    feedItems = [
      ActivityFeedModel(
        feedId: 1,
        userId: 4,
        userName: '박지훈',
        eventType: 'problem_registered',
        metadata: {'count': 3},
        createdAt: now.subtract(const Duration(minutes: 20)),
        reactions: [
          FeedReactionModel(emoji: '🔥', count: 2, reactedByMe: true),
          FeedReactionModel(emoji: '👍', count: 1, reactedByMe: false),
        ],
      ),
      ActivityFeedModel(
        feedId: 2,
        userId: 2,
        userName: '김민준',
        eventType: 'streak_milestone',
        metadata: {'days': 14},
        createdAt: now.subtract(const Duration(hours: 1)),
        reactions: [
          FeedReactionModel(emoji: '🎉', count: 3, reactedByMe: false),
        ],
      ),
      ActivityFeedModel(
        feedId: 3,
        userId: 3,
        userName: '이서연',
        eventType: 'practice_completed',
        metadata: {},
        createdAt: now.subtract(const Duration(hours: 3)),
        reactions: [],
      ),
      ActivityFeedModel(
        feedId: 4,
        userId: _myUserId,
        userName: '나',
        eventType: 'level_up',
        metadata: {'level': 15},
        createdAt: now.subtract(const Duration(hours: 5)),
        reactions: [
          FeedReactionModel(emoji: '🎉', count: 4, reactedByMe: false),
        ],
      ),
      ActivityFeedModel(
        feedId: 5,
        userId: 4,
        userName: '박지훈',
        eventType: 'challenge_cleared',
        metadata: {},
        createdAt: now.subtract(const Duration(hours: 8)),
        reactions: [
          FeedReactionModel(emoji: '🔥', count: 1, reactedByMe: false),
        ],
      ),
    ];
  }

  void _loadDummyChallenges() {
    final now = DateTime.now();
    challenges = [
      ChallengeModel(
        challengeId: 1,
        title: '이번 주 문제 10개 등록하기',
        type: 'individual',
        metric: 'weekly_problem_count',
        targetValue: 10,
        endAt: now.add(const Duration(days: 2)),
        status: 'in_progress',
        memberProgress: [
          const ChallengeMemberProgressModel(
              userId: 1, name: '나', current: 12, cleared: true),
          const ChallengeMemberProgressModel(
              userId: 2, name: '김민준', current: 7, cleared: false),
          const ChallengeMemberProgressModel(
              userId: 3, name: '이서연', current: 5, cleared: false),
          const ChallengeMemberProgressModel(
              userId: 4, name: '박지훈', current: 25, cleared: true),
        ],
      ),
      ChallengeModel(
        challengeId: 2,
        title: '방 전체 문제 100개 등록하기',
        type: 'group',
        metric: 'weekly_problem_count',
        targetValue: 100,
        endAt: now.add(const Duration(days: 5)),
        status: 'in_progress',
        memberProgress: [],
        groupCurrent: 60,
      ),
    ];
  }

  void _loadDummyActiveSessions() {
    activeSessions = [
      StudySessionModel(
        userId: 2,
        name: '김민준',
        startedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
    ];
  }

  void _loadDummySharedProblems() {
    sharedProblems = [
      SharedProblemModel(
        sharedProblemId: 1,
        sharedByUserId: 4,
        sharedByName: '박지훈',
        reference: '2024 수능 수학 15번',
        comment: '이 문제 진짜 어렵다... 같이 풀어봐요!',
        sharedAt: DateTime.now().subtract(const Duration(hours: 2)),
        reactions: [
          FeedReactionModel(emoji: '😱', count: 3, reactedByMe: false),
          FeedReactionModel(emoji: '🔥', count: 1, reactedByMe: true),
        ],
      ),
      SharedProblemModel(
        sharedProblemId: 2,
        sharedByUserId: 2,
        sharedByName: '김민준',
        reference: '2023 모의고사 영어 32번',
        comment: null,
        sharedAt: DateTime.now().subtract(const Duration(days: 1)),
        reactions: [],
      ),
    ];
  }

  void _loadDummyWeeklyReport() {
    weeklyReport = WeeklyReportModel(
      reportId: 1,
      topMemberName: '박지훈',
      topMemberProblemCount: 25,
      longestStreakName: '박지훈',
      longestStreakDays: 21,
      totalProblems: 60,
      challengesCompleted: 1,
      cheerMessage: '이번 주도 모두 고생했어요! 다음 주도 화이팅 💪',
      isRead: false,
    );
  }

  bool isHost(StudyRoomModel room) => room.hostUserId == _myUserId;

  // ── 기존 방 CRUD ──

  Future<void> fetchMyRooms() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRoomDetail(int roomId) async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));
    selectedRoom = rooms.where((r) => r.roomId == roomId).firstOrNull;
    isLoading = false;
    notifyListeners();
  }

  Future<StudyRoomModel> createRoom(String name) async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    final newRoom = StudyRoomModel(
      roomId: rooms.length + 1,
      name: name.trim(),
      hostUserId: _myUserId,
      members: [_me],
      inviteCode: _generateCode(),
      inviteExpiredAt: DateTime.now().add(const Duration(hours: 24)),
    );
    rooms = [...rooms, newRoom];
    isLoading = false;
    notifyListeners();
    return newRoom;
  }

  Future<void> joinRoom(String code) async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    if (code != '123456') {
      isLoading = false;
      notifyListeners();
      throw Exception('유효하지 않은 초대 코드입니다');
    }
    final joinedRoom = StudyRoomModel(
      roomId: rooms.length + 1,
      name: '친구의 스터디방',
      hostUserId: 99,
      members: [
        const StudyRoomMemberModel(
          userId: 99,
          name: '최유진',
          totalStudyLevel: 18,
          currentStreak: 10,
          weeklyProblemCount: 14,
          weeklyPracticeCount: 6,
        ),
        _me,
      ],
      inviteCode: code,
      inviteExpiredAt: DateTime.now().add(const Duration(hours: 20)),
    );
    rooms = [...rooms, joinedRoom];
    isLoading = false;
    notifyListeners();
  }

  Future<void> leaveRoom(int roomId) async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    rooms = rooms.where((r) => r.roomId != roomId).toList();
    if (selectedRoom?.roomId == roomId) selectedRoom = null;
    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRoom(int roomId) async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    rooms = rooms.where((r) => r.roomId != roomId).toList();
    if (selectedRoom?.roomId == roomId) selectedRoom = null;
    isLoading = false;
    notifyListeners();
  }

  Future<void> kickMember(int roomId, int memberId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    rooms = rooms.map((r) {
      if (r.roomId != roomId) return r;
      return r.copyWith(
        members: r.members.where((m) => m.userId != memberId).toList(),
      );
    }).toList();
    if (selectedRoom?.roomId == roomId) {
      selectedRoom = rooms.where((r) => r.roomId == roomId).firstOrNull;
    }
    notifyListeners();
  }

  void updateRoomThumbnail(int roomId, String imagePath) {
    rooms = rooms.map((r) {
      if (r.roomId != roomId) return r;
      return r.copyWith(thumbnailImagePath: imagePath);
    }).toList();
    if (selectedRoom?.roomId == roomId) {
      selectedRoom = selectedRoom!.copyWith(thumbnailImagePath: imagePath);
    }
    notifyListeners();
  }

  Future<InviteCodeModel> generateInviteCode(int roomId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final room = rooms.where((r) => r.roomId == roomId).firstOrNull;
    if (room == null) throw Exception('방을 찾을 수 없습니다');
    return InviteCodeModel(
      code: room.inviteCode ?? _generateCode(),
      expiredAt:
          room.inviteExpiredAt ?? DateTime.now().add(const Duration(hours: 24)),
    );
  }

  // ── A. 활동 피드 ──

  Future<void> fetchFeed(int roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners();
  }

  void toggleFeedReaction(int feedId, String emoji) {
    final feed = feedItems.where((f) => f.feedId == feedId).firstOrNull;
    if (feed == null) return;

    final existing = feed.reactions.where((r) => r.emoji == emoji).firstOrNull;
    if (existing != null) {
      if (existing.reactedByMe) {
        existing.count--;
        existing.reactedByMe = false;
        if (existing.count <= 0) feed.reactions.remove(existing);
      } else {
        existing.count++;
        existing.reactedByMe = true;
      }
    } else {
      feed.reactions.add(
        FeedReactionModel(emoji: emoji, count: 1, reactedByMe: true),
      );
    }
    notifyListeners();
  }

  // ── B. 챌린지 ──

  Future<void> fetchChallenges(int roomId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    notifyListeners();
  }

  Future<void> createChallenge({
    required String title,
    required String type,
    required int targetValue,
    required DateTime endAt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final members = selectedRoom?.members ?? [];
    final newChallenge = ChallengeModel(
      challengeId: challenges.length + 1,
      title: title,
      type: type,
      metric: 'weekly_problem_count',
      targetValue: targetValue,
      endAt: endAt,
      status: 'in_progress',
      memberProgress: type == 'individual' || type == 'streak'
          ? members
              .map((m) => ChallengeMemberProgressModel(
                    userId: m.userId,
                    name: m.name,
                    current: m.weeklyProblemCount,
                    cleared: m.weeklyProblemCount >= targetValue,
                  ))
              .toList()
          : [],
      groupCurrent: type == 'group'
          ? members.fold<int>(0, (sum, m) => sum + m.weeklyProblemCount)
          : null,
    );
    challenges = [...challenges, newChallenge];
    notifyListeners();
  }

  Future<void> deleteChallenge(int challengeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    challenges = challenges.where((c) => c.challengeId != challengeId).toList();
    notifyListeners();
  }

  // ── C. 공부 세션 ──

  void addMySession() {
    if (activeSessions.any((s) => s.userId == _myUserId)) return;
    activeSessions = [
      ...activeSessions,
      StudySessionModel(
        userId: _myUserId,
        name: '나',
        startedAt: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  void removeMySession() {
    activeSessions =
        activeSessions.where((s) => s.userId != _myUserId).toList();
    notifyListeners();
  }

  // ── D. 문제 공유 ──

  Future<void> shareProblems(String reference, String? comment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newShared = SharedProblemModel(
      sharedProblemId: sharedProblems.length + 1,
      sharedByUserId: _myUserId,
      sharedByName: '나',
      reference: reference,
      comment: comment,
      sharedAt: DateTime.now(),
      reactions: [],
    );
    sharedProblems = [newShared, ...sharedProblems];

    // 피드에도 추가
    feedItems = [
      ActivityFeedModel(
        feedId: feedItems.length + 100,
        userId: _myUserId,
        userName: '나',
        eventType: 'problem_shared',
        metadata: {'reference': reference},
        createdAt: DateTime.now(),
        reactions: [],
      ),
      ...feedItems,
    ];
    notifyListeners();
  }

  void toggleSharedProblemReaction(int sharedProblemId, String emoji) {
    final shared = sharedProblems
        .where((s) => s.sharedProblemId == sharedProblemId)
        .firstOrNull;
    if (shared == null) return;

    final existing =
        shared.reactions.where((r) => r.emoji == emoji).firstOrNull;
    if (existing != null) {
      if (existing.reactedByMe) {
        existing.count--;
        existing.reactedByMe = false;
        if (existing.count <= 0) shared.reactions.remove(existing);
      } else {
        existing.count++;
        existing.reactedByMe = true;
      }
    } else {
      shared.reactions.add(
        FeedReactionModel(emoji: emoji, count: 1, reactedByMe: true),
      );
    }
    notifyListeners();
  }

  // ── E. 주간 리포트 ──

  void markReportRead() {
    weeklyReport?.isRead = true;
    notifyListeners();
  }

  // ── F. 목표 설정 ──

  Future<void> setMyGoal(int goal) async {
    await Future.delayed(const Duration(milliseconds: 200));
    myWeeklyGoal = goal;

    // selectedRoom 내 내 멤버 데이터도 반영 (더미)
    if (selectedRoom != null) {
      final updatedMembers = selectedRoom!.members.map((m) {
        if (m.userId != _myUserId) return m;
        return StudyRoomMemberModel(
          userId: m.userId,
          name: m.name,
          totalStudyLevel: m.totalStudyLevel,
          currentStreak: m.currentStreak,
          weeklyProblemCount: m.weeklyProblemCount,
          weeklyPracticeCount: m.weeklyPracticeCount,
          weeklyGoal: goal,
          goalProgress: m.weeklyProblemCount,
        );
      }).toList();
      selectedRoom = selectedRoom!.copyWith(members: updatedMembers);
    }
    notifyListeners();
  }

  String _generateCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }
}
