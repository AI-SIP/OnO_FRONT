/// 기간 키를 사람이 읽는 말로 바꾼다.
///
/// 서버가 주는 `2026-09-08`, `2026-W36` 을 그대로 보여 주면 무슨 뜻인지 알 수
/// 없다. 지난 미션 목록은 여러 기간이 섞여 오기 때문에, 어느 때 것인지가
/// 줄마다 보여야 한다.
///
/// 읽지 못하는 키가 와도 화면이 깨지면 안 되므로 언제나 문구를 돌려준다.
abstract final class MissionPeriodLabel {
  /// 기간을 알 수 없을 때 쓰는 말.
  static const String unknown = '지난 미션';

  /// 날짜 하나를 [now] 기준의 문구로 바꾼다.
  ///
  /// 보상 기록을 날짜별로 묶을 때 쓴다. 기간 키와 같은 규칙으로 말해야 두
  /// 화면의 말이 어긋나지 않는다.
  static String ofDate(DateTime date, {DateTime? now}) {
    return _dailyLabel(_dateOnly(date), _dateOnly(now ?? DateTime.now()));
  }

  /// [periodKey] 를 [now] 기준의 문구로 바꾼다.
  ///
  /// - `2026-09-08` → `어제` 또는 `9월 8일`
  /// - `2026-W36` → `지난주` 또는 `3주 전`
  /// - 그 밖 → [unknown]
  static String of(String? periodKey, {DateTime? now}) {
    final key = periodKey?.trim() ?? '';
    if (key.isEmpty) return unknown;

    final today = _dateOnly(now ?? DateTime.now());

    final weekly = _weekMondayOf(key);
    if (weekly != null) return _weeklyLabel(weekly, today);

    final daily = _dateOf(key);
    if (daily != null) return _dailyLabel(daily, today);

    return unknown;
  }

  static String _dailyLabel(DateTime date, DateTime today) {
    final days = today.difference(date).inDays;
    if (days == 1) return '어제';
    if (days == 0) return '오늘';
    return '${date.month}월 ${date.day}일';
  }

  static String _weeklyLabel(DateTime monday, DateTime today) {
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final weeks = thisMonday.difference(monday).inDays ~/ 7;
    if (weeks == 1) return '지난주';
    if (weeks <= 0) return '이번 주';
    return '$weeks주 전';
  }

  /// `2026-09-08` 을 읽는다.
  static DateTime? _dateOf(String key) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    // DateTime 은 2026-02-31 을 3월로 넘겨 버린다. 넘어갔으면 잘못된 키다.
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// `2026-W36` 의 월요일을 구한다.
  ///
  /// ISO 주차라 1월 4일이 언제나 1주차에 든다. 그 주의 월요일을 기준으로
  /// 주 수를 더한다.
  static DateTime? _weekMondayOf(String key) {
    final match = RegExp(r'^(\d{4})-W(\d{1,2})$').firstMatch(key);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final week = int.parse(match.group(2)!);
    if (week < 1 || week > 53) return null;

    final jan4 = DateTime(year, 1, 4);
    final firstMonday = jan4.subtract(Duration(days: jan4.weekday - 1));
    return firstMonday.add(Duration(days: (week - 1) * 7));
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
