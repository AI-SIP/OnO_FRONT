// FolderModel.dart
import '../Problem/ProblemModelWithTemplate.dart';
import 'FolderThumbnailModel.dart';

class FolderModel {
  final int folderId;
  final String folderName;
  final FolderThumbnailModel? parentFolder;
  final List<ProblemModelWithTemplate> problems;
  final List<FolderThumbnailModel> subFolderList;
  final DateTime? createdAt;
  final DateTime? updateAt;

  FolderModel({
    required this.folderId,
    required this.folderName,
    this.parentFolder,
    required this.problems,
    required this.subFolderList,
    this.createdAt,
    this.updateAt,
  });

  factory FolderModel.fromJson(dynamic json) {
    // parentFolder: null or Map
    final parentJson = json['parentFolder'] as Map<String, dynamic>?;
    final parent =
        parentJson != null ? FolderThumbnailModel.fromJson(parentJson) : null;

    // problemList → problems
    final problemList = json['problemList'] as List<dynamic>? ?? [];
    final problems = problemList
        .map(
            (e) => ProblemModelWithTemplate.fromJson(e as Map<String, dynamic>))
        .toList();

    // subFolderList: List<Map> → List<FolderThumbnailModel>
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
      problems: problems,
      subFolderList: subFolderList,
      createdAt: created != null ? DateTime.parse(created) : null,
      updateAt: updated != null ? DateTime.parse(updated) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'folderId': folderId,
        'folderName': folderName,
        'parentFolder': parentFolder?.toJson(),
        'problemList': problems.map((e) => e.toJson()).toList(),
        'subFolderList': subFolderList.map((e) => e.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'updateAt': updateAt?.toIso8601String(),
      };
}
