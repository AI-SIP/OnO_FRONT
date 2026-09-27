enum OnoEmojiCategory {
  emotion('감정', 'happy_tears'),
  study('공부', 'studying_together'),
  cheer('응원', 'celebrating_confetti'),
  social('소통', 'waving_hello'),
  leisure('여가', 'playing_game_controller');

  final String label;
  final String iconKey;

  const OnoEmojiCategory(this.label, this.iconKey);
}
