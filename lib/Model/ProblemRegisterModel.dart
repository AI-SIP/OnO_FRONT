import 'dart:convert';
import 'dart:ffi';

class Problem {

  int? userId;
  String? imageUrl;
  String? solveImageUrl;
  String? answerImageUrl;
  String? memo;
  String? reference;
  DateTime? solvedAt;

  Problem({
    this.userId,
    this.imageUrl,
    this.solveImageUrl,
    this.answerImageUrl,
    this.memo,
    this.reference,
    this.solvedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId' : userId,
      'imageUrl': imageUrl,
      'solveImageUrl': solveImageUrl,
      'answerImageUrl': answerImageUrl,
      'memo': memo,
      'reference': reference,
      'solvedAt': solvedAt?.toIso8601String(),
    };
  }

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      userId: json['userId'],
      imageUrl: json['imageUrl'],
      solveImageUrl: json['solveImageUrl'],
      answerImageUrl: json['answerImageUrl'],
      memo: json['memo'],
      reference: json['reference'],
      solvedAt: DateTime.parse(json['solvedAt']),
    );
  }
}