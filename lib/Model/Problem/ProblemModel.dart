import 'package:ono/Model/Problem/ProblemRepeatModel.dart';

import 'ProblemImageDataModel.dart';

/// 2) 기존 ProblemModel 에 imageUrlList 필드를 추가합니다.
class ProblemModel {
  final int problemId;
  final int? folderId;
  final String? memo;
  final String? reference;
  final List<ProblemRepeatModel>? repeats;
  final DateTime? solvedAt;
  final DateTime? createdAt;
  final DateTime? updateAt;

  final List<ProblemImageDataModel> imageDataList;

  ProblemModel({
    this.problemId = -1,
    this.folderId,
    this.memo,
    this.reference,
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
      folderId: json['folderId'] as int,
      memo: json['memo'] as String?,
      reference: json['reference'] as String?,
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
      'folderId': folderId,
      'memo': memo,
      'reference': reference,
      //'repeats': repeats?.map((e) => e.toJson()).toList(),
      'solvedAt': _toIso(solvedAt),
      'createdAt': _toIso(createdAt),
      'updatedAt': _toIso(updateAt),
      'imageUrlList': imageDataList.map((e) => e.toJson()).toList(),
    };
  }

  String? _toIso(DateTime? dt) => dt?.toIso8601String();
}
