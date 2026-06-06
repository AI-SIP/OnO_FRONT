class FeedReactionModel {
  final String emoji;
  int count;
  bool reactedByMe;

  FeedReactionModel({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
  });
}
