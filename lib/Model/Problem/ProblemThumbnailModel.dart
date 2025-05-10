class ProblemThumbnailModel {
  final int problemId;
  final String reference;
  final String problemImageUrl;
  final DateTime? createdAt;

  ProblemThumbnailModel(
      {required this.problemId,
      required this.reference,
      required this.problemImageUrl,
      required this.createdAt});

  factory ProblemThumbnailModel.fromJson(Map<String, dynamic> json) {
    return ProblemThumbnailModel(
      problemId: json['problemId'],
      reference: json['reference'],
      problemImageUrl: json['problemImageUrl'],
      createdAt: json['createdAt'],
    );
  }
}
