// PracticeThumbnailScreen(복습 세트 목록) 위젯 테스트.
//
// 이 화면은 initState 에서 스스로 데이터를 fetch 하지 않는다 — 목록은 진입 전에
// 이미 로드돼 있다고 가정하는 구조라, 상태별 그림은 진짜 ProblemPracticeProvider 에
// mock 서비스를 물려 `loadInitialPracticeThumbnails()` 를 직접 불러서 만든다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteThumbnailModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeProblemSelectionScreen.dart';
import 'package:ono/Screen/PracticeNote/PracticeThumbnailScreen.dart';

import '../../helpers/helpers.dart';

PracticeNoteThumbnails _thumb(
  int id, {
  String? title,
  int practiceCount = 0,
  DateTime? lastSolvedAt,
  String? lastSessionMoodEmojiKey,
}) {
  return PracticeNoteThumbnails(
    practiceId: id,
    practiceTitle: title ?? 'practice-$id',
    practiceCount: practiceCount,
    lastSolvedAt: lastSolvedAt,
    lastSessionMoodEmojiKey: lastSessionMoodEmojiKey,
  );
}

PaginatedResponse<PracticeNoteThumbnails> _page(
  List<PracticeNoteThumbnails> content, {
  bool hasNext = false,
  int? nextCursor,
}) {
  return PaginatedResponse(
    content: content,
    nextCursor: nextCursor,
    hasNext: hasNext,
    size: 20,
  );
}

