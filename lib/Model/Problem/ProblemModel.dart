import 'package:ono/Model/Problem/ProblemRepeatModel.dart';
import 'package:ono/Model/Problem/TemplateType.dart';

class ProblemImageDataModel {
  final String imageUrl;
  final String problemImageType;
  final DateTime createdAt;

  ProblemImageDataModel({
    required this.imageUrl,
    required this.problemImageType,
    required this.createdAt,
  });

  factory ProblemImageDataModel.fromJson(Map<String, dynamic> json) {
    return ProblemImageDataModel(
      imageUrl: json['imageUrl'] as String,
      problemImageType: json['problemImageType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'problemImageType': problemImageType,
        'createdAt': createdAt.toIso8601String(),
      };
}

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

  /// 새로 추가된 부분
  final List<ProblemImageDataModel> imageUrlList;

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
    required this.imageUrlList,
  });

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    // 3) imageUrlList 파싱
    final imageListJson = json['imageUrlList'] as List<dynamic>? ?? [];
    final imageUrlList = imageListJson
        .map((e) => ProblemImageDataModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProblemModel(
      problemId: json['problemId'] as int,
      memo: json['memo'] as String?,
      reference: json['reference'] as String?,
      // 아래 필드들은 API 에서 내려오는 것에 맞추어 필요하면 수정하세요.
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
      imageUrlList: imageUrlList,
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
      'repeats': repeats?.map((e) => e.toJson()).toList(),
      'solvedAt': _toIso(solvedAt),
      'createdAt': _toIso(createdAt),
      'updatedAt': _toIso(updateAt),
      'imageUrlList': imageUrlList.map((e) => e.toJson()).toList(),
    };
  }

  String? _toIso(DateTime? dt) => dt?.toIso8601String();
}
