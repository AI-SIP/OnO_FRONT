import 'ProblemImageDataRegisterModel.dart';

class ProblemRegisterModel {
  int? problemId;
  String? memo;
  String? reference;
  int? folderId;
  DateTime? solvedAt;
  List<ProblemImageDataRegisterModel>? imageDataDtoList;
  List<int>? tagIds;

  ProblemRegisterModel({
    this.problemId,
    this.memo,
    this.reference,
    this.folderId,
    this.solvedAt,
    this.imageDataDtoList,
    this.tagIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'memo': memo,
      'reference': reference,
      'folderId': folderId,
      'solvedAt': solvedAt?.toIso8601String(),
      'imageDataDtoList': imageDataDtoList?.map((e) => e.toJson()).toList(),
      'tagIds': tagIds,
    };
  }
}
