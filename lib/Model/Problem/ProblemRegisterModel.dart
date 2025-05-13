import 'ProblemImageDataRegisterModel.dart';

class ProblemRegisterModel {
  int? problemId;
  String? memo;
  String? reference;
  int? folderId;
  DateTime? solvedAt;
  List<ProblemImageDataRegisterModel>? imageDataDtoList;

  ProblemRegisterModel({
    this.problemId,
    this.memo,
    this.reference,
    this.folderId,
    this.solvedAt,
    this.imageDataDtoList,
  });

  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'memo': memo,
      'reference': reference,
      'folderId': folderId,
      'solvedAt':
          solvedAt?.subtract(const Duration(hours: 9)).toIso8601String(),
      'imageDataDtoList': imageDataDtoList?.map((e) => e.toJson()).toList(),
    };
  }
}
