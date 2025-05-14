class PracticeNoteRegisterModel {
  final int? practiceId;
  String practiceTitle;
  final List<int> registerProblemIdList;

  PracticeNoteRegisterModel({
    this.practiceId,
    required this.practiceTitle,
    required this.registerProblemIdList,
  });

  void setPracticeTitle(String newTitle) {
    practiceTitle = newTitle;
  }

  Map<String, dynamic> toJson() {
    return {
      'practiceId': practiceId,
      'practiceTitle': practiceTitle,
      'problemIdList': registerProblemIdList,
    };
  }
}
