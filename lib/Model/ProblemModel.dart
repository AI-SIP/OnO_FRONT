import 'package:intl/intl.dart';
import 'package:ono/Model/TemplateType.dart';

class ProblemModel {
  final int? problemId;
  final String? processImageUrl;
  final String? problemImageUrl;
  final String? solveImageUrl;
  final String? answerImageUrl;
  final String? memo;
  final String? reference;
  final int? folderId;
  final TemplateType? templateType;
  final String? analysis;
  final DateTime? solvedAt;
  final DateTime? createdAt;
  final DateTime? updateAt;

  ProblemModel({
    this.problemId,
    this.processImageUrl,
    this.problemImageUrl,
    this.solveImageUrl,
    this.answerImageUrl,
    this.memo,
    this.reference,
    this.folderId,
    this.templateType,
    this.analysis,
    this.solvedAt,
    this.createdAt,
    this.updateAt,
  });

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    return ProblemModel(
      problemId: json['problemId'],
      problemImageUrl: json['problemImageUrl'],
      solveImageUrl: json['solveImageUrl'],
      answerImageUrl: json['answerImageUrl'],
      processImageUrl: json['processImageUrl'],
      memo: json['memo'],
      reference: json['reference'],
      folderId: json['folderId'],
      templateType: TemplateTypeExtension.fromTemplateTypeCode(json['templateType']) ?? TemplateType.simple,
      analysis: json['analysis'],
      solvedAt:
          json['solvedAt'] != null ? DateTime.parse(json['solvedAt']).subtract(const Duration(hours: 9)) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).add(const Duration(hours: 9)) : DateTime.parse(json['solvedAt']).subtract(const Duration(hours: 9)),
      updateAt: json['updateAt'] != null ? DateTime.parse(json['updateAt']).add(const Duration(hours: 9)) : DateTime.parse(json['solvedAt']).subtract(const Duration(hours: 9)),

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'processImageUrl': processImageUrl,
      'problemImageUrl': problemImageUrl,
      'solveImageUrl': solveImageUrl,
      'answerImageUrl': answerImageUrl,
      'memo': memo,
      'reference': reference,
      'folderId': folderId,
      'templateType' : templateType,
      'analysis' : analysis,
      'solvedAt': _formatDateTime(solvedAt),
      'createdAt' : _formatDateTime(createdAt),
      'updateAt' : _formatDateTime(updateAt),
    };
  }

  // 날짜 포맷팅 함수
  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}
