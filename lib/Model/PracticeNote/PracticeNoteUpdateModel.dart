class PracticeNoteUpdateModel {
  final int practiceNoteId;
  String? practiceTitle;
  final List<int> addProblemIdList;
  final List<int> removeProblemIdList;

  PracticeNoteUpdateModel({
    required this.practiceNoteId,
    this.practiceTitle,
    required this.addProblemIdList,
    required this.removeProblemIdList,
  });

  void setPracticeTitle(String newTitle) {
    practiceTitle = newTitle;
  }

  Map<String, dynamic> toJson() {
    return {
      'practiceNoteId': practiceNoteId,
      'practiceTitle': practiceTitle,
      'addProblemIdList': addProblemIdList,
      'removeProblemIdList': removeProblemIdList,
    };
  }
}
