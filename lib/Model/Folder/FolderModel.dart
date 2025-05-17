// FolderModel.dart
import 'FolderThumbnailModel.dart';

class FolderModel {
  final int folderId;
  final String folderName;
  final FolderThumbnailModel? parentFolder;
  final List<int> problemIdList;
  final List<FolderThumbnailModel> subFolderList;
  final DateTime? createdAt;
  final DateTime? updateAt;

  FolderModel({
    required this.folderId,
    required this.folderName,
    this.parentFolder,
    required this.problemIdList,
    required this.subFolderList,
    this.createdAt,
    this.updateAt,
  });

  factory FolderModel.fromJson(dynamic json) {
    final parentJson = json['parentFolder'] as Map<String, dynamic>?;
    final parent =
        parentJson != null ? FolderThumbnailModel.fromJson(parentJson) : null;

    final problemIdDynamic = json['problemIdList'] as List<dynamic>? ?? [];
    final problemIdList = problemIdDynamic.map((e) => e as int).toList();

    final subListJson = json['subFolderList'] as List<dynamic>? ?? [];
    final subFolderList = subListJson
        .cast<Map<String, dynamic>>()
        .map((e) => FolderThumbnailModel.fromJson(e))
        .toList();

    // 날짜 파싱
    final created = json['createdAt'] as String?;
    final updated = json['updateAt'] as String?;

    return FolderModel(
      folderId: json['folderId'] as int,
      folderName: json['folderName'] as String,
      parentFolder: parent,
      problemIdList: problemIdList,
      subFolderList: subFolderList,
      createdAt: created != null ? DateTime.parse(created) : null,
      updateAt: updated != null ? DateTime.parse(updated) : null,
    );
  }
}
