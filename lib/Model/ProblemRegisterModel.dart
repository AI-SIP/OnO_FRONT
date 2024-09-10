import 'package:image_picker/image_picker.dart';

class ProblemRegisterModel {
  int? problemId;
  XFile? problemImage;
  XFile? solveImage;
  XFile? answerImage;
  String? memo;
  String? reference;
  DateTime? solvedAt;
  int? folderId;
  bool? isProcess;
  List<Map<String, int>?>? colors;

  ProblemRegisterModel({
    this.problemId,
    this.problemImage,
    this.solveImage,
    this.answerImage,
    this.memo,
    this.reference,
    this.solvedAt,
    this.folderId,
    this.isProcess,
    this.colors
  });

  Map<String, dynamic> toJson() {
    return {
      'problemId' : problemId,
      'problemImage': problemImage,
      'solveImage': solveImage,
      'answerImage': answerImage,
      'memo': memo,
      'reference': reference,
      'solvedAt': solvedAt?.subtract(const Duration(hours: 9)).toIso8601String(),
      'folderId' : folderId,
      'isProcess' : isProcess,
      'colors' : colors?.map((color) => color).toList(),
    };
  }

  factory ProblemRegisterModel.fromJson(Map<String, dynamic> json) {
    return ProblemRegisterModel(
      problemId: int.parse(json['problemId']),
      problemImage: json['problemImage'],
      solveImage: json['solveImage'],
      answerImage: json['answerImage'],
      memo: json['memo'],
      reference: json['reference'],
      solvedAt: DateTime.parse(json['solvedAt']).subtract(const Duration(hours: 9)),
      folderId: int.parse(json['folderId']),
      isProcess : bool.parse(json['isProcess']),
      colors: json['colors'],
    );
  }
}
