import 'StudyRoomMemberModel.dart';

class StudyRoomModel {
  final int roomId;
  final String name;
  final int hostUserId;
  final List<StudyRoomMemberModel> members;
  final String? inviteCode;
  final DateTime? inviteExpiredAt;
  final String? thumbnailImagePath;
  final int? serverMemberCount;
  final int? todayPracticeMemberCount;
  final int? todayPracticeCount;
  final bool hasUnreadReport;

  const StudyRoomModel({
    required this.roomId,
    required this.name,
    required this.hostUserId,
    required this.members,
    this.inviteCode,
    this.inviteExpiredAt,
    this.thumbnailImagePath,
    this.serverMemberCount,
    this.todayPracticeMemberCount,
    this.todayPracticeCount,
    this.hasUnreadReport = false,
  });

  int get memberCount => serverMemberCount ?? members.length;

  int get displayTodayPracticeMemberCount =>
      todayPracticeMemberCount ??
      members.where((member) => member.hasPracticedToday).length;

  int get displayTodayPracticeCount =>
      todayPracticeCount ??
      members.fold<int>(
        0,
        (sum, member) => sum + member.displayTodayPracticeCount,
      );

  factory StudyRoomModel.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'];
    final members = membersJson is List
        ? membersJson
            .whereType<Map<String, dynamic>>()
            .map(StudyRoomMemberModel.fromJson)
            .toList()
        : <StudyRoomMemberModel>[];

    return StudyRoomModel(
      roomId: ((json['roomId'] ?? 0) as num).toInt(),
      name: (json['name'] ?? '').toString(),
      hostUserId: ((json['hostUserId'] ?? 0) as num).toInt(),
      members: members,
      thumbnailImagePath: json['thumbnailUrl'] as String?,
      serverMemberCount: json['memberCount'] == null
          ? null
          : (json['memberCount'] as num).toInt(),
      todayPracticeMemberCount: json['todayPracticeMemberCount'] == null
          ? null
          : (json['todayPracticeMemberCount'] as num).toInt(),
      todayPracticeCount: json['todayPracticeCount'] == null
          ? null
          : (json['todayPracticeCount'] as num).toInt(),
      hasUnreadReport: (json['hasUnreadReport'] as bool?) ?? false,
    );
  }

  StudyRoomModel copyWith({
    int? roomId,
    String? name,
    int? hostUserId,
    List<StudyRoomMemberModel>? members,
    String? inviteCode,
    DateTime? inviteExpiredAt,
    String? thumbnailImagePath,
    int? serverMemberCount,
    int? todayPracticeMemberCount,
    int? todayPracticeCount,
    bool? hasUnreadReport,
  }) {
    return StudyRoomModel(
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      hostUserId: hostUserId ?? this.hostUserId,
      members: members ?? this.members,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteExpiredAt: inviteExpiredAt ?? this.inviteExpiredAt,
      thumbnailImagePath: thumbnailImagePath ?? this.thumbnailImagePath,
      serverMemberCount: serverMemberCount ?? this.serverMemberCount,
      todayPracticeMemberCount:
          todayPracticeMemberCount ?? this.todayPracticeMemberCount,
      todayPracticeCount: todayPracticeCount ?? this.todayPracticeCount,
      hasUnreadReport: hasUnreadReport ?? this.hasUnreadReport,
    );
  }
}
