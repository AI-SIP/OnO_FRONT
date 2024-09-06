import 'ProblemModel.dart';

class FolderThumbnailModel {
  int folderId;
  String folderName;

  FolderThumbnailModel({
    required this.folderId,
    required this.folderName,
  });

  // JSON 파싱 메서드
  factory FolderThumbnailModel.fromJson(Map<String, dynamic> json) {
    return FolderThumbnailModel(
      folderId: json['folderId'],
      folderName: json['folderName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folderId': folderId,
      'folderName': folderName,
    };
  }
}
