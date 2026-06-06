import 'StudyRoomMemberModel.dart';

class StudyRoomModel {
  final int roomId;
  final String name;
  final int hostUserId;
  final List<StudyRoomMemberModel> members;
  final String? inviteCode;
  final DateTime? inviteExpiredAt;
  final String? thumbnailImagePath;

  const StudyRoomModel({
    required this.roomId,
    required this.name,
    required this.hostUserId,
    required this.members,
    this.inviteCode,
    this.inviteExpiredAt,
    this.thumbnailImagePath,
  });

  int get memberCount => members.length;

  StudyRoomModel copyWith({
    int? roomId,
    String? name,
    int? hostUserId,
    List<StudyRoomMemberModel>? members,
    String? inviteCode,
    DateTime? inviteExpiredAt,
    String? thumbnailImagePath,
  }) {
    return StudyRoomModel(
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      hostUserId: hostUserId ?? this.hostUserId,
      members: members ?? this.members,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteExpiredAt: inviteExpiredAt ?? this.inviteExpiredAt,
      thumbnailImagePath: thumbnailImagePath ?? this.thumbnailImagePath,
    );
  }
}
