import 'package:ono/Model/Problem/ProblemRepeatModel.dart';
import 'package:ono/Model/Problem/TemplateType.dart';

import 'ProblemImageDataModel.dart';

/// 2) 기존 ProblemModel 에 imageUrlList 필드를 추가합니다.
class ProblemModel {
  final int problemId;
  final String? memo;
  final String? reference;
  final TemplateType? templateType;
  final String? analysis;
  final List<ProblemRepeatModel>? repeats;
  final DateTime? solvedAt;
  final DateTime? createdAt;
  final DateTime? updateAt;

  final List<ProblemImageDataModel> imageDataList;

  ProblemModel({
    this.problemId = -1,
    this.memo,
    this.reference,
    this.templateType,
    this.analysis,
    this.repeats,
    this.solvedAt,
    this.createdAt,
    this.updateAt,
    required this.imageDataList,
  });

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    final imageListJson = json['imageUrlList'] as List<dynamic>? ?? [];
    final imageUrlList = imageListJson
        .map((e) => ProblemImageDataModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProblemModel(
      problemId: json['problemId'] as int,
      memo: json['memo'] as String?,
      reference: json['reference'] as String?,
      templateType: json['templateType'] != null
          ? TemplateTypeExtension.fromTemplateTypeCode(json['templateType'])
          : null,
      analysis: json['analysis'] as String?,
      repeats: (json['repeats'] as List<dynamic>?)
          ?.map((e) => ProblemRepeatModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      solvedAt: json['solvedAt'] != null
          ? DateTime.parse(json['solvedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updateAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      imageDataList: imageUrlList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'memo': memo,
      'reference': reference,
      'templateType':
          templateType != null ? templateType!.name : null, // or code
      'analysis': analysis,
      //'repeats': repeats?.map((e) => e.toJson()).toList(),
      'solvedAt': _toIso(solvedAt),
      'createdAt': _toIso(createdAt),
      'updatedAt': _toIso(updateAt),
      'imageUrlList': imageDataList.map((e) => e.toJson()).toList(),
    };
  }

  String? _toIso(DateTime? dt) => dt?.toIso8601String();
}
