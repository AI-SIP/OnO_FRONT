class ProblemPracticeModel {
  final int practiceId;
  final String practiceTitle;
  final int practiceCount;
  final int practiceSize;

  ProblemPracticeModel({
    required this.practiceId,
    required this.practiceTitle,
    required this.practiceCount,
    required this.practiceSize,
  });

  factory ProblemPracticeModel.fromJson(Map<String, dynamic> json) {
    return ProblemPracticeModel(
      practiceId: json['practiceId'],
      practiceTitle: json['practiceTitle'],
      practiceCount: json['practiceCount'],
      practiceSize: json['practiceSize'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'practiceId': practiceId,
      'practiceTitle': practiceTitle,
      'practiceCount': practiceCount,
      'practiceSize': practiceSize,
    };
  }
}