// PracticeDetailScreen 위젯 테스트.
//
// ProblemPracticeProvider 는 mock 서비스를 물린 진짜 Provider 를 쓴다. 화면이
// `provider.currentProblems` 를 직접 읽고, moveToPractice 를 거치지 않고도
// 필드에 바로 값을 넣을 수 있는 구조라 (problem_practice_provider_test.dart 참고)
// 상태를 세팅하기 편하다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/Problem/ProblemImageDataModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeDetailScreen.dart';

import '../../helpers/helpers.dart';

/// didPush 호출 여부만 기록하는 관찰자. mock 대신 실제 서브클래스를 쓰는 이유는
/// MaterialPageRoute 의 builder 를 mocktail 로 캡처해도 내부 위젯 타입을 들여다볼
/// 수 없어서다 — README 규약대로 "불렸는지" 만 본다.
class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    pushed.add(route);
  }
}

PracticeNoteDetailModel _practice({
  int practiceId = 1,
  String title = '수학 오답노트',
  int practiceCount = 0,
  DateTime? lastSolvedAt,
  String? lastSessionMoodEmojiKey,
  List<int> problemIdList = const [],
}) {
  return PracticeNoteDetailModel(
    practiceId: practiceId,
    practiceTitle: title,
    practiceCount: practiceCount,
    createdAt: DateTime(2024, 1, 1),
    lastSolvedAt: lastSolvedAt,
    lastSessionMoodEmojiKey: lastSessionMoodEmojiKey,
    problemIdList: problemIdList,
  );
}

ProblemModel _problem(int id, {String? imageUrl, String? reference}) {
  return ProblemModel(
    problemId: id,
    reference: reference,
    problemImageDataList: imageUrl == null
        ? null
        : [
            ProblemImageDataModel(
              imageUrl: imageUrl,
              problemImageType: ProblemImageType.PROBLEM_IMAGE,
              createdAt: DateTime(2024, 1, 1),
            ),
          ],
  );
}

