// ProblemPracticeProvider(PracticeNoteProvider.dart 안의 클래스) 상태 전이 테스트.
//
// problemsProvider 를 통해 문제를 지연 로딩하는 구조라 MockProblemsProvider 로
// 위임 여부를 확인하고, V2 무한 스크롤 썸네일 캐시(_practiceThumbnails)의
// 동시 호출·경쟁 조건을 집중적으로 본다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/AnswerStatus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteThumbnailModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNotificationModel.dart';
import 'package:ono/Model/PracticeNote/RepeatType.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';

import '../helpers/helpers.dart';
import 'support/provider_test_env.dart';

PracticeNoteDetailModel _practice(
  int id, {
  String? title,
  List<int>? problemIds,
  int practiceCount = 0,
}) {
  return PracticeNoteDetailModel(
    practiceId: id,
    practiceTitle: title ?? 'practice-$id',
    practiceCount: practiceCount,
    createdAt: DateTime(2024, 1, 1),
    lastSolvedAt: null,
    problemIdList: problemIds ?? [],
  );
}

PracticeNoteThumbnails _thumb(int id, {int practiceCount = 0}) {
  return PracticeNoteThumbnails(
    practiceId: id,
    practiceTitle: 'practice-$id',
    practiceCount: practiceCount,
    lastSolvedAt: null,
  );
}

ProblemModel _problem(int id) => ProblemModel(problemId: id);

