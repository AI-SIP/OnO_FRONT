import 'package:ono/Model/Problem/ProblemModel.dart';

class ProblemThumbnailModel {
  final int problemId;
  final String? reference;
  final String? problemImageUrl;
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

  factory ProblemThumbnailModel.fromProblem(ProblemModel problemModel) {
    return ProblemThumbnailModel(
      problemId: problemModel.problemId,
      reference: problemModel.reference,
      problemImageUrl: problemModel.problemImageDataList != null
          ? problemModel.problemImageDataList![0].imageUrl
          : null,
      createdAt: problemModel.createdAt,
    );
  }
}