void main() {
  setUpOnoWidgetTest();

  late MockPracticeNoteService practiceNoteService;
  late MockProblemsProvider problemsProvider;
  late ProblemPracticeProvider practiceProvider;

  setUp(() {
    practiceNoteService = MockPracticeNoteService();
    problemsProvider = MockProblemsProvider();
    practiceProvider = ProblemPracticeProvider(
      problemsProvider: problemsProvider,
      practiceNoteService: practiceNoteService,
    );
    when(() => practiceNoteService.deletePracticeNotes(any()))
        .thenAnswer((_) async {});
  });

  testWidgets('문제가 있으면 문제 수·복습 횟수 정보가 보인다', (tester) async {
    practiceProvider.currentProblems = [_problem(10), _problem(20)];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(
        practice: _practice(practiceCount: 3, problemIdList: [10, 20]),
      ),
      practiceProvider: practiceProvider,
    );

    expect(find.text('2'), findsOneWidget); // practiceSize == problemIdList 길이
    expect(find.text('3회'), findsOneWidget);
    expect(find.text('수학 오답노트'), findsOneWidget);
  });

  testWidgets('마지막 복습 일시가 없으면 "기록 없음" 이 보인다', (tester) async {
    // 문제 목록(ProblemThumbnailCard)도 개별 lastSolvedAt 이 없으면 같은 문구를
    // 써서 겹치므로, 여기서는 정보 영역만 보려고 문제 목록을 비워 둔다.
    practiceProvider.currentProblems = [];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(
        practice: _practice(problemIdList: [10], lastSolvedAt: null),
      ),
      practiceProvider: practiceProvider,
    );

    expect(find.text('기록 없음'), findsOneWidget);
  });

  testWidgets('마지막 복습 일시가 있으면 yyyy/MM/dd 형식으로 보인다', (tester) async {
    practiceProvider.currentProblems = [];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(
        practice: _practice(
          problemIdList: [10],
          lastSolvedAt: DateTime(2024, 3, 5),
        ),
      ),
      practiceProvider: practiceProvider,
    );

    expect(find.text('2024/03/05'), findsOneWidget);
    expect(find.text('기록 없음'), findsNothing);
  });

  testWidgets('지난 복습 소감 이모지 키가 없으면 그 행이 안 보인다', (tester) async {
    practiceProvider.currentProblems = [_problem(10)];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(
        practice: _practice(problemIdList: [10]),
      ),
      practiceProvider: practiceProvider,
    );

    expect(find.text('지난 복습 소감'), findsNothing);
  });

  testWidgets('지난 복습 소감 이모지 키가 있으면 그 행이 보인다', (tester) async {
    practiceProvider.currentProblems = [_problem(10)];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(
        practice: _practice(
          problemIdList: [10],
          lastSessionMoodEmojiKey: 'birthday_cake',
        ),
      ),
      practiceProvider: practiceProvider,
    );

    expect(find.text('지난 복습 소감'), findsOneWidget);
  });

  testWidgets('문제가 없으면 빈 상태 그림(안내 문구·프로그·추가 버튼)이 보이고 복습하기 버튼은 없다',
      (tester) async {
    practiceProvider.currentProblems = [];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(practice: _practice(problemIdList: [])),
      practiceProvider: practiceProvider,
    );

    expect(find.textContaining('복습 세트가 비어있습니다'), findsOneWidget);
    expect(find.text('오답노트 추가하기'), findsOneWidget);
    expect(find.text('복습하기'), findsNothing);
  });

  testWidgets('문제가 있으면 복습하기 버튼이 보인다', (tester) async {
    practiceProvider.currentProblems = [_problem(10)];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(practice: _practice(problemIdList: [10])),
      practiceProvider: practiceProvider,
    );

    expect(find.text('복습하기'), findsOneWidget);
    expect(find.textContaining('복습 세트가 비어있습니다'), findsNothing);
  });

  testWidgets('빈 상태에서 오답노트 추가하기를 탭하면 문제 선택 화면으로 전환된다', (tester) async {
    practiceProvider.currentProblems = [];
    final observer = _RecordingNavigatorObserver();

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(practice: _practice(problemIdList: [])),
      practiceProvider: practiceProvider,
      navigatorObservers: [observer],
    );
    final pushedBefore = observer.pushed.length;

    await tester.tap(find.text('오답노트 추가하기'));

    expect(observer.pushed.length, pushedBefore + 1);
  });

  testWidgets('복습하기를 탭하면 복습 방식 선택 바텀시트가 뜬다', (tester) async {
    practiceProvider.currentProblems = [_problem(10)];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(practice: _practice(problemIdList: [10])),
      practiceProvider: practiceProvider,
    );

    await tester.tap(find.text('복습하기'));
    await tester.pumpAndSettle();

    expect(find.text('복습 방식 선택'), findsOneWidget);
    expect(find.text('등록한 순서로 복습하기'), findsOneWidget);
    expect(find.text('셔플 모드로 복습하기'), findsOneWidget);
  });

  testWidgets('등록한 순서로 복습하기를 고르면 currentProblems 가 등록 순서로 재정렬된 뒤 화면이 전환된다',
      (tester) async {
    // problemIdList 등록 순서는 [20, 10] 인데 currentProblems 는 뒤섞인 상태로 시작한다.
    final practice = _practice(problemIdList: [20, 10]);
    practiceProvider.currentProblems = [_problem(10), _problem(20)];
    // useRegisteredProblemOrder() 는 화면에 넘긴 practice 가 아니라 provider 의
    // currentPracticeNote 를 기준으로 재정렬하므로 같이 맞춰 둔다.
    practiceProvider.currentPracticeNote = practice;
    final observer = _RecordingNavigatorObserver();

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(practice: practice),
      practiceProvider: practiceProvider,
      navigatorObservers: [observer],
    );
    await tester.tap(find.text('복습하기'));
    await tester.pumpAndSettle();
    final pushedBefore = observer.pushed.length;

    // 다음 프레임을 그리면 ProblemDetailScreen 이 실제로 빌드되며 네트워크를
    // 태우므로, 탭 콜백이 동기로 반영하는 상태만 확인하고 pump 는 하지 않는다.
    await tester.tap(find.text('등록한 순서로 복습하기'));

    expect(
      practiceProvider.currentProblems.map((p) => p.problemId),
      [20, 10],
    );
    expect(observer.pushed.length, pushedBefore + 1);
  });

  testWidgets('더보기 버튼을 탭하면 편집·삭제 메뉴가 뜬다', (tester) async {
    practiceProvider.currentProblems = [_problem(10)];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(practice: _practice(problemIdList: [10])),
      practiceProvider: practiceProvider,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // 시트 제목도 같은 문구('복습 세트 편집하기')를 쓰기 때문에 메뉴 항목과 합쳐 2개다.
    expect(find.text('복습 세트 편집하기'), findsNWidgets(2));
    expect(find.text('복습 세트 삭제하기'), findsOneWidget);
  });

  testWidgets('삭제하기를 고르면 확인 다이얼로그가 뜨고, 삭제를 누르면 서비스가 호출된다', (tester) async {
    practiceProvider.currentProblems = [_problem(10)];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(
          practice: _practice(practiceId: 42, problemIdList: [10])),
      practiceProvider: practiceProvider,
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('복습 세트 삭제하기'));
    await tester.pumpAndSettle();

    expect(find.text('정말로 이 복습 세트를 삭제하시겠습니까?'), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    verify(() => practiceNoteService.deletePracticeNotes([42])).called(1);
  });

  testWidgets('삭제 다이얼로그에서 취소를 누르면 서비스가 호출되지 않는다', (tester) async {
    practiceProvider.currentProblems = [_problem(10)];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(practice: _practice(problemIdList: [10])),
      practiceProvider: practiceProvider,
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('복습 세트 삭제하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    verifyNever(() => practiceNoteService.deletePracticeNotes(any()));
    expect(find.text('정말로 이 복습 세트를 삭제하시겠습니까?'), findsNothing);
  });

  testWidgets('네트워크 이미지가 있는 문제 카드도 예외 없이 그려진다', (tester) async {
    practiceProvider.currentProblems = [
      _problem(10, imageUrl: 'https://example.com/a.png', reference: '3번 문제'),
    ];

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        PracticeDetailScreen(practice: _practice(problemIdList: [10])),
        practiceProvider: practiceProvider,
      );
    });

    expect(find.text('3번 문제'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    practiceProvider.currentProblems = [_problem(10), _problem(20)];

    await pumpOnoWidget(
      tester,
      PracticeDetailScreen(practice: _practice(problemIdList: [10, 20])),
      practiceProvider: practiceProvider,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(PracticeDetailScreen), findsOneWidget);
  });
}
