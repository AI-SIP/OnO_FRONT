class ChallengeMemberProgressModel {
  final int userId;
  final String name;
  final String? profileImageUrl;
  final int current;
  final bool cleared;

  const ChallengeMemberProgressModel({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    required this.current,
    required this.cleared,
  });

  factory ChallengeMemberProgressModel.fromJson(Map<String, dynamic> json) {
    return ChallengeMemberProgressModel(
      userId: ((json['userId'] ?? 0) as num).toInt(),
      name: (json['name'] ?? '알 수 없음').toString(),
      profileImageUrl: json['profileImageUrl'] as String?,
      current: ((json['current'] ?? 0) as num).toInt(),
      cleared: json['cleared'] == true,
    );
  }
}
