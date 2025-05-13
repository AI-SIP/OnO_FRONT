// FolderThumbnailModel.dart
class FolderThumbnailModel {
  final int folderId;
  final String folderName;

  FolderThumbnailModel({
    required this.folderId,
    required this.folderName,
  });

  factory FolderThumbnailModel.fromJson(Map<String, dynamic> json) {
    return FolderThumbnailModel(
      folderId: json['folderId'] as int,
      folderName: json['folderName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'folderId': folderId,
        'folderName': folderName,
      };
}
