class FeedReactionModel {
  final String emoji;
  int count;
  bool reactedByMe;

  FeedReactionModel({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
  });

  factory FeedReactionModel.fromJson(Map<String, dynamic> json) {
    return FeedReactionModel(
      emoji: (json['emoji'] ?? '').toString(),
      count: ((json['count'] ?? 0) as num).toInt(),
      reactedByMe: json['reactedByMe'] == true,
    );
  }
}
