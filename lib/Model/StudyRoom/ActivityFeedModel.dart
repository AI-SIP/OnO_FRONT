import 'FeedReactionModel.dart';

class ActivityFeedModel {
  final int feedId;
  final int userId;
  final String userName;
  final String eventType;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  List<FeedReactionModel> reactions;

  ActivityFeedModel({
    required this.feedId,
    required this.userId,
    required this.userName,
    required this.eventType,
    this.metadata,
    required this.createdAt,
    required this.reactions,
  });

  factory ActivityFeedModel.fromJson(Map<String, dynamic> json) {
    final reactionsJson = json['reactions'];
    return ActivityFeedModel(
      feedId: ((json['feedId'] ?? 0) as num).toInt(),
      userId: ((json['userId'] ?? 0) as num).toInt(),
      userName: (json['userName'] ?? '알 수 없음').toString(),
      eventType: (json['eventType'] ?? '').toString(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      reactions: reactionsJson is List
          ? reactionsJson
              .whereType<Map<String, dynamic>>()
              .map(FeedReactionModel.fromJson)
              .toList()
          : <FeedReactionModel>[],
    );
  }

  String get displayText {
    switch (eventType) {
      case 'problem_registered':
        final count = metadata?['count'] ?? 1;
        return '$userName 님이 오답노트 $count문제를 등록했어요';
      case 'practice_completed':
        return '$userName 님이 복습 세트를 완료했어요';
      case 'streak_milestone':
        final days = metadata?['days'] ?? 7;
        return '$userName 님이 $days일 연속 공부 중이에요';
      case 'level_up':
        final level = metadata?['level'] ?? 1;
        return '$userName 님이 레벨 $level이 됐어요';
      case 'challenge_cleared':
        return '$userName 님이 이번 주 챌린지를 완료했어요';
      case 'session_started':
        return '$userName 님이 공부 세션을 시작했어요';
      case 'problem_shared':
        return '$userName 님이 문제를 공유했어요';
      default:
        return '$userName 님의 활동';
    }
  }
}
