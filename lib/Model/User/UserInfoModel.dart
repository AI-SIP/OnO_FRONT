class UserInfoModel {
  int userId;
  String? email;
  String? name;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserInfoModel({
    this.userId = -1,
    this.email = '',
    this.name = '',
    this.createdAt = null,
    this.updatedAt = null,
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
    );
  }
}
