class ProblemThumbnailModelWithTemplate {
  final int problemId;
  final String reference;
  final String processImageUrl;
  final DateTime? createdAt;

  ProblemThumbnailModelWithTemplate(
      {required this.problemId,
      required this.reference,
      required this.processImageUrl,
      required this.createdAt});

  factory ProblemThumbnailModelWithTemplate.fromJson(
      Map<String, dynamic> json) {
    return ProblemThumbnailModelWithTemplate(
      problemId: json['problemId'],
      reference: json['reference'],
      processImageUrl: json['processImageUrl'],
      createdAt: json['createdAt'],
    );
  }
}
