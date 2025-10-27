import 'ProblemAnalysisStatus.dart';

class ProblemAnalysisModel {
  final int? id;
  final int? problemId;
  final String? subject;
  final String? problemType;
  final List<String>? keyPoints;
  final String? solution;
  final String? commonMistakes;
  final String? studyTips;
  final ProblemAnalysisStatus? status;
  final String? errorMessage;

  ProblemAnalysisModel({
    this.id,
    this.problemId,
    this.subject,
    this.problemType,
    this.keyPoints,
    this.solution,
    this.commonMistakes,
    this.studyTips,
    this.status,
    this.errorMessage,
  });

  factory ProblemAnalysisModel.fromJson(Map<String, dynamic> json) {
    return ProblemAnalysisModel(
      id: json['id'] as int?,
      problemId: json['problemId'] as int?,
      subject: json['subject'] as String?,
      problemType: json['problemType'] as String?,
      keyPoints: (json['keyPoints'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      solution: json['solution'] as String?,
      commonMistakes: json['commonMistakes'] as String?,
      studyTips: json['studyTips'] as String?,
      status: ProblemAnalysisStatus.fromString(json['status'] as String?),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'problemId': problemId,
      'subject': subject,
      'problemType': problemType,
      'keyPoints': keyPoints,
      'solution': solution,
      'commonMistakes': commonMistakes,
      'studyTips': studyTips,
      'status': status?.toJson(),
      'errorMessage': errorMessage,
    };
  }
}