void main() {
  setUpOnoTest();

  setUpAll(() {
    setUpProviderTestEnv();
    registerFallbackValue(
      PracticeNoteRegisterModel(
          practiceTitle: 'fallback', registerProblemIdList: const []),
    );
    registerFallbackValue(
      PracticeNoteUpdateModel(
        practiceNoteId: 0,
        addProblemIdList: const [],
        removeProblemIdList: const [],
      ),
    );
  });

  late MockPracticeNoteService practiceNoteService;
  late MockProblemsProvider problemsProvider;
  late ProblemPracticeProvider provider;
  late NotifyRecorder notified;

  setUp(() {
    practiceNoteService = MockPracticeNoteService();
    problemsProvider = MockProblemsProvider();
    provider = ProblemPracticeProvider(
      problemsProvider: problemsProvider,
      practiceNoteService: practiceNoteService,
    );
    notified = NotifyRecorder();
    provider.addListener(notified.call);
  });

  group('초기 상태', () {
    test('아무 것도 하지 않았을 때 모두 비어 있다', () {
      expect(provider.practices, isEmpty);
      expect(provider.practiceThumbnails, isEmpty);
      expect(provider.currentProblems, isEmpty);
      expect(provider.currentPracticeNote, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.hasNext, isFalse);
      expect(provider.hasCachedData, isFalse);
    });
  });

  group('fetchPracticeNote / getPracticeNote', () {
    test('성공하면 캐시에 들어가고 notifyListeners 가 불린다', () async {
      when(() => practiceNoteService.getPracticeNoteById(7,
          showErrorSnackBar: true)).thenAnswer((_) async => _practice(7));

      await provider.fetchPracticeNote(7);

      expect(provider.practices, hasLength(1));
      expect(notified.count, greaterThan(0));
    });

    test('캐시에 없으면 fetch 후 반환하고, 있으면 서버를 다시 부르지 않는다', () async {
      when(() => practiceNoteService.getPracticeNoteById(7,
          showErrorSnackBar: true)).thenAnswer((_) async => _practice(7));

      final first = await provider.getPracticeNote(7);
      clearInteractions(practiceNoteService);
      final second = await provider.getPracticeNote(7);

      expect(first.practiceId, 7);
      expect(second.practiceId, 7);
      verifyNever(() => practiceNoteService.getPracticeNoteById(any(),
          showErrorSnackBar: any(named: 'showErrorSnackBar')));
    });

    test('실패하면 예외를 삼키지 않고 던진다', () async {
      when(() => practiceNoteService.getPracticeNoteById(7,
          showErrorSnackBar: true)).thenThrow(Exception('network error'));

      await expectLater(
        provider.fetchPracticeNote(7),
        throwsA(isA<Exception>()),
      );
      expect(provider.practices, isEmpty);
    });
  });

  group('moveToPractice', () {
    test('문제들을 problemsProvider 캐시에서 가져와 currentProblems 를 채운다', () async {
      when(() => practiceNoteService.getPracticeNoteById(1,
              showErrorSnackBar: true))
          .thenAnswer((_) async => _practice(1, problemIds: [10, 20]));
      when(() => problemsProvider.getProblem(10))
          .thenAnswer((_) async => _problem(10));
      when(() => problemsProvider.getProblem(20))
          .thenAnswer((_) async => _problem(20));

      await provider.moveToPractice(1);

      expect(provider.currentProblems.map((p) => p.problemId), [10, 20]);
      expect(provider.currentPracticeNote?.practiceId, 1);
    });

    test('캐시에 없는 문제는 fetchProblem 으로 한 번 더 시도한다', () async {
      when(() => practiceNoteService.getPracticeNoteById(1,
              showErrorSnackBar: true))
          .thenAnswer((_) async => _practice(1, problemIds: [10]));
      var getCallCount = 0;
      when(() => problemsProvider.getProblem(10)).thenAnswer((_) async {
        getCallCount++;
        if (getCallCount == 1) throw Exception('not cached');
        return _problem(10);
      });
      when(() => problemsProvider.fetchProblem(10)).thenAnswer((_) async {});

      await provider.moveToPractice(1);

      verify(() => problemsProvider.fetchProblem(10)).called(1);
      expect(provider.currentProblems.map((p) => p.problemId), [10]);
    });

    test('일부 문제 로딩이 완전히 실패해도 나머지는 채우고 계속 진행한다', () async {
      when(() => practiceNoteService.getPracticeNoteById(1,
              showErrorSnackBar: true))
          .thenAnswer((_) async => _practice(1, problemIds: [10, 20]));
      when(() => problemsProvider.getProblem(10))
          .thenThrow(Exception('cache miss'));
      when(() => problemsProvider.fetchProblem(10))
          .thenThrow(Exception('network error'));
      when(() => problemsProvider.getProblem(20))
          .thenAnswer((_) async => _problem(20));

      await provider.moveToPractice(1); // 던지지 않아야 한다

      expect(provider.currentProblems.map((p) => p.problemId), [20]);
      expect(provider.currentPracticeNote?.practiceId, 1);
    });
  });

  group('getProblemDetails', () {
    test(
      '없는 problemId 를 조회하면 null 이 아니라 StateError 를 던진다',
      () async {
        // TODO(#174): 실제 버그. lib/Provider/PracticeNoteProvider.dart:274-277
        // getProblemDetails 의 시그니처는 `Future<ProblemModel?>` 로 "없으면 null"
        // 을 약속하지만, 구현은 `firstWhere` 를 orElse 없이 써서 못 찾으면
        // StateError 를 던진다. 호출부가 null 체크만 하고 있다면(가장 흔한 사용
        // 패턴) 화면이 예외로 죽거나, try/catch 로 감싸지 않은 경로에서는 크래시로
        // 이어질 수 있다. problemId 가 null 로 들어오는 경우도 항상 이 경로를 탄다.
        when(() => practiceNoteService.getPracticeNoteById(1,
                showErrorSnackBar: true))
            .thenAnswer((_) async => _practice(1, problemIds: [10]));
        when(() => problemsProvider.getProblem(10))
            .thenAnswer((_) async => _problem(10));
        await provider.moveToPractice(1);

        await expectLater(
          provider.getProblemDetails(999),
          throwsA(isA<StateError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );
  });

  group('registerPractice / updatePractice', () {
    test('등록 성공 후 갱신까지 성공하면 캐시에 들어간다', () async {
      when(() => practiceNoteService.registerPracticeNote(any()))
          .thenAnswer((_) async => 5);
      when(() => practiceNoteService.getPracticeNoteById(5,
          showErrorSnackBar: false)).thenAnswer((_) async => _practice(5));

      await provider.registerPractice(
        PracticeNoteRegisterModel(
          practiceTitle: '새 세트',
          registerProblemIdList: const [],
        ),
      );

      expect(provider.practices.map((p) => p.practiceId), [5]);
      expect(provider.practiceRefreshTimestamp, greaterThan(0));
    });

    test('refreshAfterUpdate=false 면 서버를 다시 조회하지 않고 로컬 캐시만 반영한다', () async {
      when(() => practiceNoteService.getPracticeNoteById(1,
              showErrorSnackBar: true))
          .thenAnswer((_) async => _practice(1, problemIds: [10]));
      await provider.fetchPracticeNote(1);
      clearInteractions(practiceNoteService);

      when(() => practiceNoteService.updatePracticeNote(any(),
              showErrorSnackBar: any(named: 'showErrorSnackBar')))
          .thenAnswer((_) async {});

      await provider.updatePractice(
        PracticeNoteUpdateModel(
          practiceNoteId: 1,
          addProblemIdList: const [20],
          removeProblemIdList: const [10],
        ),
        refreshAfterUpdate: false,
      );

      verifyNever(() => practiceNoteService.getPracticeNoteById(1,
          showErrorSnackBar: any(named: 'showErrorSnackBar')));
      expect(provider.practices.first.problemIdList, [20]);
    });
  });

  group('deletePractices', () {
    test('삭제된 항목이 썸네일 캐시에서 실제로 빠진다', () async {
      when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_thumb(1), _thumb(2)],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      await provider.loadInitialPracticeThumbnails();

      when(() => practiceNoteService.deletePracticeNotes([1]))
          .thenAnswer((_) async {});

      await provider.deletePractices([1]);

      expect(
        provider.practiceThumbnails.map((t) => t.practiceId),
        [2],
      );
    });
  });

  group('loadInitialPracticeThumbnails', () {
    test('첫 로드 후 캐시 플래그가 서고, 같은 조건이면 서버를 다시 부르지 않는다', () async {
      when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_thumb(1)],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));

      await provider.loadInitialPracticeThumbnails();
      expect(provider.hasCachedData, isTrue);
      clearInteractions(practiceNoteService);

      await provider.loadInitialPracticeThumbnails();

      verifyNever(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: any(named: 'cursor'), size: any(named: 'size')));
    });

    test('forceRefresh 면 캐시가 있어도 다시 부른다', () async {
      when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_thumb(1)],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      await provider.loadInitialPracticeThumbnails();

      await provider.refreshPracticeThumbnails();

      verify(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null, size: 20)).called(2);
    });

    test('실패하면 예외를 던지고, isLoading 은 반드시 false 로 돌아온다', () async {
      when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
            cursor: null,
            size: 20,
          )).thenThrow(Exception('network error'));

      await expectLater(
        provider.loadInitialPracticeThumbnails(),
        throwsA(isA<Exception>()),
      );
      expect(provider.isLoading, isFalse);
    });

    test(
      '동시에 두 번 부르면 가드가 없어 늦게 도착한 응답이 최신 응답을 덮어쓴다 (경쟁 조건)',
      () async {
        // TODO(#174): 실제 버그. lib/Provider/PracticeNoteProvider.dart:303-341
        // loadInitialPracticeThumbnails 는 loadMorePracticeThumbnails 와 달리
        // `if (_isLoading) return;` 가드가 없다. 그래서 화면에서 새로고침을 빠르게
        // 두 번 트리거하면(예: pull-to-refresh 연타) 두 요청이 동시에 나가고,
        // "나중에 시작한 요청"이 아니라 "나중에 도착한 응답"이 그냥 덮어쓴다.
        // 아래 시나리오는 먼저 시작한 요청이 일부러 늦게 응답하도록 만들어,
        // 최신 요청(B)의 결과가 오래된 요청(A)의 결과로 되돌아가는 것을 보여준다.
        var callIndex = 0;
        when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
              cursor: null,
              size: 20,
            )).thenAnswer((_) async {
          callIndex++;
          if (callIndex == 1) {
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return PaginatedResponse(
              content: [_thumb(1)], // A: 먼저 시작했지만 늦게 도착
              nextCursor: null,
              hasNext: false,
              size: 20,
            );
          }
          return PaginatedResponse(
            content: [_thumb(2)], // B: 나중에 시작했지만 먼저 도착 (최신 요청)
            nextCursor: null,
            hasNext: false,
            size: 20,
          );
        });

        final first = provider.loadInitialPracticeThumbnails();
        final second = provider.loadInitialPracticeThumbnails();
        await Future.wait([first, second]);

        // 사용자 입장에서는 "화면이 최신 상태(B)로 갱신되길" 기대하지만,
        // 실제로는 늦게 도착한 A 가 덮어써서 오래된 목록이 남는다.
        expect(
          provider.practiceThumbnails.map((t) => t.practiceId),
          [1],
        );
      },
      skip: '#174 에서 수정 예정',
    );
  });

  group('회차 순서 (startSession)', () {
    Future<void> openPractice() async {
      when(() => practiceNoteService.getPracticeNoteById(1,
              showErrorSnackBar: true))
          .thenAnswer((_) async => _practice(1, problemIds: [30, 10, 20]));
      for (final id in [10, 20, 30]) {
        when(() => problemsProvider.getProblem(id))
            .thenAnswer((_) async => _problem(id));
      }
      await provider.moveToPractice(1);
    }

    test('시작하기 전에는 세트 전체를 등록한 순서로 푼다', () async {
      await openPractice();

      expect(provider.isPracticing, isFalse);
      expect(provider.sessionProblems.map((p) => p.problemId), [30, 10, 20]);
    });

    test('틀린 문제만 고르면 그 문제들만 등록한 순서로 푼다', () async {
      await openPractice();

      provider.startSession(onlyProblemIds: {20, 30});

      expect(provider.isPracticing, isTrue);
      expect(provider.sessionProblems.map((p) => p.problemId), [30, 20]);
      // 세트 상세에 보이는 목록은 그대로다.
      expect(provider.currentProblems.map((p) => p.problemId), [30, 10, 20]);
    });

    test('셔플은 고른 문제들끼리만 섞는다', () async {
      await openPractice();

      provider.startSession(shuffle: true, onlyProblemIds: {10, 20});

      expect(
          provider.sessionProblems.map((p) => p.problemId).toSet(), {10, 20});
    });

    test('복습을 저장하고 세트를 다시 받아도 회차 순서가 풀리지 않는다', () async {
      await openPractice();
      provider.startSession(onlyProblemIds: {20, 10});

      await provider.moveToPractice(1);

      expect(provider.sessionProblems.map((p) => p.problemId), [10, 20]);
    });

    test('회차 안에서 저장한 결과만 남기고 다시 시작하면 비운다', () async {
      await openPractice();

      provider.recordSessionResult(10, AnswerStatus.CORRECT);
      expect(provider.sessionResults, isEmpty, reason: '회차를 시작하기 전이다');

      provider.startSession(onlyProblemIds: {10, 20});
      provider.recordSessionResult(10, AnswerStatus.WRONG);
      provider.recordSessionResult(10, AnswerStatus.CORRECT);
      provider.recordSessionResult(30, AnswerStatus.CORRECT);
      expect(provider.sessionResults, {10: AnswerStatus.CORRECT},
          reason: '같은 문제는 마지막 결과로 바뀌고 회차에 없는 문제는 남기지 않는다');

      // 복습을 저장할 때마다 세트를 다시 받아도 그대로다.
      await provider.moveToPractice(1);
      expect(provider.sessionResults, hasLength(1));

      provider.startSession();
      expect(provider.sessionResults, isEmpty);
    });

    test('다른 세트를 열면 앞 세트의 회차 순서는 버린다', () async {
      await openPractice();
      provider.startSession(onlyProblemIds: {20});
      when(() => practiceNoteService.getPracticeNoteById(2,
              showErrorSnackBar: true))
          .thenAnswer((_) async => _practice(2, problemIds: [10]));

      await provider.moveToPractice(2);

      expect(provider.isPracticing, isFalse);
      expect(provider.sessionProblems.map((p) => p.problemId), [10]);
    });

    test('endSession 뒤에는 다시 세트 전체를 푼다', () async {
      await openPractice();
      provider.startSession(onlyProblemIds: {20});

      provider.endSession();

      expect(provider.isPracticing, isFalse);
      expect(provider.sessionProblems, hasLength(3));
    });
  });

  group('leavePractice', () {
    test('세트 화면을 닫으면 currentPracticeNote 와 회차를 비운다', () async {
      when(() => practiceNoteService.getPracticeNoteById(1,
              showErrorSnackBar: true))
          .thenAnswer((_) async => _practice(1, problemIds: [10]));
      when(() => problemsProvider.getProblem(10))
          .thenAnswer((_) async => _problem(10));
      await provider.moveToPractice(1);
      provider.startSession();

      provider.leavePractice(1);

      expect(provider.currentPracticeNote, isNull);
      expect(provider.isPracticing, isFalse);
    });

    test('그사이 다른 세트를 열었으면 그 세트는 건드리지 않는다', () async {
      when(() => practiceNoteService.getPracticeNoteById(2,
              showErrorSnackBar: true))
          .thenAnswer((_) async => _practice(2, problemIds: []));
      await provider.moveToPractice(2);

      provider.leavePractice(1);

      expect(provider.currentPracticeNote?.practiceId, 2);
    });
  });

  group('removeProblems / addProblems', () {
    late List<PracticeNoteUpdateModel> sent;

    setUp(() {
      sent = [];
      when(() => practiceNoteService.updatePracticeNote(any(),
              showErrorSnackBar: any(named: 'showErrorSnackBar')))
          .thenAnswer((invocation) async {
        sent.add(
            invocation.positionalArguments.first as PracticeNoteUpdateModel);
      });
    });

    Future<void> openPractice({PracticeNotificationModel? notification}) async {
      when(() => practiceNoteService.getPracticeNoteById(1,
              showErrorSnackBar: true))
          .thenAnswer((_) async => PracticeNoteDetailModel(
                practiceId: 1,
                practiceTitle: '수학',
                practiceCount: 0,
                createdAt: DateTime(2024, 1, 1),
                lastSolvedAt: null,
                practiceNotificationModel: notification,
                problemIdList: [10, 20, 30],
              ));
      for (final id in [10, 20, 30]) {
        when(() => problemsProvider.getProblem(id))
            .thenAnswer((_) async => _problem(id));
      }
      await provider.fetchPracticeNote(1);
      await provider.moveToPractice(1);
    }

    test('빼기 요청에 세트의 알림을 그대로 다시 싣는다', () async {
      final notification = PracticeNotificationModel(
        intervalDays: 3,
        hour: 21,
        minute: 0,
        repeatType: RepeatType.daily,
      );
      await openPractice(notification: notification);

      await provider.removeProblems(1, [20]);

      expect(sent.single.removeProblemIdList, [20]);
      expect(
          sent.single.toJson()['practiceNotification'], notification.toJson());
    });

    test('빼면 화면 목록과 회차에서도 바로 빠진다', () async {
      await openPractice();
      provider.startSession();

      await provider.removeProblems(1, [20]);

      expect(provider.currentProblems.map((p) => p.problemId), [10, 30]);
      expect(provider.sessionProblems.map((p) => p.problemId), [10, 30]);
      expect(provider.currentPracticeNote?.problemIdList, [10, 30]);
    });

    test('넣기 요청에도 알림을 다시 싣는다', () async {
      final notification = PracticeNotificationModel(
        intervalDays: 7,
        hour: 9,
        minute: 30,
        repeatType: RepeatType.weekly,
        weekDays: [1, 3],
      );
      await openPractice(notification: notification);

      await provider.addProblems(1, [40]);

      expect(sent.single.addProblemIdList, [40]);
      expect(
          sent.single.toJson()['practiceNotification'], notification.toJson());
    });
  });

  group('updateSinglePracticeThumbnail', () {
    test('복습을 마치고 썸네일을 바꿔도 기분 이모지가 남는다', () async {
      when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
            cursor: null,
            size: 20,
          )).thenAnswer((_) async => PaginatedResponse(
            content: [_thumb(1)],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
      await provider.loadInitialPracticeThumbnails();
      when(() => practiceNoteService.getPracticeNoteById(1))
          .thenAnswer((_) async => PracticeNoteDetailModel(
                practiceId: 1,
                practiceTitle: 'practice-1',
                practiceCount: 1,
                createdAt: DateTime(2024, 1, 1),
                lastSolvedAt: DateTime(2024, 2, 1),
                lastSessionMoodEmojiKey: 'excited_happy',
                problemIdList: const [],
              ));

      await provider.updateSinglePracticeThumbnail(1);

      expect(provider.practiceThumbnails.single.lastSessionMoodEmojiKey,
          'excited_happy');
    });
  });

  group('resetProblems / clear', () {
    test('clear 는 캐시 전부와 currentProblems 를 비운다', () async {
      when(() => practiceNoteService.getPracticeNoteById(1,
              showErrorSnackBar: true))
          .thenAnswer((_) async => _practice(1, problemIds: [10]));
      when(() => problemsProvider.getProblem(10))
          .thenAnswer((_) async => _problem(10));
      await provider.moveToPractice(1);

      provider.clear();

      expect(provider.practices, isEmpty);
      expect(provider.currentProblems, isEmpty);
      expect(provider.hasCachedData, isFalse);
    });
  });
}
