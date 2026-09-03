import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Module/Util/ProblemSorting.dart';

import '../../helpers/helpers.dart';

/// 테스트 편의를 위해 필요한 필드만 채워 문제를 만든다.
ProblemModel _problem({
  required int problemId,
  String? reference,
  DateTime? createdAt,
}) {
  return ProblemModel(
    problemId: problemId,
    reference: reference,
    createdAt: createdAt,
  );
}

void main() {
  setUpOnoTest();

  group('sortByName', () {
    test('reference 오름차순(사전순)으로 정렬한다', () {
      final problems = [
        _problem(problemId: 1, reference: '수학'),
        _problem(problemId: 2, reference: '국어'),
        _problem(problemId: 3, reference: '영어'),
      ];

      problems.sortByName();

      expect(
        problems.map((p) => p.reference).toList(),
        ['국어', '수학', '영어'],
      );
    });

    test('reference 가 null 이면 빈 문자열로 취급되어 맨 앞에 온다', () {
      final problems = [
        _problem(problemId: 1, reference: '수학'),
        _problem(problemId: 2, reference: null),
        _problem(problemId: 3, reference: '가나다'),
      ];

      problems.sortByName();

      expect(
        problems.map((p) => p.problemId).toList(),
        [2, 3, 1],
      );
    });

    test('reference 가 같은 문제들은 원래 순서를 유지한다', () {
      final problems = [
        _problem(problemId: 1, reference: '동일'),
        _problem(problemId: 2, reference: '동일'),
        _problem(problemId: 3, reference: '동일'),
      ];

      problems.sortByName();

      expect(
        problems.map((p) => p.problemId).toList(),
        [1, 2, 3],
      );
    });
  });

  group('sortByNewest', () {
    test('createdAt 내림차순(최신순)으로 정렬한다', () {
      final problems = [
        _problem(problemId: 1, createdAt: DateTime(2024, 1, 1)),
        _problem(problemId: 2, createdAt: DateTime(2024, 3, 1)),
        _problem(problemId: 3, createdAt: DateTime(2024, 2, 1)),
      ];

      problems.sortByNewest();

      expect(
        problems.map((p) => p.problemId).toList(),
        [2, 3, 1],
      );
    });

    test('createdAt 이 같은 문제들은 원래 순서를 유지한다', () {
      final sameDate = DateTime(2024, 5, 1);
      final problems = [
        _problem(problemId: 1, createdAt: sameDate),
        _problem(problemId: 2, createdAt: sameDate),
      ];

      problems.sortByNewest();

      expect(
        problems.map((p) => p.problemId).toList(),
        [1, 2],
      );
    });

    // createdAt 은 ProblemModel 에서 nullable 이지만 sortByNewest 는 null 검사 없이
    // `!` 로 강제 언래핑한다. null 이 섞여 있으면 TypeError 가 발생한다.
    // 이 확장은 현재 lib/ 어디에서도 호출되지 않는 죽은 코드라 실사용 버그는 아니지만,
    // 추후 실제로 쓰일 경우를 대비해 현재 동작을 문서화해 둔다.
    test('createdAt 이 null 인 문제가 섞여 있으면 예외가 발생한다', () {
      final problems = [
        _problem(problemId: 1, createdAt: DateTime(2024, 1, 1)),
        _problem(problemId: 2, createdAt: null),
      ];

      expect(() => problems.sortByNewest(), throwsA(isA<TypeError>()));
    });
  });

  group('sortByOldest', () {
    test('createdAt 오름차순(오래된순)으로 정렬한다', () {
      final problems = [
        _problem(problemId: 1, createdAt: DateTime(2024, 1, 1)),
        _problem(problemId: 2, createdAt: DateTime(2024, 3, 1)),
        _problem(problemId: 3, createdAt: DateTime(2024, 2, 1)),
      ];

      problems.sortByOldest();

      expect(
        problems.map((p) => p.problemId).toList(),
        [1, 3, 2],
      );
    });

    test('createdAt 이 같은 문제들은 원래 순서를 유지한다', () {
      final sameDate = DateTime(2024, 5, 1);
      final problems = [
        _problem(problemId: 1, createdAt: sameDate),
        _problem(problemId: 2, createdAt: sameDate),
      ];

      problems.sortByOldest();

      expect(
        problems.map((p) => p.problemId).toList(),
        [1, 2],
      );
    });
  });

  group('빈 목록', () {
    test('빈 목록을 정렬해도 예외 없이 빈 목록 그대로다', () {
      final problems = <ProblemModel>[];

      expect(() => problems.sortByName(), returnsNormally);
      expect(() => problems.sortByNewest(), returnsNormally);
      expect(() => problems.sortByOldest(), returnsNormally);
      expect(problems, isEmpty);
    });
  });
}
