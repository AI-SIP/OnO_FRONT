class ProblemThumbnailModel {
  final int problemId;
  final String reference;
  final String processImageUrl;
  final DateTime? createdAt;

  ProblemThumbnailModel(
      {required this.problemId,
      required this.reference,
      required this.processImageUrl,
      required this.createdAt});

  factory ProblemThumbnailModel.fromJson(Map<String, dynamic> json) {
    return ProblemThumbnailModel(
      problemId: json['problemId'],
      reference: json['reference'],
      processImageUrl: json['processImageUrl'],
      createdAt: json['createdAt'],
    );
  }
}
