import 'package:image_picker/image_picker.dart';

class ProblemRegisterModel {
  int? problemId;
  XFile? problemImage;
  XFile? answerImage;
  String? memo;
  String? reference;
  DateTime? solvedAt;
  int? folderId;

  ProblemRegisterModel({
    this.problemId,
    this.problemImage,
    this.answerImage,
    this.memo,
    this.reference,
    this.solvedAt,
    this.folderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'problemImage': problemImage,
      'answerImage': answerImage,
      'memo': memo,
      'reference': reference,
      'solvedAt':
          solvedAt?.subtract(const Duration(hours: 9)).toIso8601String(),
      'folderId': folderId,
    };
  }

  factory ProblemRegisterModel.fromJson(Map<String, dynamic> json) {
    return ProblemRegisterModel(
      problemId: int.parse(json['problemId']),
      problemImage: json['problemImage'],
      answerImage: json['answerImage'],
      memo: json['memo'],
      reference: json['reference'],
      solvedAt:
          DateTime.parse(json['solvedAt']).subtract(const Duration(hours: 9)),
      folderId: int.parse(json['folderId']),
    );
  }
}
