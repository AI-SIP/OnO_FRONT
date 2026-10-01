class ReviewDueProblemModel {
  final int problemId;
  final String? memo;
  final String? reference;
  final DateTime? nextReviewAt;
  final int reviewInterval;
  final int consecutiveCorrectCount;

  /// 지금까지 맞힌 횟수. 연속이 아니어도 센다. 이 필드를 주지 않는 예전 서버면 null 이다.
  final int? correctCount;

  ReviewDueProblemModel({
    required this.problemId,
    this.memo,
    this.reference,
    this.nextReviewAt,
    required this.reviewInterval,
    required this.consecutiveCorrectCount,
    this.correctCount,
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
      correctCount: (json['correctCount'] as num?)?.toInt(),
    );
  }
}

class ReviewDueResponse {
  final int dueCount;
  final int overdueCount;

  /// 이만큼 맞히면 추천에서 빠진다. 예전 서버면 null 이고, 그때는 안내를 띄우지 않는다.
  final int? requiredCorrectCount;
  final List<ReviewDueProblemModel> problems;

  ReviewDueResponse({
    required this.dueCount,
    required this.overdueCount,
    this.requiredCorrectCount,
    required this.problems,
  });

  factory ReviewDueResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ReviewDueResponse(
      dueCount: data['dueCount'] as int? ?? 0,
      overdueCount: data['overdueCount'] as int? ?? 0,
      requiredCorrectCount: (data['requiredCorrectCount'] as num?)?.toInt(),
      problems: (data['problems'] as List<dynamic>? ?? [])
          .map((e) => ReviewDueProblemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
