class LearningReportResponseModel {
  final LearningPeriodReport weekly;
  final LearningPeriodReport monthly;
  final LearningPeriodReport total;
  final LearningReportComparison? weeklyComparison;
  final LearningReportComparison? monthlyComparison;
  final LearningReportRecommendations recommendations;

  const LearningReportResponseModel({
    required this.weekly,
    required this.monthly,
    required this.total,
    required this.weeklyComparison,
    required this.monthlyComparison,
    required this.recommendations,
  });

  factory LearningReportResponseModel.fromJson(Map<String, dynamic> json) {
    return LearningReportResponseModel(
      weekly: LearningPeriodReport.fromJson(json['weekly']),
      monthly: LearningPeriodReport.fromJson(json['monthly']),
      total: LearningPeriodReport.fromJson(json['total']),
      weeklyComparison: json['weeklyComparison'] != null
          ? LearningReportComparison.fromJson(json['weeklyComparison'])
          : null,
      monthlyComparison: json['monthlyComparison'] != null
          ? LearningReportComparison.fromJson(json['monthlyComparison'])
          : null,
      recommendations:
          LearningReportRecommendations.fromJson(json['recommendations']),
    );
  }
}

class LearningPeriodReport {
  final String periodLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final int reviewCount;
  final double averageAccuracy;
  final int consecutiveLearningDays;
  final double averageStudyTimeMinutes;
  final List<LearningTrendItem> trend;
  final List<LearningWeakArea> weakAreas;

  const LearningPeriodReport({
    required this.periodLabel,
    required this.startDate,
    required this.endDate,
    required this.reviewCount,
    required this.averageAccuracy,
    required this.consecutiveLearningDays,
    required this.averageStudyTimeMinutes,
    required this.trend,
    required this.weakAreas,
  });

  factory LearningPeriodReport.fromJson(Map<String, dynamic> json) {
    return LearningPeriodReport(
      periodLabel: (json['periodLabel'] ?? '').toString(),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      reviewCount: ((json['reviewCount'] ?? 0) as num).toInt(),
      averageAccuracy: ((json['averageAccuracy'] ?? 0) as num).toDouble(),
      consecutiveLearningDays:
          ((json['consecutiveLearningDays'] ?? 0) as num).toInt(),
      averageStudyTimeMinutes:
          ((json['averageStudyTimeMinutes'] ?? 0) as num).toDouble(),
      trend: (json['trend'] as List<dynamic>? ?? [])
          .map((e) => LearningTrendItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      weakAreas: (json['weakAreas'] as List<dynamic>? ?? [])
          .map((e) => LearningWeakArea.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LearningTrendItem {
  final String label;
  final int reviewCount;

  const LearningTrendItem({
    required this.label,
    required this.reviewCount,
  });

  factory LearningTrendItem.fromJson(Map<String, dynamic> json) {
    return LearningTrendItem(
      label: (json['label'] ?? '').toString(),
      reviewCount: ((json['reviewCount'] ?? 0) as num).toInt(),
    );
  }
}

class LearningWeakArea {
  final String topic;
  final int wrongCount;

  const LearningWeakArea({
    required this.topic,
    required this.wrongCount,
  });

  factory LearningWeakArea.fromJson(Map<String, dynamic> json) {
    return LearningWeakArea(
      topic: (json['topic'] ?? '').toString(),
      wrongCount: ((json['wrongCount'] ?? 0) as num).toInt(),
    );
  }
}

class LearningReportComparison {
  final String basePeriod;
  final String compareTo;
  final double reviewCountChangeRate;
  final double averageAccuracyChangeRate;
  final double consecutiveLearningDaysChangeRate;
  final double averageStudyTimeChangeRate;

  const LearningReportComparison({
    required this.basePeriod,
    required this.compareTo,
    required this.reviewCountChangeRate,
    required this.averageAccuracyChangeRate,
    required this.consecutiveLearningDaysChangeRate,
    required this.averageStudyTimeChangeRate,
  });

  factory LearningReportComparison.fromJson(Map<String, dynamic> json) {
    return LearningReportComparison(
      basePeriod: (json['basePeriod'] ?? '').toString(),
      compareTo: (json['compareTo'] ?? '').toString(),
      reviewCountChangeRate:
          ((json['reviewCountChangeRate'] ?? 0) as num).toDouble(),
      averageAccuracyChangeRate:
          ((json['averageAccuracyChangeRate'] ?? 0) as num).toDouble(),
      consecutiveLearningDaysChangeRate:
          ((json['consecutiveLearningDaysChangeRate'] ?? 0) as num).toDouble(),
      averageStudyTimeChangeRate:
          ((json['averageStudyTimeChangeRate'] ?? 0) as num).toDouble(),
    );
  }
}

class LearningReportRecommendations {
  final List<String> strengths;
  final List<String> gaps;
  final List<String> actions;
  final String nextWeekGoal;
  final double confidence;

  const LearningReportRecommendations({
    required this.strengths,
    required this.gaps,
    required this.actions,
    required this.nextWeekGoal,
    required this.confidence,
  });

  factory LearningReportRecommendations.fromJson(Map<String, dynamic> json) {
    return LearningReportRecommendations(
      strengths: (json['strengths'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      gaps: (json['gaps'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      actions: (json['actions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      nextWeekGoal: (json['nextWeekGoal'] ?? '').toString(),
      confidence: ((json['confidence'] ?? 0) as num).toDouble(),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  final raw = value.toString();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
