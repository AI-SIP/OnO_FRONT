// ReviewDueProvider 상태 전이 테스트.
//
// 로딩 가드(`if (_isLoading) return;`)와, 실패 시 예외를 삼키고
// isLoading 만 되돌리는지가 관찰 대상이다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Problem/ReviewDueProblemModel.dart';
import 'package:ono/Provider/ReviewDueProvider.dart';

import '../helpers/helpers.dart';
import 'support/provider_test_env.dart';

void main() {
  setUpOnoTest();

  setUpAll(setUpProviderTestEnv);

  late MockProblemService problemService;
  late ReviewDueProvider provider;
  late NotifyRecorder notified;

  setUp(() {
    problemService = MockProblemService();
    provider = ReviewDueProvider(problemService: problemService);
    notified = NotifyRecorder();
    provider.addListener(notified.call);
  });

  group('초기 상태', () {
    test('아무 것도 안 했을 때 dueCount 는 0, data 는 null', () {
      expect(provider.data, isNull);
      expect(provider.dueCount, 0);
      expect(provider.isLoading, isFalse);
    });
  });

  group('fetchReviewDue', () {
    test('성공하면 data 가 채워지고 isLoading 이 false 로 돌아온다', () async {
      when(() => problemService.getReviewDueProblems()).thenAnswer(
        (_) async => ReviewDueResponse(
          dueCount: 3,
          overdueCount: 1,
          problems: const [],
        ),
      );

      await provider.fetchReviewDue();

      expect(provider.dueCount, 3);
      expect(provider.isLoading, isFalse);
      expect(notified.count, greaterThan(0));
    });

    test('실패해도 예외를 삼키고 isLoading 은 false 로 돌아온다 (화면이 스피너에 갇히지 않는다)', () async {
      when(() => problemService.getReviewDueProblems())
          .thenThrow(Exception('network error'));

      await provider.fetchReviewDue(); // 던지지 않아야 한다

      expect(provider.isLoading, isFalse);
      expect(provider.data, isNull);
    });

    test('이미 로딩 중이면 재진입하지 않는다 (동시 호출 가드)', () async {
      var callCount = 0;
      when(() => problemService.getReviewDueProblems()).thenAnswer((_) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return ReviewDueResponse(
            dueCount: 1, overdueCount: 0, problems: const []);
      });

      final first = provider.fetchReviewDue();
      final second = provider.fetchReviewDue();
      await Future.wait([first, second]);

      expect(callCount, 1);
    });
  });

  group('clear', () {
    test('data 를 비우고 notifyListeners 를 부른다', () async {
      when(() => problemService.getReviewDueProblems()).thenAnswer(
        (_) async =>
            ReviewDueResponse(dueCount: 2, overdueCount: 0, problems: const []),
      );
      await provider.fetchReviewDue();
      notified.reset();

      provider.clear();

      expect(provider.data, isNull);
      expect(provider.dueCount, 0);
      expect(notified.count, greaterThan(0));
    });
  });
}
