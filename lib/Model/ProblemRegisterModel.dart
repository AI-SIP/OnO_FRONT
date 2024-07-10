import 'package:image_picker/image_picker.dart';

class ProblemRegisterModel {
  XFile? problemImage;
  XFile? solveImage;
  XFile? answerImage;
  String? memo;
  String? reference;
  DateTime? solvedAt;

  ProblemRegisterModel({
    this.problemImage,
    this.solveImage,
    this.answerImage,
    this.memo,
    this.reference,
    this.solvedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'problemImage': problemImage,
      'solveImage': solveImage,
      'answerImage': answerImage,
      'memo': memo,
      'reference': reference,
      'solvedAt': solvedAt?.toIso8601String(),
    };
  }

  factory ProblemRegisterModel.fromJson(Map<String, dynamic> json) {
    return ProblemRegisterModel(
      problemImage: json['problemImage'],
      solveImage: json['solveImage'],
      answerImage: json['answerImage'],
      memo: json['memo'],
      reference: json['reference'],
      solvedAt: DateTime.parse(json['solvedAt']),
    );
  }
}
