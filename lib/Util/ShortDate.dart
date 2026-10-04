import 'package:intl/intl.dart';

/// 목록 카드에 붙이는 짧은 날짜.
///
/// 문제 카드는 `M/d`, 복습 세트 카드는 `yyyy/MM/dd` 로 서로 달랐다. 올해면
/// `M/d`, 다른 해면 `yy/M/d` 로 맞춘다.
String shortDate(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return date.year == today.year
      ? DateFormat('M/d').format(date)
      : DateFormat('yy/M/d').format(date);
}
