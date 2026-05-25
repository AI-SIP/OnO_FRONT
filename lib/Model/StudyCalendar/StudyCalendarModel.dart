class StudyCalendarModel {
  final int year;
  final int month;
  final int currentStreak;
  final int bestStreak;
  final int thisMonthStudyDays;
  final List<DailyStudyRecord> records;

  const StudyCalendarModel({
    required this.year,
    required this.month,
    required this.currentStreak,
    required this.bestStreak,
    required this.thisMonthStudyDays,
    required this.records,
  });

  factory StudyCalendarModel.fromJson(Map<String, dynamic> json) {
    return StudyCalendarModel(
      year: ((json['year'] ?? 0) as num).toInt(),
      month: ((json['month'] ?? 0) as num).toInt(),
      currentStreak: ((json['currentStreak'] ?? 0) as num).toInt(),
      bestStreak: ((json['bestStreak'] ?? 0) as num).toInt(),
      thisMonthStudyDays: ((json['thisMonthStudyDays'] ?? 0) as num).toInt(),
      records: (json['records'] as List<dynamic>? ?? [])
          .map((e) => DailyStudyRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  DailyStudyRecord? recordFor(int day) {
    try {
      return records.firstWhere(
        (r) => r.date.day == day && r.date.month == month && r.date.year == year,
      );
    } catch (_) {
      return null;
    }
  }
}

class DailyStudyRecord {
  final DateTime date;
  final bool hasStudied;
  final int reviewCount;
  final int noteWriteCount;
  final int studyMinutes;
  final List<String> reviewedItems;

  const DailyStudyRecord({
    required this.date,
    required this.hasStudied,
    required this.reviewCount,
    required this.noteWriteCount,
    required this.studyMinutes,
    required this.reviewedItems,
  });

  factory DailyStudyRecord.fromJson(Map<String, dynamic> json) {
    return DailyStudyRecord(
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime(0),
      hasStudied: (json['hasStudied'] ?? false) as bool,
      reviewCount: ((json['reviewCount'] ?? 0) as num).toInt(),
      noteWriteCount: ((json['noteWriteCount'] ?? 0) as num).toInt(),
      studyMinutes: ((json['studyMinutes'] ?? 0) as num).toInt(),
      reviewedItems: (json['reviewedItems'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  int get intensityLevel {
    if (!hasStudied) return 0;
    final total = reviewCount + noteWriteCount;
    if (total >= 10) return 3;
    if (total >= 5) return 2;
    return 1;
  }
}
