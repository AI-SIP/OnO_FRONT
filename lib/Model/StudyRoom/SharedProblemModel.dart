import 'FeedReactionModel.dart';

class SharedProblemModel {
  final int sharedProblemId;
  final int sharedByUserId;
  final String sharedByName;
  final String? sharedByProfileImageUrl;
  final int? problemId;
  final List<String> problemImageUrls;
  final String reference;
  final String? comment;
  int? commentCount;
  final DateTime sharedAt;
  List<FeedReactionModel> reactions;

  SharedProblemModel({
    required this.sharedProblemId,
    required this.sharedByUserId,
    required this.sharedByName,
    this.sharedByProfileImageUrl,
    this.problemId,
    required this.problemImageUrls,
    required this.reference,
    this.comment,
    this.commentCount,
    required this.sharedAt,
    required this.reactions,
  });

  factory SharedProblemModel.fromJson(Map<String, dynamic> json) {
    final reactionsJson = json['reactions'];
    return SharedProblemModel(
      sharedProblemId: ((json['sharedProblemId'] ?? 0) as num).toInt(),
      sharedByUserId: ((json['sharedByUserId'] ?? 0) as num).toInt(),
      sharedByName: (json['sharedByName'] ?? '알 수 없음').toString(),
      sharedByProfileImageUrl: (json['sharedByProfileImageUrl'] ??
          json['sharedByUserProfileImageUrl'] ??
          json['authorProfileImageUrl'] ??
          json['profileImageUrl']) as String?,
      problemId:
          json['problemId'] == null ? null : (json['problemId'] as num).toInt(),
      problemImageUrls: (json['problemImageUrls'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      reference: (json['reference'] ?? '공유 문제').toString(),
      comment: json['comment'] as String?,
      commentCount: json['commentCount'] == null
          ? null
          : (json['commentCount'] as num).toInt(),
      sharedAt: DateTime.tryParse((json['sharedAt'] ?? '').toString()) ??
          DateTime.now(),
      reactions: reactionsJson is List
          ? reactionsJson
              .whereType<Map<String, dynamic>>()
              .map(FeedReactionModel.fromJson)
              .toList()
          : <FeedReactionModel>[],
    );
  }
}
