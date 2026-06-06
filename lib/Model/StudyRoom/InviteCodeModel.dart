class InviteCodeModel {
  final String code;
  final DateTime expiredAt;

  const InviteCodeModel({required this.code, required this.expiredAt});

  bool get isExpired => DateTime.now().isAfter(expiredAt);
}
