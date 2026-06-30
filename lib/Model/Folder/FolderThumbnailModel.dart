// FolderThumbnailModel.dart
class FolderThumbnailModel {
  final int folderId;
  final String folderName;
  final int problemCount;

  FolderThumbnailModel({
    required this.folderId,
    required this.folderName,
    this.problemCount = 0,
  });

  factory FolderThumbnailModel.fromJson(Map<String, dynamic> json) {
    return FolderThumbnailModel(
      folderId: json['folderId'] as int,
      folderName: json['folderName'] as String,
      problemCount: _parseProblemCount(json['problemCount']),
    );
  }

  static int _parseProblemCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'folderId': folderId,
        'folderName': folderName,
        'problemCount': problemCount,
      };
}
