import 'FeedReactionModel.dart';

class SharedProblemModel {
  final int sharedProblemId;
  final int sharedByUserId;
  final String sharedByName;
  final int? problemId;
  final String? problemImageUrl;
  final String reference;
  final String? comment;
  final DateTime sharedAt;
  List<FeedReactionModel> reactions;

  SharedProblemModel({
    required this.sharedProblemId,
    required this.sharedByUserId,
    required this.sharedByName,
    this.problemId,
    this.problemImageUrl,
    required this.reference,
    this.comment,
    required this.sharedAt,
    required this.reactions,
  });

  factory SharedProblemModel.fromJson(Map<String, dynamic> json) {
    final reactionsJson = json['reactions'];
    return SharedProblemModel(
      sharedProblemId: ((json['sharedProblemId'] ?? 0) as num).toInt(),
      sharedByUserId: ((json['sharedByUserId'] ?? 0) as num).toInt(),
      sharedByName: (json['sharedByName'] ?? '알 수 없음').toString(),
      problemId:
          json['problemId'] == null ? null : (json['problemId'] as num).toInt(),
      problemImageUrl: json['problemImageUrl'] as String?,
      reference: (json['reference'] ?? '공유 문제').toString(),
      comment: json['comment'] as String?,
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