void main() {
  setUpOnoWidgetTest();

  late MockPracticeNoteService practiceNoteService;
  late ProblemPracticeProvider practiceProvider;

  setUp(() {
    practiceNoteService = MockPracticeNoteService();
    practiceProvider = ProblemPracticeProvider(
      problemsProvider: MockProblemsProvider(),
      practiceNoteService: practiceNoteService,
    );
  });

  testWidgets('아직 아무 것도 로드하지 않았으면 빈 상태 그림과 추가 버튼이 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );

    expect(find.textContaining('복습 세트에 오답노트를 담아'), findsOneWidget);
    expect(find.text('복습 세트 추가하기'), findsOneWidget);
  });

  testWidgets('첫 로드가 진행 중이면(썸네일 없음+isLoading) 로딩 인디케이터가 보인다', (tester) async {
    final completer = Completer<PaginatedResponse<PracticeNoteThumbnails>>();
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) => completer.future);

    // await 하지 않고 로딩 상태(isLoading=true)만 만든 채 화면을 띄운다.
    // ignore: unawaited_futures
    practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
      settle: false,
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('복습 세트 추가하기'), findsNothing);

    completer.complete(_page([_thumb(1)]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('썸네일이 있으면 제목과 마지막 복습 날짜, 복습 횟수 태그가 보인다', (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) async => _page([
          _thumb(1, title: '수학 오답노트', practiceCount: 1),
        ]));
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );

    expect(find.text('수학 오답노트'), findsOneWidget);
    expect(find.textContaining('복습 기록 없음'), findsOneWidget);
    expect(find.text('1회 복습'), findsOneWidget);
  });

  testWidgets('복습 3회 이상이면 "복습 완료" 태그로 바뀐다', (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) async => _page([_thumb(1, practiceCount: 3)]));
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );

    expect(find.text('복습 완료'), findsOneWidget);
    expect(find.text('3회 복습'), findsNothing);
  });

  testWidgets('제목이 빈 문자열이면 "제목 없음" 으로 보인다', (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) async => _page([_thumb(1, title: '')]));
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );

    expect(find.text('제목 없음'), findsOneWidget);
  });

  testWidgets('추가하기 FAB 을 탭하면 문제 선택 화면으로 전환된다', (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) async => _page([_thumb(1)]));
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );

    await tester.tap(find.widgetWithText(FloatingActionButton, '복습 세트 추가'));
    await tester.pumpAndSettle();

    expect(find.byType(PracticeProblemSelectionScreen), findsOneWidget);
  });

  testWidgets('더보기(⋮) 를 탭하면 생성하기·삭제하기 메뉴가 뜬다', (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) async => _page([_thumb(1)]));
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('복습 세트 편집하기'), findsOneWidget);
    expect(find.text('복습 세트 생성하기'), findsOneWidget);
    expect(find.text('복습 세트 삭제하기'), findsOneWidget);
  });

  testWidgets('삭제하기를 고르면 선택 모드로 들어가 FAB 대신 취소·삭제 버튼이 보인다', (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) async => _page([_thumb(1), _thumb(2)]));
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('복습 세트 삭제하기'));
    await tester.pumpAndSettle();

    expect(find.text('삭제할 항목 선택'), findsOneWidget); // 앱바 제목도 바뀐다
    expect(find.text('취소하기'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '삭제하기'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('선택 모드에서 항목을 탭하면 선택되고 삭제 버튼에 개수가 표시된다', (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) async => _page([_thumb(1), _thumb(2)]));
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('복습 세트 삭제하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('practice-1'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget); // 삭제 버튼 옆 선택 개수 배지

    // 같은 항목을 다시 탭하면 선택이 풀린다.
    await tester.tap(find.text('practice-1'));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('아무 것도 선택하지 않고 삭제하기를 눌러도 다이얼로그가 뜨지 않는다', (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) async => _page([_thumb(1)]));
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('복습 세트 삭제하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, '삭제하기'));
    await tester.pumpAndSettle();

    expect(find.text('정말로 이 복습 세트를 삭제하시겠습니까?'), findsNothing);
  });

  testWidgets('선택 후 삭제를 확정하면 deletePracticeNotes 가 불리고 목록에서 빠지며 선택 모드가 풀린다',
      (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) async => _page([_thumb(1), _thumb(2)]));
    // 위젯이 삭제 직후 선택 목록(_selectedPracticeIds)을 clear() 하는데, 그 리스트를
    // 그대로 넘겨 받으므로 mock 이 기억하는 인자도 나중엔 비어버린다. 호출 시점에
    // 값을 복사해 둬야 검증할 수 있다.
    List<int>? deletedIds;
    when(() => practiceNoteService.deletePracticeNotes(any())).thenAnswer(
      (invocation) async {
        deletedIds =
            List<int>.from(invocation.positionalArguments.first as List<int>);
      },
    );
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('복습 세트 삭제하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('practice-1'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, '삭제하기'));
    await tester.pumpAndSettle();
    expect(find.text('정말로 이 복습 세트를 삭제하시겠습니까?'), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(deletedIds, [1]);
    expect(find.text('practice-1'), findsNothing);
    expect(find.text('practice-2'), findsOneWidget);
    expect(find.text('삭제할 항목 선택'), findsNothing); // 선택 모드 해제됨
  });

  testWidgets('취소하기를 누르면 선택 모드가 풀리고 FAB 이 다시 보인다', (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
          cursor: null,
          size: 20,
        )).thenAnswer((_) async => _page([_thumb(1)]));
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('복습 세트 삭제하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소하기'));
    await tester.pumpAndSettle();

    expect(find.text('오답 복습'), findsOneWidget); // 앱바 제목이 원래대로
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets(
    'pull-to-refresh 를 두 번 빠르게 하면 늦게 도착한 응답이 최신 응답을 덮어쓴다 (경쟁 조건)',
    (tester) async {
      // TODO(#174): 실제 버그. lib/Provider/PracticeNoteProvider.dart:303-341
      // loadInitialPracticeThumbnails 에는 loadMorePracticeThumbnails 와 달리
      // `if (_isLoading) return;` 가드가 없다. 화면의 RefreshIndicator.onRefresh 는
      // 이 메서드로 바로 이어지는 provider.refreshPracticeThumbnails() 를 부르므로,
      // 사용자가 pull-to-refresh 를 연달아 두 번 하면(두 번째 당김이 첫 번째 응답을
      // 기다리지 않고 시작되면) 두 요청이 동시에 나간다. 이 테스트는 실제
      // RefreshIndicator 위젯에 연결된 onRefresh 콜백을 두 번 직접 호출해
      // "먼저 시작했지만 늦게 도착한 응답"이 "나중에 시작했지만 먼저 도착한 최신
      // 응답"을 덮어쓰는 것을 화면 레벨에서 보여준다.
      var callIndex = 0;
      when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
            cursor: null,
            size: 20,
          )).thenAnswer((_) async {
        callIndex++;
        if (callIndex == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return _page([_thumb(1)]); // A: 먼저 시작했지만 늦게 도착
        }
        return _page([_thumb(2)]); // B: 나중에 시작했지만 먼저 도착 (최신 요청)
      });
      await practiceProvider.loadInitialPracticeThumbnails();

      await pumpOnoWidget(
        tester,
        const PracticeThumbnailScreen(),
        practiceProvider: practiceProvider,
      );
      expect(find.text('practice-1'), findsOneWidget);

      final refreshIndicator =
          tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
      final firstPull = refreshIndicator.onRefresh();
      final secondPull = refreshIndicator.onRefresh();
      await Future.wait([firstPull, secondPull]);
      await tester.pumpAndSettle();

      // 사용자 입장에서는 최신 상태(practice-2)를 기대하지만, 늦게 도착한
      // A 가 덮어써서 오래된 목록(practice-1)이 그대로 남는다.
      expect(find.text('practice-1'), findsOneWidget);
      expect(find.text('practice-2'), findsNothing);
    },
    skip: true, // #174 에서 수정 예정
  );

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    when(() => practiceNoteService.getPracticeNoteThumbnailsV2(
              cursor: null,
              size: 20,
            ))
        .thenAnswer(
            (_) async => _page([_thumb(1), _thumb(2, practiceCount: 3)]));
    await practiceProvider.loadInitialPracticeThumbnails();

    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(PracticeThumbnailScreen), findsOneWidget);
  });

  testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpOnoWidget(
      tester,
      const PracticeThumbnailScreen(),
      practiceProvider: practiceProvider,
      surfaceSize: OnoSurface.smallPhone,
    );

    expect(tester.takeException(), isNull);
  });
}
