class ChallengeMemberProgressModel {
  final int userId;
  final String name;
  final int current;
  final bool cleared;

  const ChallengeMemberProgressModel({
    required this.userId,
    required this.name,
    required this.current,
    required this.cleared,
  });
}
