import '../../Model/Problem/AnswerStatus.dart';
import '../../Model/Problem/ProblemSolveModel.dart';

/// 세트 문제 하나의 가장 최근 결과다. 기록이 없으면 [unsolved].
enum PracticeProblemResult { correct, partial, wrong, unsolved }

/// 복습 세트에 담긴 문제들의 복습 기록을 모아 세트 분석 카드에 그릴 값을 만든다.
///
/// 문제마다 가장 최근 복습 한 번만 본다. 레거시 이관 기록(UNKNOWN)은 결과를
/// 알 수 없어서 건너뛰고 그 앞의 기록을 쓴다.
class PracticeSetAnalysis {
  /// 세트에 담긴 순서대로의 문제 번호.
  final List<int> problemIds;

  /// 문제 번호별 최근 결과. 기록을 받지 못한 문제는 들어 있지 않다.
  final Map<int, PracticeProblemResult> results;

  /// 문제 번호별 최근 풀이 시간(초). 시간이 없는 기록은 들어 있지 않다.
  final Map<int, int> latestSeconds;

  /// 기록을 받지 못한 문제가 있었는지.
  final bool partiallyFailed;

  const PracticeSetAnalysis._({
    required this.problemIds,
    required this.results,
    required this.latestSeconds,
    required this.partiallyFailed,
  });

  /// [solvesByProblem] 에 없는 문제는 기록을 받지 못한 것으로 본다.
  factory PracticeSetAnalysis.from(
    List<int> problemIds,
    Map<int, List<ProblemSolveModel>> solvesByProblem,
  ) {
    final results = <int, PracticeProblemResult>{};
    final latestSeconds = <int, int>{};
    var failed = false;

    for (final problemId in problemIds) {
      final solves = solvesByProblem[problemId];
      if (solves == null) {
        failed = true;
        continue;
      }

      final latest = _latestKnown(solves);
      results[problemId] = _resultOf(latest);
      final seconds = latest?.timeSpentSeconds;
      if (seconds != null && seconds > 0) {
        latestSeconds[problemId] = seconds;
      }
    }

    return PracticeSetAnalysis._(
      problemIds: List.unmodifiable(problemIds),
      results: Map.unmodifiable(results),
      latestSeconds: Map.unmodifiable(latestSeconds),
      partiallyFailed: failed,
    );
  }

  static ProblemSolveModel? _latestKnown(List<ProblemSolveModel> solves) {
    ProblemSolveModel? latest;
    for (final solve in solves) {
      if (solve.answerStatus == AnswerStatus.UNKNOWN) continue;
      if (latest == null) {
        latest = solve;
        continue;
      }
      final byTime = solve.practicedAt.compareTo(latest.practicedAt);
      if (byTime > 0 ||
          (byTime == 0 && solve.problemSolveId > latest.problemSolveId)) {
        latest = solve;
      }
    }
    return latest;
  }

  static PracticeProblemResult _resultOf(ProblemSolveModel? solve) {
    switch (solve?.answerStatus) {
      case AnswerStatus.CORRECT:
        return PracticeProblemResult.correct;
      case AnswerStatus.PARTIAL:
        return PracticeProblemResult.partial;
      case AnswerStatus.WRONG:
        return PracticeProblemResult.wrong;
      case AnswerStatus.UNKNOWN:
      case null:
        return PracticeProblemResult.unsolved;
    }
  }

  /// 분석에 쓴 문제 수. 기록을 받지 못한 문제는 뺀다.
  int get total => results.length;

  int countOf(PracticeProblemResult result) =>
      results.values.where((value) => value == result).length;

  int get correctCount => countOf(PracticeProblemResult.correct);

  /// 최근 복습이 오답이나 부분 정답인 문제들. 세트에 담긴 순서다.
  List<int> get wrongProblemIds => problemIds.where((id) {
        final result = results[id];
        return result == PracticeProblemResult.wrong ||
            result == PracticeProblemResult.partial;
      }).toList();

  /// 문제마다 최근 풀이 시간의 평균(초). 시간이 남은 기록이 없으면 null.
  int? get averageSeconds {
    if (latestSeconds.isEmpty) return null;
    final sum = latestSeconds.values.fold<int>(0, (a, b) => a + b);
    return (sum / latestSeconds.length).round();
  }

  PracticeProblemResult? resultOf(int problemId) => results[problemId];
}
