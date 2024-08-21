class ProblemThumbnailModel {
  final int problemId;
  final String reference;
  final String processImageUrl;
  final DateTime? updateAt;

  ProblemThumbnailModel(
      {required this.problemId,
      required this.reference,
      required this.processImageUrl, required this.updateAt});

  factory ProblemThumbnailModel.fromJson(Map<String, dynamic> json) {
    return ProblemThumbnailModel(
      problemId: json['problemId'],
      reference: json['reference'],
      processImageUrl: json['processImageUrl'],
      updateAt: json['updateAt'],
    );
  }
}
