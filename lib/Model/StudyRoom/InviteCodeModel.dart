class InviteCodeModel {
  final String code;
  final DateTime expiredAt;

  const InviteCodeModel({required this.code, required this.expiredAt});

  bool get isExpired => DateTime.now().isAfter(expiredAt);

  factory InviteCodeModel.fromJson(Map<String, dynamic> json) {
    return InviteCodeModel(
      code: (json['code'] ?? '').toString(),
      expiredAt: DateTime.tryParse((json['expiredAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
