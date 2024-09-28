class FolderThumbnailModel {
  int folderId;
  String folderName;
  int? parentFolderId;
  List<int> subFoldersId;

  FolderThumbnailModel({
    required this.folderId,
    required this.folderName,
    this.parentFolderId,
    List<int>? subFoldersId,
  }): subFoldersId = subFoldersId ?? [];

  // JSON 파싱 메서드
  factory FolderThumbnailModel.fromJson(Map<String, dynamic> json) {
    return FolderThumbnailModel(
      folderId: json['folderId'],
      folderName: json['folderName'],
      parentFolderId: json['parentFolderId'],
      // null일 수 있는 필드 처리
      subFoldersId: json['subFoldersId'] != null
          ? List<int>.from(json['subFoldersId'])
          : [], // null이면 빈 리스트로 처리
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folderId': folderId,
      'folderName': folderName,
      'parentFolderId': parentFolderId,
      'subFoldersId': subFoldersId ?? [],
    };
  }
}