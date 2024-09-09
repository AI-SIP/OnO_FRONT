class FolderThumbnailModel {
  int folderId;
  String folderName;
  int? parentFolderId;
  List<int> subFoldersId;

  FolderThumbnailModel({
    required this.folderId,
    required this.folderName,
    this.parentFolderId,
    required this.subFoldersId,
  });

  // JSON 파싱 메서드
  factory FolderThumbnailModel.fromJson(Map<String, dynamic> json) {
    return FolderThumbnailModel(
      folderId: json['folderId'],
      folderName: json['folderName'],
      parentFolderId: json['parentFolderId'],
      subFoldersId: (json['subFoldersId'] as List<dynamic>)
          .map((id) => id as int)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folderId': folderId,
      'folderName': folderName,
      'parentFolderId': parentFolderId,
      'subFoldersId': subFoldersId,
    };
  }
}
