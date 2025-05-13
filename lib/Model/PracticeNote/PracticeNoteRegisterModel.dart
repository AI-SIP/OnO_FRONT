class PracticeNoteRegisterModel {
  final int? practiceId;
  String practiceTitle;
  final List<int> registerProblemIds;

  PracticeNoteRegisterModel({
    this.practiceId,
    required this.practiceTitle,
    required this.registerProblemIds,
  });

  void setPracticeTitle(String newTitle) {
    practiceTitle = newTitle;
  }

  Map<String, dynamic> toJson() {
    return {
      'practiceId': practiceId,
      'practiceTitle': practiceTitle,
      'registerProblemIds': registerProblemIds,
    };
  }
}
