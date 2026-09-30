import 'dart:ui' show Color;

import '../../Model/Problem/ReviewDueProblemModel.dart';
import '../../Model/StudyCalendar/StudyCalendarModel.dart';
import 'HomeWidgetSnapshot.dart';

/// 달력 응답 여러 달과 복습 예정 응답을 위젯 스냅샷 하나로 합친다.
///
/// 서버도 저장소도 모르는 순수 함수만 둔다. 오늘은 인자로 받아서 테스트에서
/// 날짜를 마음대로 고정할 수 있게 한다. 규칙은 `docs/홈 화면 위젯/위젯_데이터_계약.md`
/// 를 따른다.
class HomeWidgetSnapshotBuilder {
  const HomeWidgetSnapshotBuilder._();

  /// 대형 위젯의 추천 복습 문제 수.
  static const int recommendationLimit = 3;

  /// 달력을 오늘이 속한 주 위로 몇 주 더 보여 주는지. 대형이 5줄이라 4주다.
  static const int weeksBeforeThisWeek = 4;

  static HomeWidgetSnapshot build({
    required DateTime now,
    required Color themeColor,
    required List<StudyCalendarModel> calendars,
    required ReviewDueResponse reviewDue,
    required int profileVersion,
  }) {
    final today = dateOnly(now);

    // 연속 일수와 이번 달 공부한 날은 오늘이 속한 달 응답의 값을 쓴다.
    StudyCalendarModel? thisMonth;
    for (final calendar in calendars) {
      if (calendar.year == today.year && calendar.month == today.month) {
        thisMonth = calendar;
        break;
      }
    }

    // 날짜별 단계. 같은 날이 두 번 오면 진한 쪽을 쓴다.
    final levels = <String, int>{};
    DateTime? lastStudied;
    for (final calendar in calendars) {
      for (final record in calendar.records) {
        final date = dateOnly(record.date);
        if (date.isAfter(today)) continue;
        final key = formatDate(date);
        final level = record.intensityLevel;
        final previous = levels[key];
        if (previous == null || level > previous) levels[key] = level;
        if (record.hasStudied &&
            (lastStudied == null || date.isAfter(lastStudied))) {
          lastStudied = date;
        }
      }
    }

    final days = <HomeWidgetDay>[
      for (final date in daysInRange(today))
        HomeWidgetDay(
          date: formatDate(date),
          level: levels[formatDate(date)] ?? 0,
        ),
    ];

    final recommendations = <HomeWidgetRecommendation>[
      for (final problem in reviewDue.problems.take(recommendationLimit))
        HomeWidgetRecommendation(
          problemId: problem.problemId,
          title: titleOf(problem),
          overdueDays: overdueDaysOf(problem.nextReviewAt, today),
        ),
    ];

    return HomeWidgetSnapshot(
      generatedAt: formatTimestamp(now),
      today: formatDate(today),
      themeColor: hexOf(themeColor),
      currentStreak: thisMonth?.currentStreak ?? 0,
      thisMonthStudyDays: thisMonth?.thisMonthStudyDays ?? 0,
      lastStudiedDate: lastStudied == null ? null : formatDate(lastStudied),
      dueCount: reviewDue.dueCount,
      overdueCount: reviewDue.overdueCount,
      recommendations: recommendations,
      days: days,
      profileVersion: profileVersion,
    );
  }

  /// 달력의 첫 날. 오늘이 속한 주의 일요일에서 4주 전 일요일이다.
  static DateTime rangeStart(DateTime today) {
    final date = dateOnly(today);
    // DateTime.weekday 는 월요일 1 ~ 일요일 7 이다. 일요일이면 0 만큼 돌아간다.
    final sinceSunday = date.weekday % 7;
    return DateTime(
      date.year,
      date.month,
      date.day - sinceSunday - weeksBeforeThisWeek * 7,
    );
  }

  /// 달력에 들어가는 날짜들. [rangeStart] 부터 오늘까지 오름차순이다.
  static List<DateTime> daysInRange(DateTime today) {
    final end = dateOnly(today);
    final start = rangeStart(end);
    final result = <DateTime>[];
    // 일광 절약 시간이 있는 곳에서도 하루씩 정확히 넘어가도록 Duration 대신
    // 날짜 칸을 하나씩 올린다.
    for (var i = 0;; i++) {
      final date = DateTime(start.year, start.month, start.day + i);
      if (date.isAfter(end)) break;
      result.add(date);
    }
    return result;
  }

  /// 달력을 채우려면 받아야 하는 달들. 오래된 달부터 오늘이 속한 달까지다.
  ///
  /// 보통 두 달이지만, 월 초에 이번 주 일요일이 지난달에 있고 그 4주 전이
  /// 지지난달 말일이면 세 달이 된다. 예: 오늘이 2026-10-01 이면 8월 30일부터라
  /// 8, 9, 10월을 받는다.
  static List<({int year, int month})> monthsInRange(DateTime today) {
    final end = dateOnly(today);
    final start = rangeStart(end);
    final months = <({int year, int month})>[];
    var cursor = DateTime(start.year, start.month);
    final last = DateTime(end.year, end.month);
    while (!cursor.isAfter(last)) {
      months.add((year: cursor.year, month: cursor.month));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }

  /// 추천 문제 제목. 백엔드 `reviewedItems` 와 같은 규칙이다.
  ///
  /// `reference`, 없으면 `memo`, 둘 다 없으면 `문제 {problemId}`. 앞뒤 공백을
  /// 지우고, 빈 문자열은 없는 것으로 본다.
  static String titleOf(ReviewDueProblemModel problem) {
    final reference = problem.reference?.trim();
    if (reference != null && reference.isNotEmpty) return reference;
    final memo = problem.memo?.trim();
    if (memo != null && memo.isNotEmpty) return memo;
    return '문제 ${problem.problemId}';
  }

  /// 오늘까지 며칠 밀렸는지. 0 이하면 0 이다.
  static int overdueDaysOf(DateTime? nextReviewAt, DateTime today) {
    if (nextReviewAt == null) return 0;
    final due = dateOnly(nextReviewAt.toLocal());
    final day = dateOnly(today);
    // 일광 절약 시간에 하루가 23시간이 되는 날도 날짜 수가 맞게 UTC 로 뺀다.
    final diff = DateTime.utc(day.year, day.month, day.day)
        .difference(DateTime.utc(due.year, due.month, due.day))
        .inDays;
    return diff > 0 ? diff : 0;
  }

  /// 테마 색을 `#RRGGBB` 로 적는다. 투명도는 버린다.
  static String hexOf(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// `yyyy-MM-dd`.
  static String formatDate(DateTime value) =>
      '${_pad(value.year, 4)}-${_pad(value.month, 2)}-${_pad(value.day, 2)}';

  /// `2026-09-30T21:04:11+09:00` 처럼 기기 현지 시각에 시간대를 붙여 적는다.
  static String formatTimestamp(DateTime value) {
    final offset = value.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final minutes = offset.inMinutes.abs();
    return '${formatDate(value)}T${_pad(value.hour, 2)}:${_pad(value.minute, 2)}'
        ':${_pad(value.second, 2)}'
        '$sign${_pad(minutes ~/ 60, 2)}:${_pad(minutes % 60, 2)}';
  }

  static String _pad(int value, int width) =>
      value.toString().padLeft(width, '0');
}
