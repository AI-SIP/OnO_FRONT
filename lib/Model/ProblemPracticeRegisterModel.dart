class ProblemPracticeRegisterModel {
  final int practiceCount;
  final String practiceTitle;
  final List<int> registerProblemIds;
  final List<int> removeProblemIds;

  ProblemPracticeRegisterModel({
    required this.practiceCount,
    required this.practiceTitle,
    required this.registerProblemIds,
    required this.removeProblemIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'practiceCount': practiceCount,
      'practiceTitle': practiceTitle,
      'registerProblemIds': registerProblemIds,
      'removeProblemIds': removeProblemIds,
    };
  }
}