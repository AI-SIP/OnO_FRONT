import 'dart:convert';

class ProblemThumbnailModel {
  final int problemId;
  final String reference;
  final String problemImageUrl;

  ProblemThumbnailModel({required this.problemId, required this.reference, required this.problemImageUrl});

  factory ProblemThumbnailModel.fromJson(Map<String, dynamic> json) {
    return ProblemThumbnailModel(
      problemId: json['problemId'],
      reference: json['reference'],
      problemImageUrl: json['problemImageUrl'],
    );
  }
}