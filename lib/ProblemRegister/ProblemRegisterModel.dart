import 'dart:convert';
import 'dart:ffi';

class ProblemRegisterModel {
  String? imageUrl;
  String? solveImageUrl;
  String? answerImageUrl;
  String? memo;
  String? reference;
  DateTime? solvedAt;

  ProblemRegisterModel({
    this.imageUrl,
    this.solveImageUrl,
    this.answerImageUrl,
    this.memo,
    this.reference,
    this.solvedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'solveImageUrl': solveImageUrl,
      'answerImageUrl': answerImageUrl,
      'memo': memo,
      'reference': reference,
      'solvedAt': solvedAt?.toIso8601String(),
    };
  }

  factory ProblemRegisterModel.fromJson(Map<String, dynamic> json) {
    return ProblemRegisterModel(
      imageUrl: json['imageUrl'],
      solveImageUrl: json['solveImageUrl'],
      answerImageUrl: json['answerImageUrl'],
      memo: json['memo'],
      reference: json['reference'],
      solvedAt: DateTime.parse(json['solvedAt']),
    );
  }
}
