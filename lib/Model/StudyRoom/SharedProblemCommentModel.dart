import 'FeedReactionModel.dart';

class SharedProblemCommentModel {
  final int commentId;
  final String content;
  final int authorId;
  final String authorName;
  final String? authorProfileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isMine;
  final bool canDelete;
  List<FeedReactionModel> reactions;

  SharedProblemCommentModel({
    required this.commentId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorProfileImageUrl,
    required this.createdAt,
    this.updatedAt,
    required this.isEdited,
    required this.isMine,
    required this.canDelete,
    required this.reactions,
  });

  factory SharedProblemCommentModel.fromJson(Map<String, dynamic> json) {
    final updatedAtText = json['updatedAt']?.toString();
    final reactionsJson = json['reactions'];
    return SharedProblemCommentModel(
      commentId: ((json['commentId'] ?? 0) as num).toInt(),
      content: (json['content'] ?? '').toString(),
      authorId: ((json['authorId'] ?? 0) as num).toInt(),
      authorName: (json['authorName'] ?? '알 수 없음').toString(),
      authorProfileImageUrl: (json['authorProfileImageUrl'] ??
          json['userProfileImageUrl'] ??
          json['profileImageUrl'] ??
          json['authorImageUrl']) as String?,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt:
          updatedAtText == null ? null : DateTime.tryParse(updatedAtText),
      isEdited: json['isEdited'] == true,
      isMine: json['isMine'] == true,
      canDelete: json['canDelete'] == true || json['isMine'] == true,
      reactions: reactionsJson is List
          ? reactionsJson
              .whereType<Map<String, dynamic>>()
              .map(FeedReactionModel.fromJson)
              .toList()
          : <FeedReactionModel>[],
    );
  }
}
