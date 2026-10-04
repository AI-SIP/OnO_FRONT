/// 추천 복습 일정을 사람이 읽는 말로 바꾼다.
class ReviewScheduleText {
  /// 추천 카드에 붙이는 칩. 오늘이 복습일이면 `오늘`, 지났으면 `N일 밀림`.
  /// 아직 오지 않았거나 날짜가 없으면 null 이다.
  static String? dueChip(DateTime? nextReviewAt, {DateTime? now}) {
    if (nextReviewAt == null) return null;
    final overdueDays = _daysBetween(nextReviewAt, now ?? DateTime.now());
    if (overdueDays < 0) return null;
    return overdueDays == 0 ? '오늘' : '$overdueDays일 밀림';
  }

  /// 복습을 저장한 뒤 띄우는 말.
  ///
  /// 서버가 다음 복습일을 주지 않는 예전 버전이면 [hasReviewSchedule] 이
  /// false 라 예전 문구를 쓴다.
  static String afterSave({
    required bool hasReviewSchedule,
    required DateTime? nextReviewAt,
    DateTime? now,
  }) {
    if (!hasReviewSchedule) return '복습이 완료되었습니다!';
    if (nextReviewAt == null) return '복습을 기록했어요. 3번 맞혀서 추천 복습에서 빠졌어요';
    final days = _daysBetween(now ?? DateTime.now(), nextReviewAt);
    final date = '${nextReviewAt.month}월 ${nextReviewAt.day}일';
    if (days <= 0) return '복습을 기록했어요. 오늘 한 번 더 복습해 보세요';
    if (days == 1) return '복습을 기록했어요. 다음 복습은 내일($date)이에요';
    return '복습을 기록했어요. 다음 복습은 $date($days일 뒤)이에요';
  }

  /// from 에서 to 까지 며칠인지. 시각은 보지 않고 날짜만 센다.
  static int _daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }
}
