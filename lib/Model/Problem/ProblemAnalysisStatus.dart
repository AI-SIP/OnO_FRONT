enum ProblemAnalysisStatus {
  NOT_STARTED,
  PROCESSING,
  COMPLETED,
  FAILED,
  NO_IMAGE,

  /// 하루 분석 횟수(서버 기준 20회)를 넘겨 분석하지 않았다.
  RATE_LIMIT_EXCEEDED;

  static ProblemAnalysisStatus? fromString(String? status) {
    if (status == null) return null;

    switch (status) {
      case 'NOT_STARTED':
        return ProblemAnalysisStatus.NOT_STARTED;
      case 'PROCESSING':
        return ProblemAnalysisStatus.PROCESSING;
      case 'COMPLETED':
        return ProblemAnalysisStatus.COMPLETED;
      case 'FAILED':
        return ProblemAnalysisStatus.FAILED;
      case 'NO_IMAGE':
        return ProblemAnalysisStatus.NO_IMAGE;
      case 'RATE_LIMIT_EXCEEDED':
        return ProblemAnalysisStatus.RATE_LIMIT_EXCEEDED;
      default:
        return null;
    }
  }

  String toJson() {
    return toString().split('.').last;
  }
}
