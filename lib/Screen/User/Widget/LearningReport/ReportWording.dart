import 'package:intl/intl.dart';

import '../../../../Model/LearningReport/LearningOverviewModel.dart';

/// 보고서 카드들이 기간마다 바꿔 쓰는 말이다.
///
/// 이번 주를 보고 있을 때와 지난 주를 넘겨 보고 있을 때 같은 칸이 다른 말을
/// 써야 한다. 지난 주를 보는데 `이번 주에 복습한 문제` 라고 쓰면 틀린 말이
/// 된다. 카드마다 따로 고르면 한 화면 안에서 말이 어긋나서 한곳에 모은다.
class ReportWording {
  final LearningOverviewPeriod period;

  /// 오늘이 들어 있는 기간을 보고 있는지. 전체는 늘 지금이다.
  final bool isCurrent;

  const ReportWording({required this.period, required this.isCurrent});

  factory ReportWording.of(LearningOverviewModel overview) {
    return ReportWording(
      period: overview.period,
      isCurrent:
          overview.period == LearningOverviewPeriod.total || !overview.hasNext,
    );
  }

  bool get isTotal => period == LearningOverviewPeriod.total;

  /// `이번 주`, `이 주`, `이번 달`, `이 달`, `지금까지`.
  String get thisPeriod {
    switch (period) {
      case LearningOverviewPeriod.week:
        return isCurrent ? '이번 주' : '이 주';
      case LearningOverviewPeriod.month:
        return isCurrent ? '이번 달' : '이 달';
      case LearningOverviewPeriod.total:
        return '지금까지';
    }
  }

  /// `이번 주에`, `지금까지`. 전체는 조사를 붙이지 않는다.
  String get inThisPeriod => isTotal ? thisPeriod : '$thisPeriod에';

  /// 비교하는 앞 기간. 지금 기간이면 `지난주`, 넘겨 본 기간이면 그 앞이라
  /// `전 주` 다.
  String get previousPeriod {
    switch (period) {
      case LearningOverviewPeriod.week:
        return isCurrent ? '지난주' : '전 주';
      case LearningOverviewPeriod.month:
        return isCurrent ? '지난달' : '전 달';
      case LearningOverviewPeriod.total:
        return '';
    }
  }

  /// `지난주와`, `지난달과`. 달은 받침이 있어 `과` 다.
  String get withPreviousPeriod => period == LearningOverviewPeriod.month
      ? '$previousPeriod과'
      : '$previousPeriod와';

  String get reviewLabel => '$inThisPeriod 복습한 문제';

  /// 기록이 없을 때 요약 카드의 큰 글자.
  String get emptyTitle {
    if (isTotal) return '아직 복습한\n기록이 없어요';
    if (!isCurrent) return '$thisPeriod에는 복습한 기록이 없어요';
    // 달은 받침이 있어 `은` 이다.
    final topic = period == LearningOverviewPeriod.month ? '은' : '는';
    return '$thisPeriod$topic 아직\n복습을 안 했어요';
  }

  String get previousReportLabel => '$previousPeriod 보고서 보기';

  String get previousTooltip =>
      period == LearningOverviewPeriod.month ? '이전 달' : '이전 주';

  String get nextTooltip =>
      period == LearningOverviewPeriod.month ? '다음 달' : '다음 주';

  String get trendTitle {
    switch (period) {
      case LearningOverviewPeriod.week:
        return '요일별 복습';
      case LearningOverviewPeriod.month:
        return '주별 복습';
      case LearningOverviewPeriod.total:
        return '월별 복습';
    }
  }

  /// 막대 한 칸의 단위. 평균 문구에 쓴다.
  String get trendUnit {
    switch (period) {
      case LearningOverviewPeriod.week:
        return '하루';
      case LearningOverviewPeriod.month:
        return '한 주';
      case LearningOverviewPeriod.total:
        return '한 달';
    }
  }
}

/// `10월 5일 ~ 10월 11일`. 두 날의 해가 다르면 둘 다 해를 붙인다.
String formatReportRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return '';
  if (start == null) return _formatDay(end!, withYear: false);
  if (end == null) return _formatDay(start, withYear: false);
  final withYear = start.year != end.year;
  return '${_formatDay(start, withYear: withYear)} ~ '
      '${_formatDay(end, withYear: withYear)}';
}

String _formatDay(DateTime date, {required bool withYear}) {
  return DateFormat(withYear ? 'yyyy년 M월 d일' : 'M월 d일').format(date);
}

/// `3.5`, `4`. 소수 첫째 자리까지만, `.0` 은 뗀다.
String formatReportDecimal(double value) {
  final fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}
