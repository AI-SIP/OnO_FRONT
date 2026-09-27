class PracticeNoteThumbnails {
  final int practiceId;
  final String practiceTitle;
  int practiceCount;
  final DateTime? lastSolvedAt;
  final String? lastSessionMoodEmojiKey;

  PracticeNoteThumbnails({
    required this.practiceId,
    required this.practiceTitle,
    required this.practiceCount,
    required this.lastSolvedAt,
    this.lastSessionMoodEmojiKey,
  });

  factory PracticeNoteThumbnails.fromJson(Map<String, dynamic> json) {
    return PracticeNoteThumbnails(
      practiceId: json['practiceNoteId'],
      practiceTitle: json['practiceTitle'] ?? '제목 없음',
      practiceCount: json['practiceCount'] ?? 0,
      lastSolvedAt: json['lastSolvedAt'] != null
          ? DateTime.parse(json['lastSolvedAt'])
          : null,
      lastSessionMoodEmojiKey: json['lastSessionMoodEmojiKey']?.toString(),
    );
  }

  void addPracticeCount() {
    practiceCount += 1;
  }
}
