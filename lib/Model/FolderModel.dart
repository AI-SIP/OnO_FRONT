import 'package:ono/Model/FolderThumbnailModel.dart';
import 'ProblemModel.dart';

class FolderModel {
  int folderId;
  String folderName;
  FolderThumbnailModel? parentFolder;
  List<ProblemModel> problems = [];
  List<FolderThumbnailModel> subFolders = [];
  final DateTime? createdAt;
  final DateTime? updateAt;

  FolderModel({
    required this.folderId,
    required this.folderName,
    this.parentFolder,
    required this.problems,
    required this.subFolders,
    required this.createdAt,
    required this.updateAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      folderId: json['folderId'],
      folderName: json['folderName'],
      parentFolder: json['parentFolder'] != null
          ? FolderThumbnailModel.fromJson(json['parentFolder'])
          : null, // null 체크
      problems: (json['problems'] as List?)?.map((e) => ProblemModel.fromJson(e)).toList() ?? [], // null 체크
      subFolders: (json['subFolders'] as List?)?.map((e) => FolderThumbnailModel.fromJson(e)).toList() ?? [], // null 체크
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null, // null 체크
      updateAt: json['updateAt'] != null
          ? DateTime.parse(json['updateAt'])
          : null, // null 체크
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folderId': folderId,
      'folderName': folderName,
      'parentFolder': parentFolder?.toJson(),
      'problems': problems.map((e) => e.toJson()).toList(),
      'subFolders': subFolders.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updateAt': updateAt?.toIso8601String(),
    };
  }
}