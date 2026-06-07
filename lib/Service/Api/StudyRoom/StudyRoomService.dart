import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/StudyRoom/ActivityFeedModel.dart';
import 'package:ono/Model/StudyRoom/ChallengeModel.dart';
import 'package:ono/Model/StudyRoom/FeedReactionModel.dart';
import 'package:ono/Model/StudyRoom/InviteCodeModel.dart';
import 'package:ono/Model/StudyRoom/SharedProblemModel.dart';
import 'package:ono/Model/StudyRoom/StudyRoomModel.dart';
import 'package:ono/Model/StudyRoom/StudySessionModel.dart';
import 'package:ono/Model/StudyRoom/WeeklyReportModel.dart';

import '../HttpService.dart';

class CursorPage<T> {
  final List<T> content;
  final int? nextCursor;
  final bool hasNext;

  const CursorPage({
    required this.content,
    required this.nextCursor,
    required this.hasNext,
  });
}

class StudyRoomService {
  final HttpService httpService = HttpService();
  final String baseUrl = '${AppConfig.baseUrl}/api/study-room';

  Future<List<StudyRoomModel>> fetchMyRooms() async {
    final data = await httpService.sendRequest(method: 'GET', url: baseUrl);
    return _mapList(data, StudyRoomModel.fromJson);
  }

  Future<StudyRoomModel> fetchRoomDetail(int roomId) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$roomId',
    );
    return StudyRoomModel.fromJson(_asMap(data));
  }

  Future<StudyRoomModel> createRoom(String name) async {
    final data = await httpService.sendRequest(
      method: 'POST',
      url: baseUrl,
      body: {'name': name.trim()},
    );
    return StudyRoomModel.fromJson(_asMap(data));
  }

  Future<StudyRoomModel> joinRoom(String code) async {
    final data = await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/join',
      body: {'code': code},
    );
    return StudyRoomModel.fromJson(_asMap(data));
  }

  Future<void> leaveRoom(int roomId) async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/$roomId/leave',
    );
  }

  Future<void> deleteRoom(int roomId) async {
    await httpService.sendRequest(method: 'DELETE', url: '$baseUrl/$roomId');
  }

  Future<void> kickMember(int roomId, int memberId) async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/$roomId/members/$memberId',
    );
  }

  Future<InviteCodeModel> generateInviteCode(int roomId) async {
    final data = await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/$roomId/invite',
    );
    return InviteCodeModel.fromJson(_asMap(data));
  }

  Future<({int? weeklyGoal, int? goalProgress})> setMyGoal({
    required int roomId,
    required int? weeklyGoal,
  }) async {
    final data = await httpService.sendRequest(
      method: 'PUT',
      url: '$baseUrl/$roomId/members/me/goal',
      body: {'weeklyGoal': weeklyGoal},
    );
    final map = _asMap(data);
    return (
      weeklyGoal:
          map['weeklyGoal'] == null ? null : (map['weeklyGoal'] as num).toInt(),
      goalProgress: map['goalProgress'] == null
          ? null
          : (map['goalProgress'] as num).toInt(),
    );
  }

  Future<CursorPage<ActivityFeedModel>> fetchFeed(
    int roomId, {
    int? cursor,
    int size = 30,
  }) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$roomId/feed',
      queryParams: {
        if (cursor != null) 'cursor': cursor.toString(),
        'size': size.toString(),
      },
    );
    return _cursorPage(data, ActivityFeedModel.fromJson);
  }

  Future<List<FeedReactionModel>> toggleFeedReaction({
    required int roomId,
    required int feedId,
    required String emoji,
  }) async {
    final data = await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/$roomId/feed/$feedId/reactions',
      body: {'emoji': emoji},
    );
    return _mapList(_asMap(data)['reactions'], FeedReactionModel.fromJson);
  }

  Future<List<ChallengeModel>> fetchChallenges(int roomId) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$roomId/challenges',
    );
    return _mapList(data, ChallengeModel.fromJson);
  }

  Future<ChallengeModel> createChallenge({
    required int roomId,
    required String title,
    required String type,
    required String metric,
    required int targetValue,
    required DateTime endAt,
  }) async {
    final data = await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/$roomId/challenges',
      body: {
        'title': title,
        'type': type,
        'metric': metric,
        'targetValue': targetValue,
        'endAt': endAt.toIso8601String(),
      },
    );
    return ChallengeModel.fromJson(_asMap(data));
  }

  Future<void> deleteChallenge({
    required int roomId,
    required int challengeId,
  }) async {
    await httpService.sendRequest(
      method: 'DELETE',
      url: '$baseUrl/$roomId/challenges/$challengeId',
    );
  }

  Future<List<StudySessionModel>> fetchActiveSessions(int roomId) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$roomId/sessions/active',
    );
    return _mapList(
        _asMap(data)['activeSessions'], StudySessionModel.fromActiveJson);
  }

  Future<int?> startSession(int roomId) async {
    final data = await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/$roomId/sessions',
    );
    final map = _asMap(data);
    return map['sessionId'] == null ? null : (map['sessionId'] as num).toInt();
  }

  Future<void> endSession({
    required int roomId,
    required int sessionId,
  }) async {
    await httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl/$roomId/sessions/$sessionId/end',
    );
  }

  Future<CursorPage<SharedProblemModel>> fetchSharedProblems(
    int roomId, {
    int? cursor,
    int size = 20,
  }) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$roomId/shared-problems',
      queryParams: {
        if (cursor != null) 'cursor': cursor.toString(),
        'size': size.toString(),
      },
    );
    return _cursorPage(data, SharedProblemModel.fromJson);
  }

  Future<List<FeedReactionModel>> toggleSharedProblemReaction({
    required int roomId,
    required int sharedProblemId,
    required String emoji,
  }) async {
    final data = await httpService.sendRequest(
      method: 'POST',
      url: '$baseUrl/$roomId/shared-problems/$sharedProblemId/reactions',
      body: {'emoji': emoji},
    );
    return _mapList(_asMap(data)['reactions'], FeedReactionModel.fromJson);
  }

  Future<List<WeeklyReportModel>> fetchWeeklyReports({
    required int roomId,
    int limit = 4,
  }) async {
    final data = await httpService.sendRequest(
      method: 'GET',
      url: '$baseUrl/$roomId/weekly-reports',
      queryParams: {'limit': limit.toString()},
    );
    return _mapList(data, WeeklyReportModel.fromJson);
  }

  Future<bool> markWeeklyReportRead({
    required int roomId,
    required int reportId,
  }) async {
    final data = await httpService.sendRequest(
      method: 'PATCH',
      url: '$baseUrl/$roomId/weekly-reports/$reportId/read',
    );
    return _asMap(data)['isRead'] == true;
  }

  CursorPage<T> _cursorPage<T>(
    dynamic data,
    T Function(Map<String, dynamic>) parser,
  ) {
    final map = _asMap(data);
    return CursorPage<T>(
      content: _mapList(map['content'], parser),
      nextCursor:
          map['nextCursor'] == null ? null : (map['nextCursor'] as num).toInt(),
      hasNext: map['hasNext'] == true,
    );
  }

  List<T> _mapList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (data is! List) return <T>[];
    return data.whereType<Map<String, dynamic>>().map(parser).toList();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}
