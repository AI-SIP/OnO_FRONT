class FolderRegisterModel {
  final String folderName;
  final int? folderId;
  final int parentFolderId;

  FolderRegisterModel({
    required this.folderName,
    this.folderId,
    required this.parentFolderId,
  });

  Map<String, dynamic> toJson() => {
        'folderName': folderName,
        'folderId': folderId,
        'parentFolderId': parentFolderId,
      };
}
