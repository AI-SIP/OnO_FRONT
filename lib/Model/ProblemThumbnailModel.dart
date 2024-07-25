class ProblemThumbnailModel {
  final int problemId;
  final String reference;
  final String processImageUrl;

  ProblemThumbnailModel(
      {required this.problemId,
      required this.reference,
      required this.processImageUrl});

  factory ProblemThumbnailModel.fromJson(Map<String, dynamic> json) {
    return ProblemThumbnailModel(
      problemId: json['problemId'],
      reference: json['reference'],
      processImageUrl: json['processImageUrl'],
    );
  }
}
