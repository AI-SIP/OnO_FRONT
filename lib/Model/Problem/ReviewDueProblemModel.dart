class ReviewDueProblemModel {
  final int problemId;
  final String? memo;
  final String? reference;
  final DateTime? nextReviewAt;
  final int reviewInterval;
  final int consecutiveCorrectCount;

  ReviewDueProblemModel({
    required this.problemId,
    this.memo,
    this.reference,
    this.nextReviewAt,
    required this.reviewInterval,
    required this.consecutiveCorrectCount,
  });

  factory ReviewDueProblemModel.fromJson(Map<String, dynamic> json) {
    return ReviewDueProblemModel(
      problemId: json['problemId'] as int,
      memo: json['memo'] as String?,
      reference: json['reference'] as String?,
      nextReviewAt: json['nextReviewAt'] != null
          ? DateTime.tryParse(json['nextReviewAt'] as String)
          : null,
      reviewInterval: json['reviewInterval'] as int? ?? 1,
      consecutiveCorrectCount: json['consecutiveCorrectCount'] as int? ?? 0,
    );
  }
}

class ReviewDueResponse {
  final int dueCount;
  final int overdueCount;
  final List<ReviewDueProblemModel> problems;

  ReviewDueResponse({
    required this.dueCount,
    required this.overdueCount,
    required this.problems,
  });

  factory ReviewDueResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ReviewDueResponse(
      dueCount: data['dueCount'] as int? ?? 0,
      overdueCount: data['overdueCount'] as int? ?? 0,
      problems: (data['problems'] as List<dynamic>? ?? [])
          .map((e) => ReviewDueProblemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
