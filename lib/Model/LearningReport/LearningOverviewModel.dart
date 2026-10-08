/// 학습 보고서 화면이 보는 기간.
///
/// 서버 쿼리 값(`WEEK`, `MONTH`, `TOTAL`)과 애널리틱스 값(`weekly`, `monthly`,
/// `total`)이 다르다. 애널리틱스 값은 예전 보고서부터 쓰던 것이라 그대로 둔다.
enum LearningOverviewPeriod {
  week('WEEK', 'weekly'),
  month('MONTH', 'monthly'),
  total('TOTAL', 'total');

  final String apiValue;
  final String analyticsValue;

  const LearningOverviewPeriod(this.apiValue, this.analyticsValue);

  /// 모르는 값이 오면 주간으로 본다. 서버가 값을 늘려도 화면이 죽지 않게 한다.
  static LearningOverviewPeriod fromApi(Object? value) {
    for (final period in values) {
      if (period.apiValue == value) return period;
    }
    return week;
  }
}

/// `GET /api/learning-reports/overview` 응답.
///
/// 계약은 `docs/학습 보고서 개편/구현_명세서.md` 의 API 계약 절이다. 필드가
/// 비거나 빠져도 화면이 그려지도록 숫자는 0, 목록은 빈 목록으로 채운다.
/// 정답률은 0 과 "기록 없음" 이 다른 뜻이라 null 을 그대로 둔다.
class LearningOverviewModel {
  final LearningOverviewPeriod period;

  /// 달력 기준 기간의 첫날. 전체 기간에 기록이 없으면 null 이다.
  final DateTime? startDate;

  /// 달력 기준 기간의 마지막 날. 이번 주면 아직 오지 않은 일요일일 수 있다.
  final DateTime? endDate;

  final bool hasPrevious;
  final bool hasNext;
  final LearningOverviewSummary summary;

  /// 비교 기간. 전체 기간이면 null 이다.
  final LearningOverviewPrevious? previous;

  final LearningNoteStatus noteStatus;
  final List<LearningWeakFolder> weakFolders;
  final List<LearningTrendBucket> trend;

  const LearningOverviewModel({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.hasPrevious,
    required this.hasNext,
    required this.summary,
    required this.previous,
    required this.noteStatus,
    required this.weakFolders,
    required this.trend,
  });

  factory LearningOverviewModel.fromJson(Map<String, dynamic> json) {
    final previous = json['previous'];
    return LearningOverviewModel(
      period: LearningOverviewPeriod.fromApi(json['period']),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      hasPrevious: json['hasPrevious'] == true,
      hasNext: json['hasNext'] == true,
      summary: LearningOverviewSummary.fromJson(_asMap(json['summary'])),
      previous: previous is Map<String, dynamic>
          ? LearningOverviewPrevious.fromJson(previous)
          : null,
      noteStatus: LearningNoteStatus.fromJson(_asMap(json['noteStatus'])),
      weakFolders: _asList(json['weakFolders'])
          .map(LearningWeakFolder.fromJson)
          .toList(),
      trend: _asList(json['trend']).map(LearningTrendBucket.fromJson).toList(),
    );
  }
}

class LearningOverviewSummary {
  final int reviewCount;

  /// 소수 첫째 자리까지의 백분율. 채점한 기록이 없으면 null 이다.
  final double? accuracy;

  final int studyDays;
  final int currentStreak;

  const LearningOverviewSummary({
    required this.reviewCount,
    required this.accuracy,
    required this.studyDays,
    required this.currentStreak,
  });

  factory LearningOverviewSummary.fromJson(Map<String, dynamic> json) {
    return LearningOverviewSummary(
      reviewCount: _asInt(json['reviewCount']),
      accuracy: _asDouble(json['accuracy']),
      studyDays: _asInt(json['studyDays']),
      currentStreak: _asInt(json['currentStreak']),
    );
  }
}

class LearningOverviewPrevious {
  final int reviewCount;
  final double? accuracy;
  final int studyDays;

  const LearningOverviewPrevious({
    required this.reviewCount,
    required this.accuracy,
    required this.studyDays,
  });

  factory LearningOverviewPrevious.fromJson(Map<String, dynamic> json) {
    return LearningOverviewPrevious(
      reviewCount: _asInt(json['reviewCount']),
      accuracy: _asDouble(json['accuracy']),
      studyDays: _asInt(json['studyDays']),
    );
  }
}

/// 지금 시점의 오답노트 상태. 지난 기간을 봐도 오늘 기준이다.
class LearningNoteStatus {
  final int totalCount;
  final int knownCount;
  final int unsureCount;
  final int unsolvedCount;

  /// 이 기간 안에 확실히 아는 문제가 된 수.
  final int newlyKnownCount;

  /// 확실히 아는 문제가 되려면 맞혀야 하는 날 수. 설명 문구에 쓴다.
  final int knownThreshold;

  const LearningNoteStatus({
    required this.totalCount,
    required this.knownCount,
    required this.unsureCount,
    required this.unsolvedCount,
    required this.newlyKnownCount,
    required this.knownThreshold,
  });

  factory LearningNoteStatus.fromJson(Map<String, dynamic> json) {
    final threshold = _asInt(json['knownThreshold']);
    return LearningNoteStatus(
      totalCount: _asInt(json['totalCount']),
      knownCount: _asInt(json['knownCount']),
      unsureCount: _asInt(json['unsureCount']),
      unsolvedCount: _asInt(json['unsolvedCount']),
      newlyKnownCount: _asInt(json['newlyKnownCount']),
      // 0 이 오면 `연달아 0번 맞힌 문제` 가 되어 버린다. 서버 기준값인 3 으로 둔다.
      knownThreshold: threshold > 0 ? threshold : 3,
    );
  }
}

class LearningWeakFolder {
  final int folderId;
  final String name;
  final int solveCount;
  final int wrongCount;
  final double accuracy;

  const LearningWeakFolder({
    required this.folderId,
    required this.name,
    required this.solveCount,
    required this.wrongCount,
    required this.accuracy,
  });

  factory LearningWeakFolder.fromJson(Map<String, dynamic> json) {
    return LearningWeakFolder(
      folderId: _asInt(json['folderId']),
      name: (json['name'] ?? '').toString(),
      solveCount: _asInt(json['solveCount']),
      wrongCount: _asInt(json['wrongCount']),
      accuracy: _asDouble(json['accuracy']) ?? 0,
    );
  }
}

/// 막대 하나. 주간은 하루, 월간은 한 주, 전체는 한 달이다.
class LearningTrendBucket {
  final DateTime? startDate;
  final DateTime? endDate;
  final int reviewCount;

  const LearningTrendBucket({
    required this.startDate,
    required this.endDate,
    required this.reviewCount,
  });

  factory LearningTrendBucket.fromJson(Map<String, dynamic> json) {
    return LearningTrendBucket(
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      reviewCount: _asInt(json['reviewCount']),
    );
  }
}

/// `yyyy-MM-dd` 를 그 날 0시(기기 시간대)로 읽는다. 시각이 없는 날짜라
/// 시간대를 옮기면 하루가 밀린다.
DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

int _asInt(Object? value) => value is num ? value.toInt() : 0;

double? _asDouble(Object? value) => value is num ? value.toDouble() : null;

Map<String, dynamic> _asMap(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

List<Map<String, dynamic>> _asList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}
