class UserInfoModel {
  int userId;
  String? email;
  String? name;
  DateTime? createdAt;
  DateTime? updatedAt;

  // 경험치 및 레벨 관련 필드
  int attendanceLevel;
  int attendancePoint;
  int noteWriteLevel;
  int noteWritePoint;
  int problemPracticeLevel;
  int problemPracticePoint;
  int notePracticeLevel;
  int notePracticePoint;

  UserInfoModel({
    this.userId = -1,
    this.email = '',
    this.name = '',
    this.createdAt = null,
    this.updatedAt = null,
    this.attendanceLevel = 1,
    this.attendancePoint = 0,
    this.noteWriteLevel = 1,
    this.noteWritePoint = 0,
    this.problemPracticeLevel = 1,
    this.problemPracticePoint = 0,
    this.notePracticeLevel = 1,
    this.notePracticePoint = 0,
  });

  factory UserInfoModel.fromJson(dynamic json) {
    return UserInfoModel(
      userId: json['userId'],
      email: json['email'],
      name: json['name'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).add(const Duration(hours: 9))
          : DateTime.now().subtract(const Duration(hours: 9)),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt']).add(const Duration(hours: 9))
          : DateTime.now().subtract(const Duration(hours: 9)),
      attendanceLevel: json['attendanceLevel'] ?? 1,
      attendancePoint: json['attendancePoint'] ?? 0,
      noteWriteLevel: json['noteWriteLevel'] ?? 1,
      noteWritePoint: json['noteWritePoint'] ?? 0,
      problemPracticeLevel: json['problemPracticeLevel'] ?? 1,
      problemPracticePoint: json['problemPracticePoint'] ?? 0,
      notePracticeLevel: json['notePracticeLevel'] ?? 1,
      notePracticePoint: json['notePracticePoint'] ?? 0,
    );
  }
}
