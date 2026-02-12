enum ProblemAnalysisStatus {
  NOT_STARTED,
  PROCESSING,
  COMPLETED,
  FAILED,
  NO_IMAGE;

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
      default:
        return null;
    }
  }

  String toJson() {
    return toString().split('.').last;
  }
}