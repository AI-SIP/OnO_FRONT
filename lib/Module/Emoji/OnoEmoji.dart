import 'OnoEmojiCategory.dart';

class OnoEmoji {
  final String key;
  final String label;
  final OnoEmojiCategory category;

  const OnoEmoji({
    required this.key,
    required this.label,
    required this.category,
  });

  String get assetPath => 'assets/emoji/$key.png';
}
