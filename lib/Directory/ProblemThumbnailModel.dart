import 'dart:convert';

class ProblemThumbnailModel {
  final int id;
  final String title;
  final String problemImageUrl;

  ProblemThumbnailModel({required this.id, required this.title, required this.problemImageUrl});

  factory ProblemThumbnailModel.fromJson(Map<String, dynamic> json) {
    return ProblemThumbnailModel(
      id: json['problemId'],
      title: json['reference'],
      problemImageUrl: json['problemImageUrl'],
    );
  }
}