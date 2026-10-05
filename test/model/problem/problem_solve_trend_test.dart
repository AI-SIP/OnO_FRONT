import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Model/Problem/ImprovementType.dart';
import 'package:ono/Model/Problem/ProblemSolveModel.dart';
import 'package:ono/Model/Problem/ProblemSolveTrend.dart';

const _c = AnswerStatus.CORRECT;
const _w = AnswerStatus.WRONG;
const _p = AnswerStatus.PARTIAL;
const _u = AnswerStatus.UNKNOWN;

ProblemSolveModel _solve(
  int id,
  DateTime at,
  AnswerStatus status, {
  int? seconds,
  List<ImprovementType> improvements = const [],
}) {
  return ProblemSolveModel(
    problemSolveId: id,
    problemId: 1,
    userId: 1,
    practicedAt: at,
    answerStatus: status,
    improvements: improvements,
    timeSpentSeconds: seconds,
    migratedFromLegacy: false,
    imageUrls: const [],
    createdAt: at,
    updatedAt: at,
  );
}

/// 9월 1일부터 하루씩 간격을 두고 [statuses] 순서대로 기록을 만든다.
ProblemSolveTrend _trend(List<AnswerStatus> statuses, {DateTime? now}) {
  return ProblemSolveTrend.from(
    [
      for (var i = 0; i < statuses.length; i++)
        _solve(i + 1, DateTime(2026, 9, 1 + i, 20), statuses[i]),
    ],
    now: now ?? DateTime(2026, 10, 1, 9),
  );
}

void main() {
  group('정렬과 요약', () {
    test('서버 순서와 상관없이 오래된 기록이 1회차가 된다', () {
      final trend = ProblemSolveTrend.from([
        _solve(3, DateTime(2026, 9, 20), _c),
        _solve(1, DateTime(2026, 9, 3), _w),
        _solve(2, DateTime(2026, 9, 6), _p),
      ], now: DateTime(2026, 10, 1));

      expect(trend.solves.map((s) => s.problemSolveId), [1, 2, 3]);
    });

    test('같은 시각이면 id 가 작은 기록이 먼저다', () {
      final at = DateTime(2026, 9, 3, 10);
      final trend = ProblemSolveTrend.from([
        _solve(9, at, _c),
        _solve(4, at, _w),
      ]);

      expect(trend.solves.map((s) => s.problemSolveId), [4, 9]);
    });

    test('맞힌 수는 정답만 센다', () {
      final trend = _trend([_w, _p, _c, _u, _c]);

      expect(trend.total, 5);
      expect(trend.correctCount, 2);
    });

    test('마지막 복습이 며칠 전인지 날짜만 보고 센다', () {
      final trend = ProblemSolveTrend.from(
        [_solve(1, DateTime(2026, 9, 26, 23, 50), _c)],
        now: DateTime(2026, 10, 1, 0, 10),
      );

      expect(trend.daysSinceLast, 5);
    });

    test('기기 시계가 어긋나 마지막 복습이 미래면 오늘로 본다', () {
      final trend = ProblemSolveTrend.from(
        [_solve(1, DateTime(2026, 10, 2), _c)],
        now: DateTime(2026, 10, 1),
      );

      expect(trend.daysSinceLast, 0);
    });

    test('회차 사이 간격은 날짜 차이다', () {
      final trend = ProblemSolveTrend.from([
        _solve(1, DateTime(2026, 9, 3, 23), _w),
        _solve(2, DateTime(2026, 9, 6, 1), _c),
        _solve(3, DateTime(2026, 9, 6, 22), _c),
      ]);

      expect(trend.gapDaysBefore(0), isNull);
      expect(trend.gapDaysBefore(1), 3);
      expect(trend.gapDaysBefore(2), 0);
    });
  });

  group('상태 칩', () {
    test('정답이 3번 이상 이어지면 연속 정답', () {
      final trend = _trend([_w, _c, _c, _c, _c]);

      expect(trend.badge, ReviewTrendBadge.correctStreak);
      expect(trend.badgeCount, 4);
    });

    test('틀렸다가 이번에 맞힌 것만으로는 칩을 달지 않는다', () {
      expect(_trend([_c, _w, _c]).badge, isNull);
      expect(_trend([_p, _c]).badge, isNull);
    });

    test('맞혔다가 다시 틀리면 relapsed 가 연속 오답보다 먼저다', () {
      expect(_trend([_c, _w, _w]).badge, ReviewTrendBadge.relapsed);
    });

    test('맞힌 적 없이 오답이 2번 이상 이어지면 연속 오답', () {
      final trend = _trend([_p, _w, _w, _w]);

      expect(trend.badge, ReviewTrendBadge.wrongStreak);
      expect(trend.badgeCount, 3);
    });

    test('UNKNOWN 은 건너뛰고 판정한다', () {
      expect(_trend([_c, _c, _u, _c]).badge, ReviewTrendBadge.correctStreak);
    });

    test('기록이 하나뿐이거나 해당하는 흐름이 없으면 칩이 없다', () {
      expect(_trend([_c]).badge, isNull);
      expect(_trend([_c, _c]).badge, isNull);
      expect(_trend([_w, _p]).badge, isNull);
    });
  });

  group('처음과 최근 비교', () {
    test('기록이 10개 미만이면 비교하지 않는다', () {
      expect(_trend(List.filled(9, _c)).hasEarlyRecentCompare, isFalse);
    });

    test('앞 5개와 뒤 5개의 정답 수를 센다', () {
      final trend =
          _trend([_w, _w, _p, _w, _p, _c, _p, _c, _c, _w, _c, _c, _c, _c]);

      expect(trend.hasEarlyRecentCompare, isTrue);
      expect(trend.earlyCorrectCount, 0);
      expect(trend.recentCorrectCount, 4);
    });
  });

  group('풀이 시간', () {
    ProblemSolveTrend timed(List<int?> seconds) => ProblemSolveTrend.from([
          for (var i = 0; i < seconds.length; i++)
            _solve(i + 1, DateTime(2026, 9, 1 + i), _c, seconds: seconds[i]),
        ]);

    test('처음 시간에서 마지막 시간을 뺀다', () {
      final trend = timed([750, 580, 430, 380, 350]);

      expect(trend.hasTimeTrend, isTrue);
      expect(trend.timeImprovementSeconds, 400);
    });

    test('시간이 모두 같으면 그리지 않는다 (기본값 10분 그대로 저장한 경우)', () {
      final trend = timed([600, 600, 600]);

      expect(trend.hasTimeTrend, isFalse);
      expect(trend.timeImprovementSeconds, isNull);
    });

    test('시간이 있는 회차가 하나뿐이면 그리지 않는다', () {
      expect(timed([null, 300, null]).hasTimeTrend, isFalse);
    });

    test('시간이 없는 회차는 건너뛰고 회차 번호는 전체 기준이다', () {
      final trend = timed([null, 500, null, 300]);

      expect(trend.timeBars.map((b) => b.round), [2, 4]);
      expect(trend.timeImprovementSeconds, 200);
    });

    test('막대는 최근 10개까지만이고 비교는 전체 처음 기준이다', () {
      final trend = timed([for (var i = 0; i < 14; i++) 900 - i * 10]);

      expect(trend.isTimeBarsTrimmed, isTrue);
      expect(trend.timeBars.length, 10);
      expect(trend.timeBars.first.round, 5);
      expect(trend.timeImprovementSeconds, 130);
    });
  });
}
