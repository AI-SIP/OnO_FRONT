import 'package:ono/Model/Problem/ProblemRepeatModel.dart';

import '../Common/ProblemImageDataType.dart';
import 'ProblemImageDataModel.dart';

class ProblemModel {
  final int problemId;
  final int? folderId;
  final String? memo;
  final String? reference;
  final DateTime? solvedAt;
  final DateTime? createdAt;
  final DateTime? updateAt;

  final List<ProblemImageDataModel>? problemImageDataList;
  final List<ProblemImageDataModel>? answerImageDataList;
  final List<ProblemRepeatModel>? repeats;

  ProblemModel({
    this.problemId = -1,
    this.folderId,
    this.memo,
    this.reference,
    this.solvedAt,
    this.createdAt,
    this.updateAt,
    this.problemImageDataList,
    this.answerImageDataList,
    this.repeats,
  });

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    final rawImageList = (json['imageUrlList'] as List<dynamic>?)
            ?.map((e) =>
                ProblemImageDataModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final problemImages = <ProblemImageDataModel>[];
    final answerImages = <ProblemImageDataModel>[];

    for (var img in rawImageList) {
      if (img.problemImageType == ProblemImageType.PROBLEM_IMAGE) {
        problemImages.add(img);
      } else if (img.problemImageType == ProblemImageType.ANSWER_IMAGE) {
        answerImages.add(img);
      }
    }
    return ProblemModel(
      problemId: json['problemId'] as int,
      folderId: json['folderId'] as int,
      memo: json['memo'] as String?,
      reference: json['reference'] as String?,
      solvedAt: json['solvedAt'] != null
          ? DateTime.parse(json['solvedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updateAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      problemImageDataList: problemImages,
      answerImageDataList: answerImages,
      repeats: (json['repeats'] as List<dynamic>?)
          ?.map((e) => ProblemRepeatModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String? _toIso(DateTime? dt) => dt?.toIso8601String();
}
