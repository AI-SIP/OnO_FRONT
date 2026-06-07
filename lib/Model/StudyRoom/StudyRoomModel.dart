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

  const StudyRoomModel({
    required this.roomId,
    required this.name,
    required this.hostUserId,
    required this.members,
    this.inviteCode,
    this.inviteExpiredAt,
    this.thumbnailImagePath,
    this.serverMemberCount,
  });

  int get memberCount => serverMemberCount ?? members.length;

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
    );
  }
}
