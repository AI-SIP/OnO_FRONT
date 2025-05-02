import 'ProblemModel.dart';

class FolderModel {
  int folderId;
  String folderName;
  int? parentFolderId;
  List<ProblemModel> problems = [];
  List<int>? subFolderIds = [];
  final DateTime? createdAt;
  final DateTime? updateAt;

  FolderModel({
    required this.folderId,
    required this.folderName,
    this.parentFolderId,
    required this.problems,
    this.subFolderIds,
    required this.createdAt,
    required this.updateAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      folderId: json['folderId'],
      folderName: json['folderName'],
      parentFolderId: json['parentFolderId'],
      problems: (json['problems'] as List?)?.map((e) => ProblemModel.fromJson(e)).toList() ?? [], // null 체크
      subFolderIds: json['subFolderIds'] != null
          ? List<int>.from(json['subFolderIds'])
          : [], // null이면 빈 리스트로 처리
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
      'parentFolderId': parentFolderId,
      'problems': problems.map((e) => e.toJson()).toList(),
      'subFolderIds': subFolderIds ?? [],
      'createdAt': createdAt?.toIso8601String(),
      'updateAt': updateAt?.toIso8601String(),
    };
  }
}