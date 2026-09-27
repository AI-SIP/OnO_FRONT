class UserInfoModel {
  int userId;
  String? email;
  String? name;
  String? profileImageUrl;
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

  // 총 학습 레벨 관련 필드 (서버에서 계산됨)
  int totalStudyLevel;
  int totalStudyCurrentPoint;
  int totalStudyNextLevelThreshold;

  bool notificationEnabled;

  UserInfoModel({
    this.userId = -1,
    this.email = '',
    this.name = '',
    this.profileImageUrl,
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
    this.totalStudyLevel = 0,
    this.totalStudyCurrentPoint = 0,
    this.totalStudyNextLevelThreshold = 40,
    this.notificationEnabled = true,
  });

  factory UserInfoModel.fromJson(dynamic json) {
    return UserInfoModel(
      userId: json['userId'],
      email: json['email'],
      name: json['name'],
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      attendanceLevel: json['attendanceLevel'] ?? 1,
      attendancePoint: json['attendancePoint'] ?? 0,
      noteWriteLevel: json['noteWriteLevel'] ?? 1,
      noteWritePoint: json['noteWritePoint'] ?? 0,
      problemPracticeLevel: json['problemPracticeLevel'] ?? 1,
      problemPracticePoint: json['problemPracticePoint'] ?? 0,
      notePracticeLevel: json['notePracticeLevel'] ?? 1,
      notePracticePoint: json['notePracticePoint'] ?? 0,
      totalStudyLevel: json['totalStudyLevel'] ?? 0,
      totalStudyCurrentPoint: json['totalStudyCurrentPoint'] ?? 0,
      totalStudyNextLevelThreshold: json['totalStudyNextLevelThreshold'] ?? 40,
      notificationEnabled: json['notificationEnabled'] ?? true,
    );
  }
}
