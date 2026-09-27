// ProblemsProvider 상태 전이 테스트.
//
// ProblemsProvider 에는 로딩 플래그(_isLoading) 자체가 없다. 그래서 "로딩이
// true 로 멈춰있는" 류의 버그는 애초에 존재할 수 없는 대신, 실패 시 예외를
// 그대로 던지는지/삼키는지가 화면 갱신 여부를 가른다. 이 파일은 그 경계를 본다.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Problem/ProblemAnalysisModel.dart';
import 'package:ono/Model/Problem/ProblemAnalysisStatus.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Problem/ProblemRegisterModel.dart';
import 'package:ono/Provider/ProblemsProvider.dart';

import '../helpers/helpers.dart';
import 'support/provider_test_env.dart';

class _MockBuildContext extends Mock implements BuildContext {}

ProblemModel _problem(int id, {int? folderId, String? memo}) {
  return ProblemModel(problemId: id, folderId: folderId ?? 1, memo: memo);
}

void main() {
  setUpOnoTest();

  setUpAll(() {
    registerFallbackValue(ProblemRegisterModel());
    setUpProviderTestEnv();
  });

  late MockProblemService problemService;
  late ProblemsProvider provider;
  late NotifyRecorder notified;

  setUp(() {
    problemService = MockProblemService();
    provider = ProblemsProvider(problemService: problemService);
    notified = NotifyRecorder();
    provider.addListener(notified.call);
  });

  group('초기 상태', () {
    test('아무 것도 하지 않았을 때 problems 는 비어 있다', () {
      expect(provider.problems, isEmpty);
      expect(provider.problemCount, 0);
    });
  });

  group('fetchProblem', () {
    test('성공하면 캐시에 들어가고 notifyListeners 가 불린다', () async {
      when(() => problemService.getProblem(7, showErrorSnackBar: true))
          .thenAnswer((_) async => _problem(7));

      await provider.fetchProblem(7);

      expect(provider.problems, hasLength(1));
      expect(provider.problems.first.problemId, 7);
      expect(notified.count, greaterThan(0));
    });

    test('실패하면 예외를 삼키지 않고 그대로 던진다 (호출부가 로딩을 못 끄면 스피너가 안 멈춘다)', () async {
      when(() => problemService.getProblem(7, showErrorSnackBar: true))
          .thenThrow(Exception('network error'));

      await expectLater(
        provider.fetchProblem(7),
        throwsA(isA<Exception>()),
      );

      // 실패했으니 캐시에도 안 들어가야 한다.
      expect(provider.problems, isEmpty);
    });
  });

  group('getProblem (캐시 우선 조회)', () {
    test('캐시에 있으면 서비스 호출 없이 바로 돌려준다', () async {
      when(() => problemService.getProblem(7, showErrorSnackBar: true))
          .thenAnswer((_) async => _problem(7));
      await provider.fetchProblem(7);
      notified.reset();
      clearInteractions(problemService);

      final result = await provider.getProblem(7);

      expect(result.problemId, 7);
      verifyNever(() => problemService.getProblem(any(),
          showErrorSnackBar: any(named: 'showErrorSnackBar')));
    });

    test('캐시에 없으면 fetch 후 반환한다', () async {
      when(() => problemService.getProblem(9, showErrorSnackBar: true))
          .thenAnswer((_) async => _problem(9));

      final result = await provider.getProblem(9);

      expect(result.problemId, 9);
      expect(provider.problems, hasLength(1));
    });
  });

  group('fetchAllProblems', () {
    test('SplayTreeMap 이 problemId 기준으로 정렬해서 담는다', () async {
      when(() => problemService.getAllProblems()).thenAnswer(
        (_) async => [_problem(3), _problem(1), _problem(2)],
      );
      when(() => problemService.getProblemCount(showErrorSnackBar: true))
          .thenAnswer((_) async => 3);

      await provider.fetchAllProblems();

      expect(provider.problems.map((p) => p.problemId), [1, 2, 3]);
      expect(provider.problemCount, 3);
      expect(notified.count, greaterThan(0));
    });

    test('다시 부르면 기존 캐시를 지우고 새로 채운다 (중복 누적 안 됨)', () async {
      when(() => problemService.getAllProblems())
          .thenAnswer((_) async => [_problem(1)]);
      when(() => problemService.getProblemCount(showErrorSnackBar: true))
          .thenAnswer((_) async => 1);
      await provider.fetchAllProblems();

      when(() => problemService.getAllProblems())
          .thenAnswer((_) async => [_problem(5)]);
      when(() => problemService.getProblemCount(showErrorSnackBar: true))
          .thenAnswer((_) async => 1);
      await provider.fetchAllProblems();

      expect(provider.problems.map((p) => p.problemId), [5]);
    });
  });

  group('fetchProblemAnalysis', () {
    test('성공하면 해당 문제의 analysis 필드만 갱신된다', () async {
      when(() => problemService.getProblem(7, showErrorSnackBar: true))
          .thenAnswer((_) async => _problem(7));
      await provider.fetchProblem(7);
      notified.reset();

      when(() => problemService.getProblemAnalysis(7)).thenAnswer(
        (_) async => ProblemAnalysisModel(
          id: 1,
          problemId: 7,
          status: ProblemAnalysisStatus.COMPLETED,
        ),
      );

      await provider.fetchProblemAnalysis(7);

      expect(provider.problems.first.analysis?.status,
          ProblemAnalysisStatus.COMPLETED);
      expect(notified.count, greaterThan(0));
    });

    test('캐시에 없는 문제면 결과를 조용히 버린다 (조회는 성공했지만 반영할 곳이 없음)', () async {
      when(() => problemService.getProblemAnalysis(999)).thenAnswer(
        (_) async => ProblemAnalysisModel(problemId: 999),
      );

      await provider.fetchProblemAnalysis(999);

      expect(provider.problems, isEmpty);
    });

    test('실패해도 예외를 삼킨다 (백그라운드 폴링이라 화면을 막지 않음)', () async {
      when(() => problemService.getProblemAnalysis(7))
          .thenThrow(Exception('boom'));

      await provider.fetchProblemAnalysis(7); // 던지지 않아야 통과

      expect(provider.problems, isEmpty);
    });
  });

  group('registerProblem', () {
    test('등록 후 갱신 단계가 실패해도 등록 자체는 성공으로 간주하고 notifyListeners 를 부른다', () async {
      // registerProblem 은 등록 성공 후의 fetchProblem/count 갱신을
      // _runPostMutationRefresh 로 감싸 예외를 삼킨다. 즉 등록은 됐는데
      // 새 문제가 캐시에 없는 상태로 "성공"처럼 보일 수 있다.
      when(() => problemService.registerProblem(any()))
          .thenAnswer((_) async => 42);
      when(() => problemService.getProblem(42, showErrorSnackBar: false))
          .thenThrow(Exception('refresh failed'));
      when(() => problemService.getProblemCount(showErrorSnackBar: false))
          .thenThrow(Exception('count refresh failed'));

      final buildContext = _MockBuildContext();

      await provider.registerProblem(ProblemRegisterModel(), buildContext);

      // 새로 등록된 42번 문제는 refresh 가 실패했으니 캐시에 없다.
      expect(provider.problems, isEmpty);
      expect(notified.count, greaterThan(0));
    });

    test('등록과 갱신이 모두 성공하면 새 문제가 캐시에 들어간다', () async {
      when(() => problemService.registerProblem(any()))
          .thenAnswer((_) async => 42);
      when(() => problemService.getProblem(42, showErrorSnackBar: false))
          .thenAnswer((_) async => _problem(42));
      when(() => problemService.getProblemCount(showErrorSnackBar: false))
          .thenAnswer((_) async => 1);

      final buildContext = _MockBuildContext();

      await provider.registerProblem(ProblemRegisterModel(), buildContext);

      expect(provider.problems.map((p) => p.problemId), [42]);
      expect(provider.problemCount, 1);
    });
  });

  group('deleteProblems', () {
    test('삭제 후 캐시에서 실제로 빠진다', () async {
      when(() => problemService.getProblem(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _problem(1));
      when(() => problemService.getProblem(2, showErrorSnackBar: true))
          .thenAnswer((_) async => _problem(2));
      await provider.fetchProblem(1);
      await provider.fetchProblem(2);

      when(() => problemService.deleteProblems([1])).thenAnswer((_) async {});
      when(() => problemService.getProblemCount(showErrorSnackBar: false))
          .thenAnswer((_) async => 1);

      await provider.deleteProblems([1]);

      expect(provider.problems.map((p) => p.problemId), [2]);
      expect(provider.problemCount, 1);
    });
  });

  group('clear', () {
    test('캐시를 비우고 notifyListeners 를 부른다', () async {
      when(() => problemService.getProblem(1, showErrorSnackBar: true))
          .thenAnswer((_) async => _problem(1));
      await provider.fetchProblem(1);
      notified.reset();

      provider.clear();

      expect(provider.problems, isEmpty);
      expect(notified.count, greaterThan(0));
    });
  });

  group('무한 스크롤 (loadMoreFolderProblemsV2)', () {
    test('첫 페이지를 캐시에 담고 nextCursor·hasNext 를 그대로 돌려준다', () async {
      when(() => problemService.getFolderProblemsV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_problem(1), _problem(2)],
            nextCursor: 2,
            hasNext: true,
            size: 20,
          ));

      final response = await provider.loadMoreFolderProblemsV2(folderId: 1);

      expect(response.hasNext, isTrue);
      expect(response.nextCursor, 2);
      expect(provider.problems.map((p) => p.problemId), [1, 2]);
    });

    test('다음 페이지를 이어 받아도 같은 문제가 두 번 들어가지 않는다', () async {
      when(() => problemService.getFolderProblemsV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_problem(1), _problem(2)],
            nextCursor: 2,
            hasNext: true,
            size: 20,
          ));
      await provider.loadMoreFolderProblemsV2(folderId: 1);

      // 두 번째 페이지가 첫 페이지와 겹치는 problemId(2)를 다시 내려줘도
      // SplayTreeMap 키가 problemId 이므로 upsert 되어 중복되지 않는다.
      when(() => problemService.getFolderProblemsV2(
            folderId: 1,
            cursor: 2,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_problem(2), _problem(3)],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));

      final response = await provider.loadMoreFolderProblemsV2(
        folderId: 1,
        cursor: 2,
      );

      expect(response.hasNext, isFalse);
      expect(provider.problems.map((p) => p.problemId), [1, 2, 3]);
    });

    test('실패하면 예외를 던지고 캐시는 그대로 유지된다', () async {
      when(() => problemService.getFolderProblemsV2(
            folderId: 1,
            cursor: null,
            size: 20,
          )).thenThrow(Exception('network error'));

      await expectLater(
        provider.loadMoreFolderProblemsV2(folderId: 1),
        throwsA(isA<Exception>()),
      );
      expect(provider.problems, isEmpty);
    });
  });
}
