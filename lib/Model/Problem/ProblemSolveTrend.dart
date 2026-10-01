import 'AnswerStatus.dart';
import 'ProblemSolveModel.dart';

/// 지금 흐름을 한 마디로 말해 주는 칩의 종류다.
enum ReviewTrendBadge {
  /// 마지막 회차부터 정답이 3번 이상 이어졌다.
  correctStreak,

  /// 앞에서 맞힌 적이 있는데 마지막에 틀렸다.
  relapsed,

  /// 마지막 회차부터 오답이 2번 이상 이어졌다.
  wrongStreak,
}

/// 풀이 시간 막대 하나다. [round] 는 전체 회차 번호(1부터)다.
class ReviewTimeBar {
  final int round;
  final int seconds;

  const ReviewTimeBar({required this.round, required this.seconds});
}

/// 한 문제의 복습 기록 목록을 복습 추이 판에 그릴 값으로 모은다.
///
/// 서버가 보내는 순서에 기대지 않고 [practicedAt] 오름차순으로 다시 정렬한다.
/// 회차 번호는 가장 오래된 기록이 1회차다. 레거시 이관 기록(UNKNOWN)은
/// 맞힌 수와 연속 판정에서 뺀다.
class ProblemSolveTrend {
  /// 오래된 기록부터.
  final List<ProblemSolveModel> solves;

  /// 마지막 복습이 며칠 전인지 셀 기준 시각이다.
  final DateTime now;

  /// 처음과 최근을 비교할 묶음 크기다.
  static const int compareWindow = 5;

  /// 풀이 시간 막대를 몇 개까지 그리는지다.
  static const int maxTimeBars = 10;

  /// 처음과 마지막 풀이 시간 차이가 이 안이면 비슷하다고 본다.
  static const int similarTimeSeconds = 30;

  ProblemSolveTrend._(this.solves, this.now);

  factory ProblemSolveTrend.from(List<ProblemSolveModel> solves,
      {DateTime? now}) {
    final sorted = List<ProblemSolveModel>.from(solves)
      ..sort((a, b) {
        final byTime = a.practicedAt.compareTo(b.practicedAt);
        return byTime != 0 ? byTime : a.problemSolveId - b.problemSolveId;
      });
    return ProblemSolveTrend._(
        List.unmodifiable(sorted), now ?? DateTime.now());
  }

  int get total => solves.length;

  int get correctCount => _countCorrect(solves);

  /// 마지막 복습이 오늘이면 0 이다. 기기 시계가 어긋나 미래로 잡혀도 0 으로 둔다.
  int? get daysSinceLast {
    if (solves.isEmpty) return null;
    final days = _daysBetween(solves.last.practicedAt, now);
    return days < 0 ? 0 : days;
  }

  /// [index] 회차와 바로 앞 회차 사이의 날짜 수다. 첫 회차는 null 이다.
  int? gapDaysBefore(int index) {
    if (index <= 0 || index >= solves.length) return null;
    return _daysBetween(
        solves[index - 1].practicedAt, solves[index].practicedAt);
  }

  ReviewTrendBadge? get badge => _badge().$1;

  /// [badge] 가 연속을 말할 때 몇 번 이어졌는지다.
  int get badgeCount => _badge().$2;

  (ReviewTrendBadge?, int) _badge() {
    final known = solves
        .map((s) => s.answerStatus)
        .where((s) => s != AnswerStatus.UNKNOWN)
        .toList();
    if (known.length < 2) return (null, 0);

    final last = known.last;
    final trailingCorrect = _trailing(known, AnswerStatus.CORRECT);
    if (trailingCorrect >= 3) {
      return (ReviewTrendBadge.correctStreak, trailingCorrect);
    }

    final hadCorrect =
        known.sublist(0, known.length - 1).contains(AnswerStatus.CORRECT);
    if (last == AnswerStatus.WRONG && hadCorrect) {
      return (ReviewTrendBadge.relapsed, 0);
    }

    final trailingWrong = _trailing(known, AnswerStatus.WRONG);
    if (trailingWrong >= 2) {
      return (ReviewTrendBadge.wrongStreak, trailingWrong);
    }
    return (null, 0);
  }

  /// 처음과 최근 비교는 두 묶음이 겹치지 않을 만큼 기록이 쌓였을 때만 보여 준다.
  bool get hasEarlyRecentCompare => total >= compareWindow * 2;

  int get earlyCorrectCount =>
      _countCorrect(solves.take(compareWindow).toList());

  int get recentCorrectCount =>
      _countCorrect(solves.skip(total - compareWindow).toList());

  List<ReviewTimeBar> get _allTimeBars => [
        for (var i = 0; i < solves.length; i++)
          if (solves[i].timeSpentSeconds != null)
            ReviewTimeBar(round: i + 1, seconds: solves[i].timeSpentSeconds!),
      ];

  /// 시간이 남은 회차가 2개 이상이고 값이 모두 같지는 않을 때만 그린다.
  ///
  /// 복습 등록 화면의 소요 시간 기본값이 10분이라, 손대지 않고 저장한 기록이
  /// 모두 같은 값으로 남는다. 그 경우 막대가 의미 없이 똑같이 나온다.
  bool get hasTimeTrend {
    final bars = _allTimeBars;
    if (bars.length < 2) return false;
    return bars.any((b) => b.seconds != bars.first.seconds);
  }

  /// 최근 [maxTimeBars] 개 회차의 풀이 시간이다.
  List<ReviewTimeBar> get timeBars {
    final bars = _allTimeBars;
    return bars.length <= maxTimeBars
        ? bars
        : bars.sublist(bars.length - maxTimeBars);
  }

  bool get isTimeBarsTrimmed => _allTimeBars.length > maxTimeBars;

  /// 처음 기록한 시간에서 마지막 시간을 뺀 값이다. 양수면 빨라졌다는 뜻이다.
  int? get timeImprovementSeconds {
    if (!hasTimeTrend) return null;
    final bars = _allTimeBars;
    return bars.first.seconds - bars.last.seconds;
  }

  static int _countCorrect(List<ProblemSolveModel> list) =>
      list.where((s) => s.answerStatus == AnswerStatus.CORRECT).length;

  static int _trailing(List<AnswerStatus> list, AnswerStatus target) {
    var count = 0;
    for (var i = list.length - 1; i >= 0 && list[i] == target; i--) {
      count++;
    }
    return count;
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    // 서머타임이 있는 지역에서 하루가 23시간이 되는 날을 반올림으로 맞춘다.
    return (b.difference(a).inHours / 24).round();
  }
}
