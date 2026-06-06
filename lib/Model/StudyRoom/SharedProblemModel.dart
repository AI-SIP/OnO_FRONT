import 'FeedReactionModel.dart';

class SharedProblemModel {
  final int sharedProblemId;
  final int sharedByUserId;
  final String sharedByName;
  final String reference;
  final String? comment;
  final DateTime sharedAt;
  List<FeedReactionModel> reactions;

  SharedProblemModel({
    required this.sharedProblemId,
    required this.sharedByUserId,
    required this.sharedByName,
    required this.reference,
    this.comment,
    required this.sharedAt,
    required this.reactions,
  });
}
