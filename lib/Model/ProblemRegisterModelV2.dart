import 'package:image_picker/image_picker.dart';
import 'package:ono/Model/TemplateType.dart';

class ProblemRegisterModelV2 {
  int? problemId;
  String? problemImageUrl;
  String? processImageUrl;
  XFile? solveImage;
  XFile? answerImage;
  String? memo;
  String? reference;
  DateTime? solvedAt;
  int? folderId;
  TemplateType? templateType;
  String? analysis;

  ProblemRegisterModelV2({
    this.problemId,
    this.problemImageUrl,
    this.processImageUrl,
    this.solveImage,
    this.answerImage,
    this.memo,
    this.reference,
    this.solvedAt,
    this.folderId,
    this.templateType,
    this.analysis,
  });

  Map<String, dynamic> toJson() {
    return {
      'problemId' : problemId,
      'problemImageUrl': problemImageUrl,
      'processImageUrl' : processImageUrl,
      'solveImage': solveImage,
      'answerImage': answerImage,
      'memo': memo,
      'reference': reference,
      'solvedAt': solvedAt?.subtract(const Duration(hours: 9)).toIso8601String(),
      'folderId' : folderId,
      'templateType' : templateType,
      'analysis' : analysis,
    };
  }

  factory ProblemRegisterModelV2.fromJson(Map<String, dynamic> json) {
    return ProblemRegisterModelV2(
      problemId: int.parse(json['problemId']),
      problemImageUrl: json['problemImageUrl'],
      processImageUrl: json['processImageUrl'],
      solveImage: json['solveImage'],
      answerImage: json['answerImage'],
      memo: json['memo'],
      reference: json['reference'],
      solvedAt: DateTime.parse(json['solvedAt']).subtract(const Duration(hours: 9)),
      folderId: int.parse(json['folderId']),
      templateType: json['templateType'],
      analysis: json['analysis'],
    );
  }
}
