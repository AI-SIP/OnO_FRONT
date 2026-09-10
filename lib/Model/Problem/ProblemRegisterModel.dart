import 'ProblemImageDataRegisterModel.dart';

class ProblemRegisterModel {
  /// 서버 problem.memo 컬럼 길이. 넘겨 보내면 DB 에서 잘리며 500 이 떨어진다.
  static const int memoMaxLength = 1000;

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
