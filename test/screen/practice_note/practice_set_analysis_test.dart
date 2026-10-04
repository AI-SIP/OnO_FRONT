import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:ono/Model/Problem/ProblemSolveModel.dart';
import 'package:ono/Screen/PracticeNote/PracticeSetAnalysis.dart';

ProblemSolveModel _solve(int solveId, int problemId, AnswerStatus status,
    {int day = 1, int? seconds}) {
  final at = DateTime(2026, 9, day);
  return ProblemSolveModel(
    problemSolveId: solveId,
    problemId: problemId,
    userId: 1,
    practicedAt: at,
    answerStatus: status,
    improvements: const [],
    timeSpentSeconds: seconds,
    migratedFromLegacy: false,
    imageUrls: const [],
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  test('문제마다 가장 최근 복습 결과로 센다', () {
    final analysis = PracticeSetAnalysis.from([
      1,
      2,
      3
    ], {
      // 서버가 보내는 순서에 기대지 않는다.
      1: [
        _solve(2, 1, AnswerStatus.CORRECT, day: 5),
        _solve(1, 1, AnswerStatus.WRONG, day: 1),
      ],
      2: [_solve(3, 2, AnswerStatus.PARTIAL)],
      3: [],
    });

    expect(analysis.total, 3);
    expect(analysis.correctCount, 1);
    expect(analysis.resultOf(1), PracticeProblemResult.correct);
    expect(analysis.resultOf(2), PracticeProblemResult.partial);
    expect(analysis.resultOf(3), PracticeProblemResult.unsolved);
    expect(analysis.partiallyFailed, isFalse);
  });

  test('틀린 문제는 오답과 부분 정답이고 세트에 담긴 순서를 따른다', () {
    final analysis = PracticeSetAnalysis.from([
      30,
      10,
      20
    ], {
      10: [_solve(1, 10, AnswerStatus.WRONG)],
      20: [_solve(2, 20, AnswerStatus.CORRECT)],
      30: [_solve(3, 30, AnswerStatus.PARTIAL)],
    });

    expect(analysis.wrongProblemIds, [30, 10]);
  });

  test('레거시 이관 기록은 건너뛰고 그 앞의 결과를 쓴다', () {
    final analysis = PracticeSetAnalysis.from([
      1,
      2
    ], {
      1: [
        _solve(1, 1, AnswerStatus.WRONG, day: 1),
        _solve(2, 1, AnswerStatus.UNKNOWN, day: 9),
      ],
      2: [_solve(3, 2, AnswerStatus.UNKNOWN)],
    });

    expect(analysis.resultOf(1), PracticeProblemResult.wrong);
    expect(analysis.resultOf(2), PracticeProblemResult.unsolved);
  });

  test('기록을 받지 못한 문제는 빼고 계산하고 일부 실패로 표시한다', () {
    final analysis = PracticeSetAnalysis.from([
      1,
      2
    ], {
      1: [_solve(1, 1, AnswerStatus.CORRECT)],
    });

    expect(analysis.total, 1);
    expect(analysis.resultOf(2), isNull);
    expect(analysis.partiallyFailed, isTrue);
  });

  test('평균 풀이 시간은 문제마다 최근 시간의 평균이고, 시간이 없으면 null 이다', () {
    final analysis = PracticeSetAnalysis.from([
      1,
      2,
      3
    ], {
      1: [
        _solve(1, 1, AnswerStatus.WRONG, day: 1, seconds: 900),
        _solve(2, 1, AnswerStatus.CORRECT, day: 2, seconds: 100),
      ],
      2: [_solve(3, 2, AnswerStatus.WRONG, seconds: 200)],
      3: [_solve(4, 3, AnswerStatus.WRONG)],
    });

    expect(analysis.averageSeconds, 150);
    expect(
      PracticeSetAnalysis.from([
        1
      ], {
        1: [_solve(1, 1, AnswerStatus.CORRECT)],
      }).averageSeconds,
      isNull,
    );
  });
}
